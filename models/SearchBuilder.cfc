/**
 *
 * Elasticsearch Search Builder Object
 *
 * @package cbElasticsearch.models
 * @author Jon Clausen <jclausen@ortussolutions.com>
 * @license Apache v2.0 <http: // www.apache.org / licenses/>
 *
 */
component accessors="true" {

	property name="configObject" inject="Config@cbElasticsearch";

	/**
	 * Property containing the index name of the active builder search
	 **/
	property name="index";
	/**
	 * Property containing the object type within the index
	 **/
	property name="type";
	/**
	 * Property containing a document `_id`
	 **/
	property name="id";
	/**
	 * Property containing the struct representation of the query being built
	 **/
	property name="query";
	/**
	 * Property containing the struct representation of any query aggregations
	 **/
	property name="aggregations";
	/**
	 * Property containing collapse directives and modifiers
	 **/
	property name="collapse";
	/**
	 * Property containing the struct representation of any _source properties
	 **/
	property name="source";

	/**
	 * Property containing an array of sort commands
	 **/
	property name="sorting";

	/**
	 * Property containing an elasticsearch scripting dsl string
	 **/
	property name="script";

	/**
	 * Property containing elasticsearch "script_fields" definition for runtime scripted fields
	 * 
	 * https://www.elastic.co/guide/en/elasticsearch/reference/current/search-fields.html#script-fields
	 */
	property name="scriptFields" type="struct";

	/**
	 * Property containing "fields" array of fields to return for each hit
	 * 
	 * https://www.elastic.co/guide/en/elasticsearch/reference/current/search-fields.html
	 */
	property name="fields" type="array";

	/**
	 * When performing matching searches, the type of match to specify
	 **/
	property name="matchType";

	/**
	 * URL parameters which will be passed to transform the execution output
	 */
	property name="params";

	/**
	 * Body parameters which will be passed to transform the execution output
	 */
	property name="body" type="struct";

	/**
	 * Whether to preflight the query prior to execution( recommended ) - ensures consistent formatting to prevent errors
	 **/
	property name="preflight" type="boolean";
	/**
	 * Property containing the struct representation of highlight
	 **/
	property name="highlight";

	/**
	 * Property containing the struct representation of suggest
	 **/
	property name="suggest";

	// Optional search defaults
	property name="size";
	property name="from";


	function onDIComplete(){
		reset();
	}

	function reset(){
		variables.index = variables.configObject.get( "defaultIndex" );

		var nullDefaults = [
			"id",
			"sorting",
			"aggregations",
			"script",
			"sortRows"
		];

		// ensure defaults, in case we are re-using a search builder with new()
		variables.matchType = "any";
		variables.query     = {};
		variables.source    = javacast( "null", 0 );

		variables.highlight = {};
		variables.suggest   = {};
		variables.params    = [];
		variables.body      = {};

		variables.size  = 25;
		variables.from = 0;

		variables.preflight = true;

		for ( var nullable in nullDefaults ) {
			if ( !structKeyExists( variables, nullable ) || !isNull( variables[ nullable ] ) ) {
				variables[ nullable ] = javacast( "null", 0 );
			}
		}
	}

	/**
	 * Client provider
	 **/
	Client function getClient() provider="Client@cbElasticsearch"{
	}

	/**
	 * Persists the document to Elasticsearch
	 **/
	function execute(){
		if ( preflight ) {
			preflightQuery();
		}

		return getClient().executeSearch( this );
	}

	/**
	 * Counts the results of the currently built search
	 **/
	function count(){
		if ( preflight ) {
			preflightQuery();
		}

		return getClient().count( this );
	}

	/**
	 * Deletes all documents matching the currently build search query
	 **/
	function deleteAll(){
		return getClient().deleteByQuery( this );
	}

	/**
	 * Backwards compatible setter for max result size
	 * 
	 * @deprecated
	 * 
	 * @value Max number of records to retrieve.
	 */
	SearchBuilder function setMaxRows( required numeric value ){
		variables.size = arguments.value;
		return this;
	}

        /**
	 * Backwards compatible getter for max result size
	 * 
	 * @deprecated
	 */
	any function getMaxRows(){
	    return getSize();
	}

	/**
	 * Backwards compatible setter for result start offset
	 * 
	 * @deprecated
	 * 
	 * @value Starting document offset.
	 */
	SearchBuilder function setStartRow( required numeric value ){
		variables.from = arguments.value;
		return this;
	}

        /**
	 * Backwards compatible getter for start row
	 * 
	 * @deprecated
	 */
	any function getStartRow(){
	    return getFrom();
	}

	/**
	 * Populates a new SearchBuilder object
	 * @index 		string 		the name of the index to search
	 * @type 		string 		the index type identifier
	 * @properties 	struct		a struct representation of the search
	 **/
	SearchBuilder function new( string index, string type, struct properties ){
		reset();

		if ( !isNull( arguments.index ) ) {
			variables.index = arguments.index;
		}

		if ( !isNull( arguments.type ) ) {
			variables.type = arguments.type;
		}

		if ( !isNull( arguments.properties ) ) {
			for ( var propName in arguments.properties ) {
				switch ( propName ) {
					case "from":
					case "offset":
					case "startRow": {
						variables.from = arguments.properties[ propName ];
						break;
					}
					case "size":
					case "maxRows": {
						variables.size = arguments.properties[ propName ];
						break;
					}
					case "query": {
						variables.query = arguments.properties[ propName ];
						break;
					}
					case "highlight": {
						variables.highlight = arguments.properties[ propName ];
						break;
					}
					case "match": {
						if ( !structKeyExists( variables.query, "match" ) ) {
							variables.query[ "match" ] = {};
						}

						structAppend( variables.query.match, arguments.properties[ propName ] );

						break;
					}
					case "aggregations": {
						if ( !isStruct( arguments.properties[ propName ] ) ) {
							throw(
								type    = "cbElasticsearch.SearchBuilder.AggregationException",
								message = "The value #serializeJSON(
									arguments.properties[ propName ],
									false,
									listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
								)# could not be converted to a valid aggregation"
							);
						}

						for ( var aggregationKey in arguments.properties[ propName ] ) {
							aggregation( aggregationKey, arguments.properties[ propName ][ aggregationKey ] );
						}

						break;
					}
					case "sort": {
						sort( arguments.properties[ propName ] );

						break;
					}
					default: {
						// Assume it's a match value if providing a simple value.  Otherwise, assume it is raw DSL
						if ( isSimpleValue( arguments.properties[ propName ] ) ) {
							match( propName, arguments.properties[ propName ] );
						} else {
							variables.query[ propName ] = arguments.properties[ propName ];
						}
					}
				}
			}
		}

		return this;
	}

	/**
	 * Adds a wildcard search to the query
	 * @name 		string 		the name of the parameter to match
	 * @value 		any 		the value of the parameter to match
	 * @boost 		numeric		A numeric boost option for any exact matches
	 * @caseinsensitive		boolean		Should the search be caseinsensitive ?
	 *
	 **/
	SearchBuilder function wildcard(
		required any name,
		required any value,
		numeric boost,
		string operator         = "must",
		boolean caseInsensitive = false
	){
		param variables.query.bool = {};
		if ( !structKeyExists( variables.query.bool, operator ) ) {
			variables.query.bool[ operator ] = [];
		}

		if ( isArray( arguments.name ) ) {
			var wildcard = {
				"bool" : {
					"should" : arguments.name.map( function( key ){
						return {
							"wildcard" : {
								"#key#" : {
									"value" : reFind( "^(?![a-zA-Z0-9 ,.&$']*[^a-zA-Z0-9 ,.&$']).*$", value )
									 ? "*" & value & "*"
									 : value,
									"case_insensitive" : javacast( "boolean", caseInsensitive )
								}
							}
						};
					} )
				}
			};
		} else {
			var wildcard = {
				"wildcard" : {
					"#name#" : {
						"value" : reFind( "^(?![a-zA-Z0-9 ,.&$']*[^a-zA-Z0-9 ,.&$']).*$", value )
						 ? "*" & value & "*"
						 : value,
						"case_insensitive" : javacast( "boolean", arguments.caseInsensitive )
					}
				}
			};
		}

		variables.query.bool[ operator ].append( wildcard );

		return this;
	}

	/**
	 * Adds an exact value restriction ( elasticsearch: term ) to the query
	 * @name 		string 		the name of the parameter to match
	 * @value 		any 		the value of the parameter to match
	 * @boost 		numeric		A numeric boost option for any exact matches
	 *
	 **/
	SearchBuilder function term(
		required string name,
		required any value,
		numeric boost
	){
		if ( !structKeyExists( variables.query, "term" ) ) {
			variables.query[ "term" ] = {};
		}

		if ( !isNull( arguments.boost ) ) {
			variables.query[ "term" ][ arguments.name ] = {
				"value" : arguments.value,
				"boost" : javacast( "float", arguments.boost )
			};
		} else {
			variables.query[ "term" ][ arguments.name ] = arguments.value;
		}

		return this;
	}

	/**
	 * Adds an exact value restriction ( elasticsearch: term ) to the query
	 * @name 		string 		the name of the parameter to match
	 * @value 		any 		the value of the parameter to match
	 * @boost 		numeric		A numeric boost option for any exact matches
	 *
	 **/
	SearchBuilder function terms(
		required string name,
		required any value,
		numeric boost
	){
		if ( !isArray( arguments.value ) ) {
			arguments.value = listToArray( arguments.value );
		}

		if ( !structKeyExists( variables.query, "terms" ) ) {
			variables.query[ "terms" ] = {};
		}

		if ( !isNull( arguments.boost ) ) {
			variables.query[ "terms" ][ arguments.name ] = {
				"value" : arguments.value,
				"boost" : javacast( "float", arguments.boost )
			};
		} else {
			variables.query[ "terms" ][ arguments.name ] = arguments.value;
		}

		return this;
	}

	/**
	 * Adds a fuzzy value restriction ( elasticsearch: match ) and ignore relevance scoring
	 *
	 * @name 		string 		the name of the key to search
	 * @value 		string 		the value of the key
	 **/
	SearchBuilder function filterMatch( required string name, required any value ){
		param variables.query.bool                  = {};
		param variables.query.bool.filter           = {};
		param variables.query.bool.filter.bool      = {};
		param variables.query.bool.filter.bool.must = [];
		variables.query.bool.filter.bool.must.append( { "match" : { "#name#" : value } } );

		return this;
	}

	/**
	 * Adds an exact value restriction ( elasticsearch: term ) and ignore relevance scoring
	 *
	 * @name 		string 		the name of the key to search
	 * @value 		string 		the value of the key
	 **/
	SearchBuilder function filterTerm(
		required string name,
		required any value,
		operator = "must"
	){
		param variables.query.bool             = {};
		param variables.query.bool.filter      = {};
		param variables.query.bool.filter.bool = {};
		if ( !structKeyExists( variables.query.bool.filter.bool, arguments.operator ) ) {
			variables.query.bool.filter.bool[ arguments.operator ] = [];
		}

		variables.query.bool.filter.bool[ arguments.operator ].append( { "term" : { "#name#" : value } } );

		return this;
	}

	/**
	 * `range` filter for date ranges
	 * @name 		string 		the key to match
	 * @start 		string 		the preformatted date string to start the range
	 * @end 		string 		the preformatted date string to end the range
	 * @operator    string      opeartor for the filter operation: `must` or `should`
	 **/
	SearchBuilder function filterRange(
		required string name,
		string start,
		string end,
		operator = "must"
	){
		if ( isNull( arguments.start ) && isNull( arguments.end ) ) {
			throw(
				type    = "cbElasticsearch.SearchBuilder.InvalidParamTypeException",
				message = "A start or end is required to use filterRange"
			);
		}

		if ( arguments.operator != "must" && arguments.operator != "should" ) {
			throw(
				type    = "cbElasticsearch.SearchBuilder.InvalidParamTypeException",
				message = "The operator should be either `must` or `should`."
			);
		}

		var properties = {};
		if ( !isNull( arguments.start ) ) {
			properties[ "gte" ] = arguments.start;
		}
		if ( !isNull( arguments.end ) ) {
			properties[ "lte" ] = arguments.end;
		}

		param variables.query.bool             = {};
		param variables.query.bool.filter      = {};
		param variables.query.bool.filter.bool = {};

		if ( !variables.query.bool.filter.bool.keyExists( arguments.operator ) ) {
			variables.query.bool.filter.bool[ arguments.operator ] = [];
		}

		variables.query.bool.filter.bool[ arguments.operator ].append( { "range" : { "#arguments.name#" : properties } } );

		return this;
	}

	SearchBuilder function filterTerms(
		required string name,
		required any value,
		operator = "must"
	){
		if ( isSimpleValue( value ) ) arguments.value = listToArray( value );

		if ( arrayLen( value ) == 1 ) {
			return filterTerm(
				name     = arguments.name,
				value    = value[ 1 ],
				operator = arguments.operator
			);
		}

		param variables.query.bool             = {};
		param variables.query.bool.filter      = {};
		param variables.query.bool.filter.bool = {};

		if ( !variables.query.bool.filter.bool.keyExists( arguments.operator ) ) {
			variables.query.bool.filter.bool[ arguments.operator ] = [];
		}

		variables.query.bool.filter.bool[ operator ].append( { "terms" : { "#name#" : arguments.value } } );

		return this;
	}

	/**
	 * `must` query alias for match()
	 *
	 * @name 		string 		the name of the key to search
	 * @value 		string 		the value of the key
	 **/
	SearchBuilder function shouldMatch(
		required string name,
		required any value,
		numeric boost
	){
		arguments[ "matchType" ] = "should";
		return match( argumentCollection = arguments );
	}

	/**
	 * `must` query alias for match()
	 *
	 * @name 		string 		the name of the key to search
	 * @value 		string 		the value of the key
	 **/
	SearchBuilder function mustMatch(
		required string name,
		required any value,
		numeric boost
	){
		arguments[ "matchType" ] = "must";
		return match( argumentCollection = arguments );
	}

	/**
	 * `must_not` query alias for match()
	 *
	 * @name 		string 		the name of the key to search
	 * @value 		string 		the value of the key
	 **/
	SearchBuilder function mustNotMatch(
		required string name,
		required any value,
		numeric boost
	){
		arguments[ "matchType" ] = "must_not";
		return match( argumentCollection = arguments );
	}

	/**
	 * Assigns a key which must exists to the query
	 *
	 * @name 		string 		the name of the key to search
	 **/
	SearchBuilder function mustExist( required string name ){
		if ( !structKeyExists( variables.query, "bool" ) ) {
			variables.query[ "bool" ] = {};
		}

		if ( !structKeyExists( variables.query.bool, "must" ) ) {
			variables.query.bool[ "must" ] = [];
		}

		variables.query.bool.must.append( { "exists" : { "field" : arguments.name } } );

		return this;
	}

	/**
	 * Assigns a key which must not exist to the query
	 *
	 * @name 		string 		the name of the key to search
	 **/
	SearchBuilder function mustNotExist( required string name ){
		if ( !structKeyExists( variables.query, "bool" ) ) {
			variables.query[ "bool" ] = {};
		}

		if ( !structKeyExists( variables.query.bool, "must_not" ) ) {
			variables.query.bool[ "must_not" ] = [];
		}

		variables.query.bool.must_not.append( { "exists" : { "field" : arguments.name } } );

		return this;
	}

	/**
	 * 'multi_match' query alias for match()
	 *
	 * @names 		array 		an array of keys to search
	 * @value 		string 		the value of the key
	 * @options 		struct 		An additional struct map of Elasticsearch query options to
	 *					pass in to the match parameters ( e.g. - operator, minimum_should_match, etc )
	 * @boost 		numeric	  	an optional boost value
	 **/
	SearchBuilder function multiMatch(
		required array names,
		required any value,
		numeric boost,
		string type = "best_fields",
		struct options
	){
		arguments.name      = arguments.names;
		arguments.matchType = "multi_match";
		return match( argumentCollection = arguments );
	}

	/**
	 * `range` match for dates
	 * @name 		string 		the key to match
	 * @start 		string 		the preformatted date string to start the range
	 * @end 			string 		the preformatted date string to end the range
	 * @boost 		numeric	    the boost value of the match
	 **/
	SearchBuilder function dateMatch(
		required string name,
		string start,
		string end,
		numeric boost
	){
		if ( isNull( arguments.start ) && isNull( arguments.end ) ) {
			throw(
				type    = "cbElasticsearch.SearchBuilder.InvalidParamTypeException",
				message = "A start or end is required to use dateMatch"
			);
		}

		var properties = {};
		if ( !isNull( arguments.start ) ) {
			properties[ "gte" ] = arguments.start;
		}
		if ( !isNull( arguments.end ) ) {
			properties[ "lte" ] = arguments.end;
		}
		if ( !isNull( arguments.boost ) ) {
			properties[ "boost" ] = arguments.boost;
		}

		return match(
			name      = arguments.name,
			value     = properties,
			matchType = "range"
		);
	}


	/**
	 * Applies a match requirement to the search builder query
	 * https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html
	 *
	 * @name 		string|array 		the name of the key to search
	 * @value 		string 				the value of the key
	 * @boost 		numeric				A numeric boost option for any exact matches
	 * @options 		struct 				An additional struct map of Elasticsearch query options to
	 *									pass in to the match parameters ( e.g. - operator, zero_terms_query, etc )
	 * @matchType 	string 				a match type ( default="any" )
	 * 									Valid options:
	 * 							 		- "any"
	 * 							 		- "all"
	 * 							 		- "phrase" - requires an exact match of a given phrase
	 * 							 		- "must" | "must_not" - specifies that any document returned must or must not match
	 * 							 		- "should" - specifies that any documents returned should match the value(s) provided
	 *
	 **/
	SearchBuilder function match(
		required any name,
		required any value,
		numeric boost,
		struct options,
		string matchType = "any",
		string type      = "best_fields",
		string minimumShouldMatch
	){
		// Auto-magically make a multi-match query if our name argument is an array
		if ( isArray( arguments.name ) ) {
			arguments.matchType = "multi_match";
		}

		switch ( arguments.matchType ) {
			case "phrase": {
				matchKey = "match_phrase";
				break;
			}
			case "all": {
				variables.query[ "match_all" ] = {};
				matchKey                       = "match";
				break;
			}
			default: {
				matchKey = "match";
			}
		}

		var match = {};

		if ( !isNull( arguments.boost ) && isSimpleValue( arguments.name ) ) {
			match[ arguments.name ] = {
				"query" : arguments.value,
				"boost" : javacast( "float", arguments.boost )
			};
		} else if ( isSimpleValue( arguments.name ) ) {
			match[ arguments.name ] = arguments.value;
		}

		if ( !isNull( arguments.options ) && isSimpleValue( arguments.name ) ) {
			// convert our query to the long form DSL so we can append options
			if ( !isStruct( match[ arguments.name ] ) ) {
				match[ arguments.name ] = { "query" : arguments.value };
			}



			for ( var optionKey in arguments.options ) {
				match[ arguments.name ][ optionKey ] = arguments.options[ optionKey ];
			}
		}

		var booleanMatchTypes = [
			"must",
			"must_not",
			"multi_match",
			"should",
			"terms",
			"range"
		];

		if ( arrayFind( booleanMatchTypes, arguments.matchType ) ) {
			if ( !structKeyExists( variables.query, "bool" ) ) {
				variables.query[ "bool" ] = {};
			}

			switch ( arguments.matchType ) {
				case "should": {
					// array-based boolean matches
					if ( !structKeyExists( variables.query.bool, arguments.matchType ) ) {
						variables.query.bool[ arguments.matchType ] = [];
					}
					// we can't use member functions or the ACF2016 compiler blows up
					arrayAppend( variables.query.bool[ arguments.matchType ], { "#matchKey#" : match } );
					break;
				}

				case "multi_match": {
					if ( !structKeyExists( variables.query.bool, "must" ) ) {
						variables.query.bool[ "must" ] = [];
					}

					var matchCriteria = {
						"query"  : arguments.value,
						"fields" : isArray( arguments.name ) ? arguments.name : listToArray( arguments.name ),
						"type"   : arguments.type
					};

					if ( !isNull( arguments.minimumShouldMatch ) ) {
						matchCriteria[ "minimum_should_match" ] = arguments.minimumShouldMatch;
					}

					if ( !isNull( arguments.boost ) ) {
						matchCriteria[ "boost" ] = arguments.boost;
					}

					if ( !isNull( arguments.options ) ) {
						for ( var optionKey in arguments.options ) {
							matchCriteria[ optionKey ] = arguments.options[ optionKey ];
						}
					}

					variables.query.bool.must.append( { "#arguments.matchType#" : matchCriteria } );

					break;
				}

				case "range": {
					if ( !structKeyExists( variables.query.bool, "must" ) ) {
						variables.query.bool[ "must" ] = [];
					}
					variables.query.bool.must.append( { "#arguments.matchType#" : { "#arguments.name#" : arguments.value } } );

					break;
				}

				case "must":
				case "must_not": {
					if ( !structKeyExists( variables.query.bool, arguments.matchType ) ) {
						variables.query.bool[ arguments.matchType ] = [];
					}

					// We can't use member functions here or the ACF 2016 compiler blows up
					arrayAppend(
						variables.query.bool[ arguments.matchType ],
						{ "match" : { "#arguments.name#" : arguments.value } }
					);

					break;
				}

				case "terms": {
					if ( !structKeyExists( variables.query.bool, "must" ) ) {
						variables.query.bool[ "must" ] = [];
					}

					variables.query.bool.must.append( { "terms" : { "#arguments.name#" : arguments.value } } );

					break;
				}

				default: {
					if ( !structKeyExists( variables.query.bool, arguments.matchType ) ) {
						variables.query.bool[ arguments.matchType ] = {};
					}

					structAppend(
						variables.query.bool[ arguments.matchType ],
						match,
						true
					);
				}
			}
		} else {
			if ( !structKeyExists( variables.query, matchKey ) ) {
				variables.query[ matchKey ] = {};
			}

			structAppend( variables.query[ matchKey ], match, true );
		}

		return this;
	}

	/**
	 * Performs a disjunctive search ( https://www.elastic.co/guide/en/elasticsearch/guide/current/_tuning_best_fields_queries.html )
	 *
	 * @matches 		struct 		A struct containing the matches
	 * @tieBreakder 	numeric     A tie breaker value to boost more relevant matches
	 *
	 **/
	SearchBuilder function disjunction( required struct matches, numeric tieBreaker ){
		if ( !structKeyExists( variables.query, "dis_max" ) ) {
			variables.query[ "dis_max" ] = { "queries" : [] };
		}

		for ( var key in matches ) {
			arrayAppend( variables.query[ "dis_max" ].queries, { "match" : { "#key#" : matches[ key ] } } );
		}

		return this;
	}

	/**
	 * Adds a URL parameter to the request ( transformation, throttling, etc. )
	 * Example https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update-by-query.html#_url_parameters
	 *
	 * @name  the name of the URL param
	 * @value  the value of the param
	 */
	SearchBuilder function param( required string name, required any value ){
		if ( !isSimpleValue( arguments.value ) ) {
			throw(
				type    = "cbElasticsearch.SearchBuilder.InvalidParamTypeException",
				message = "The URL parameter of #arguments.name# was not valid.  URL parameters may only be simple values"
			);
		}

		variables.params.append( arguments );

		return this;
	}

	/**
	 * Generic setter for any/all request properties.
	 * 
	 * For example, `set( "size", 100 )` or `set( "min_score" : 1 )`.
	 * 
	 * Example https://www.elastic.co/guide/en/elasticsearch/reference/8.7/search-search.html#search-search-api-request-body
	 *
	 * @name  the name of the parameter to set.
	 * @value  the value of the parameter
	 */
	SearchBuilder function set( required string name, required any value ){
		if( variables.keyExists( arguments.name ) ){ 
			variables[ arguments.name ] = arguments.value;
		} else {
			variables.body[ arguments.name ] = arguments.value;
		}

		return this;
	}

	/**
	 * Adds a body parameter to the request (such as filtering by min_score, forcing a relevance score return, etc.)
	 * 
	 * Example https://www.elastic.co/guide/en/elasticsearch/reference/8.7/search-search.html#search-search-api-request-body
	 *
	 * @name  the name of the body parameter to set
	 * @value  the value of the parameter
	 */
	SearchBuilder function bodyParam( required string name, required any value ){
		set( arguments.name, arguments.value );
		return this;
	}

	/**
	 * Adds highlighting to search
	 *
	 * https://www.elastic.co/guide/en/elasticsearch/reference/6.7/search-request-highlighting.html
	 *
	 * @highlight 	struct      the elasticsearch highlight DSL struct
	 **/
	public SearchBuilder function highlight( required struct highlight ){
		variables.highlight = arguments.highlight;
		return this;
	}

	/**
	 * Adds a term suggestion to a search query.
	 *
	 * https://www.elastic.co/guide/en/elasticsearch/reference/current/search-suggesters.html
	 *
	 * @text     string  The text to match to a term suggestion.
	 * @name     string  The name for the term suggestion parameter.
	 * @field    string  The field name to match against.  Uses the `name` if not provided.
	 * @options  struct  Any additional options to specify for the term suggestion.
	 **/
	public SearchBuilder function suggestTerm(
		required string text,
		required string name,
		string field   = arguments.name,
		struct options = {}
	){
		var suggestion = { "field" : arguments.field };
		structAppend( suggestion, arguments.options, false );
		variables.suggest[ arguments.name ] = { "text" : arguments.text, "term" : suggestion };
		return this;
	}

	/**
	 * Adds a term suggestion to a search query.
	 *
	 * https://www.elastic.co/guide/en/elasticsearch/reference/current/search-suggesters.html
	 *
	 * @text     string  The text to match to a term suggestion.
	 * @name     string  The name for the term suggestion parameter.
	 * @field    string  The field name to match against.  Uses the `name` if not provided.
	 * @options  struct  Any additional options to specify for the term suggestion.
	 **/
	public SearchBuilder function suggestPhrase(
		required string text,
		required string name,
		string field   = arguments.name,
		struct options = {}
	){
		var suggestion = { "field" : arguments.field };
		structAppend( suggestion, arguments.options, false );
		variables.suggest[ arguments.name ] = { "text" : arguments.text, "phrase" : suggestion };
		return this;
	}

	/**
	 * Adds a completion to a search query.
	 *
	 * https://www.elastic.co/guide/en/elasticsearch/reference/current/search-suggesters.html
	 *
	 * @text     string  The prefix text to match to a completion.
	 * @name     string  The name for the completion parameter.
	 * @field    string  The field name to match against.  Uses the `name` if not provided.
	 * @options  struct  Any additional options to specify for the completion.
	 **/
	public SearchBuilder function suggestCompletion(
		required string text,
		required string name,
		string field   = arguments.name,
		struct options = {}
	){
		var completion = { "field" : arguments.field };
		structAppend( completion, arguments.options, false );
		variables.suggest[ arguments.name ] = { "prefix" : arguments.text, "completion" : completion };
		return this;
	}

	/**
	 * Adds an aggregation directive to the search parameters
	 *
	 * https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
	 *
	 * @name 	string 		the key of the aggregation
	 * @options 	struct      the elasticsearch aggregation DSL struct
	 **/
	SearchBuilder function aggregation( required string name, required struct options ){
		if ( isNull( variables.aggregations ) ) {
			variables.aggregations = {};
		}

		variables.aggregations[ name ] = arguments.options;

		return this;
	}

	/**
	 * Applies a custom sort to the search query
	 * @sort 		any 	If passed as a string, the sortConfig argument is required,
	 * 						may also accept a full struct representation, which will be appended to the custom sort
	 * @sortConfig 	string 	A configuration - either a string or a full es-compatible sort configuration struct
	 **/
	SearchBuilder function sort( required any sort, any sortConfig ){
		if ( isNull( variables.sorting ) ) {
			variables.sorting = [];
		}

		// represents the actual sort array passed to the client
		if ( isArray( arguments.sort ) ) {
			variables.sorting.append( arguments.sort, true );
			// a friendly `[fieldName] [ORDER]` like we would use with SQL ( e.g. `name ASC` )
		} else if ( isSimpleValue( arguments.sort ) && isNull( arguments.sortConfig ) ) {
			var sortDirectives = listToArray( arguments.sort, "," );

			for ( var sortDirective in sortDirectives ) {
				var directiveItems = listToArray( sortDirective, " " );
				variables.sorting.append( {
					"#directiveItems[ 1 ]#" : {
						"order" : arrayLen( directiveItems ) > 1 ? lCase( directiveItems[ 2 ] ) : "asc"
					}
				} );
			}

			// name value argument pair
		} else if ( isSimpleValue( arguments.sort ) && !isNull( arguments.sortConfig ) ) {
			// Our sort config argument can be a complex struct or a simple value
			variables.sorting.append( {
				"#arguments.sort#" : isStruct( arguments.sortConfig ) ? arguments.sortConfig : {
					"order" : arguments.sortConfig
				}
			} );

			// Structural representation, which will be treated as individual items in the sort array
		} else if ( isStruct( arguments.sort ) ) {
			for ( var sortKey in arguments.sort ) {
				variables.sorting.append( { "#sortKey#" : { "order" : arguments.sort[ sortKey ] } } );
			}

			// Throw hard if we have no idea how to handle the provided search configuration
		} else {
			throw(
				type    = "cbElasticsearch.SearchBuilder.InvalidSortArgumentException",
				message = "The provided sort argument #serializeJSON(
					arguments.sort,
					false,
					listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
				)# could not be parsed to a valid SearchBuilder sort configuration"
			);
		}


		return this;
	}

	/**
	 * Applies a collapse directive to the search results, which will only return the first matched result of the group
	 * https://www.elastic.co/guide/en/elasticsearch/reference/current/collapse-search-results.html
	 *
	 * @field  string the grouping field
	 * @options a struct of additional options ( e.g. `inner_hits` )
	 * @includeOccurrences whether to automatically aggregate occurrences of each unique value
	 */
	SearchBuilder function collapseToField(
		required string field,
		struct options,
		boolean includeOccurrences = false
	){
		variables.collapse = { "field" : arguments.field };

		if ( !isNull( arguments.options ) ) {
			variables.collapse.append( options );
		}

		// also apply an automatic aggregation to this query so that the collapsed hits can be paginated
		param variables.aggregations = {};

		variables.aggregations[ "collapsed_count" ] = { "cardinality" : { "field" : arguments.field } };

		if ( arguments.includeOccurrences ) {
			var matched                                       = count();
			variables.aggregations[ "collapsed_occurrences" ] = {
				"terms" : {
					"field" : arguments.field,
					"size"  : matched ? matched : 1
				}
			};
		}

		return this;
	}

	/**
	 * Performs a preflight on the search
	 * ensures that a dynamically assembled query is well formatted before being passed on to elasticsearch
	 **/
	void function preflightQuery(){
		var searchQuery = getQuery();

		// move terms in to the boolean node as they won't play well together otherwise
		if (
			structKeyExists( searchQuery, "term" ) && (
				structKeyExists( searchQuery, "bool" ) || arrayLen( structKeyArray( searchQuery.term ) ) > 1
			)
		) {
			if ( !structKeyExists( searchQuery, "bool" ) ) {
				searchQuery[ "bool" ] = {};
			}

			if ( !structKeyExists( searchQuery.bool, "must" ) ) {
				searchQuery.bool[ "must" ] = [];
			}

			for ( var key in searchQuery.term ) {
				searchQuery.bool.must.append( { "term" : { "#key#" : searchQuery.term[ key ] } } );
			}

			structDelete( searchQuery, "term" );
		}

		// move match directives in to boolean node if exists
		if (
			structKeyExists( searchQuery, "match" ) && structKeyExists( searchQuery, "bool" ) && structKeyExists(
				searchQuery.bool,
				"must"
			)
		) {
			if ( !structKeyExists( searchQuery.bool, "should" ) ) {
				searchQuery.bool[ "should" ] = [];
			}

			for ( var key in searchQuery.match ) {
				searchQuery.bool.should.append( { "match" : { "#key#" : searchQuery.match[ key ] } } );
			}

			structDelete( searchQuery, "match" );
		}

		// if we have multiple term filters, move them in to the "must" array
		if (
			structKeyExists( searchQuery, "bool" ) && structKeyExists( searchQuery.bool, "filter" ) && structKeyExists(
				searchQuery.bool.filter,
				"terms"
			)
		) {
			if ( arrayLen( structKeyArray( searchQuery.bool.filter.terms ) ) > 1 ) {
				if ( !structKeyExists( searchQuery, "bool" ) ) {
					searchQuery[ "bool" ] = {};
				}

				if ( !structKeyExists( searchQuery.bool, "must" ) ) {
					searchQuery.bool[ "must" ] = [];
				}

				for ( var termKey in searchQuery.bool.filter.terms ) {
					searchQuery.bool.must.append( { "terms" : { "#termKey#" : searchQuery.bool.filter.terms[ termKey ] } } );
				}

				structDelete( searchQuery.bool.filter, "terms" );
				if ( structIsEmpty( searchQuery.bool.filter ) ) structDelete( searchQuery.bool, "filter" );
				if ( structIsEmpty( searchQuery.bool ) ) structDelete( searchQuery, "bool" );
			}
		}
	}

	any function getDSL(){
		var dsl = {};

		if ( !isNull( variables.query ) && !structIsEmpty( variables.query ) ) {
			dsl[ "query" ] = variables.query;
			dsl[ "from" ]  = variables.from;
			dsl[ "size" ]  = variables.size;
		}

		if ( !isNull( variables.highlight ) && !structIsEmpty( variables.highlight ) ) {
			dsl[ "highlight" ] = variables.highlight;
		}

		if ( !isNull( variables.source ) ) {
			dsl[ "_source" ] = variables.source;
		}

		if ( !isNull( variables.suggest ) && !structIsEmpty( variables.suggest ) ) {
			dsl[ "suggest" ] = variables.suggest;
		}

		if ( !isNull( variables.aggregations ) ) {
			dsl[ "aggs" ] = variables.aggregations;
		}

		if ( !isNull( variables.collapse ) ) {
			dsl[ "collapse" ] = variables.collapse;
		}

		if ( !isNull( variables.script ) ) {
			dsl[ "script" ] = variables.script;
		}

		structAppend( dsl, variables.body, true );

		if ( !isNull( variables.scriptFields ) ) {
			dsl[ "script_fields" ] = variables.scriptFields;
		}

		if ( !isNull( variables.fields ) ) {
			dsl[ "fields" ] = variables.fields;
		}

		if ( !isNull( variables.sorting ) ) {
			// we used a linked hashmap for sorting to maintain order
			dsl[ "sort" ] = createObject( "java", "java.util.LinkedHashMap" ).init();

			for ( var sort in variables.sorting ) {
				dsl.sort.putAll( sort );
			}
		}

		if ( variables.matchType != "any" ) {
			switch ( variables.matchType ) {
				case "all": {
					dsl[ "query" ][ "match_all" ] = {};
					if ( !isNull( variables.matchBoost ) ) {
						dsl[ "query" ][ "match_all" ][ "boost" ] = variables.matchBoost;
					}
					break;
				}
				case "none": {
					dsl[ "query" ][ "match_none" ] = {};
					if ( !isNull( variables.matchBoost ) ) {
						dsl[ "query" ][ "match_none" ][ "boost" ] = variables.matchBoost;
					}
					break;
				}
			}
		}

		return dsl;
	}

	string function getJSON(){
		return serializeJSON(
			getDSL(),
			false,
			listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
		);
	}

	function setSource( any source ){
		if ( isNull( arguments.source ) ) {
			variables.source = javacast( "null", 0 );
		} else {
			if ( isStruct( arguments.source ) ) {
				param arguments.source.includes = [];
				param arguments.source.excludes = [];
			}
			variables.source = arguments.source;
		}
		return this;
	}

	function setSourceIncludes( array includes = [] ){
		param variables.source    = { "includes" : [], "excludes" : [] };
		variables.source.includes = arguments.includes;
		return this;
	}

	function setSourceExcludes( array excludes = [] ){
		param variables.source    = { "includes" : [], "excludes" : [] };
		variables.source.excludes = arguments.excludes;
		return this;
	}

	public SearchBuilder function setFields( array fields = [] ){
		variables.fields = arguments.fields;
		return this;
	}

	/**
	 * Append a dynamic script field to the search.
	 *
	 * @name Name of the script field
	 * @script Script to use. `{ "script" : { "lang": "painless", "source" : } }`
	 * @source Which _source values to include in the response. `true` for all, `false` for none, or a wildcard-capable string: `source = "author.*"`
	 */
	public SearchBuilder function addScriptField( required string name, struct script, any source = true ){
		if ( isNull( variables.scriptFields ) ){
			variables.scriptFields = {};
		}
		variables.scriptFields[ arguments.name ] = arguments.script;
		setSource( arguments.source );
		return this;
	}

	/**
	 * Append a field name or object in the list of fields to return.
	 * 
	 * Especially useful for runtime fields.
	 * 
	 * Example:
	 * ```
	 * addField( { "field": "@timestamp", "format": "epoch_millis"  } )
	 * ```
	 * 
	 * @see https://www.elastic.co/guide/en/elasticsearch/reference/current/runtime-retrieving-fields.html#runtime-search-dayofweek
	 *
	 * @value string|struct Field name to retrieve OR struct config
	 */
	public SearchBuilder function addField( required any value ){
		if ( isNull( variables.fields ) ){
			variables.fields = [];
		}
		variables.fields.append( arguments.value );
		return this;
	}
}
