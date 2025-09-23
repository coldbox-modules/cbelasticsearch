/**
 * Boolean Query Builder for fluent query placement control
 *
 * Allows for precise placement of query operators within boolean query structures
 * like query.bool.must[], query.bool.filter.bool.should[], etc.
 *
 * @package cbElasticsearch.models
 * @author  cbElasticSearch Module
 * @license Apache v2.0 <http: // www.apache.org / licenses/>
 */
component accessors="true" {

	/**
	 * Reference to the parent SearchBuilder instance
	 */
	property name="searchBuilder";

	/**
	 * The current query path being built (e.g., "query.bool.must")
	 */
	property name="queryPath";

	/**
	 * Constructor
	 *
	 * @searchBuilder The parent SearchBuilder instance
	 * @queryPath     The dot-notation path where queries should be placed
	 */
	function init( required any searchBuilder, string queryPath = "query" ){
		variables.searchBuilder = arguments.searchBuilder;
		variables.queryPath     = arguments.queryPath;
		return this;
	}

	/**
	 * Creates a new boolean query context at query.bool
	 *
	 * @return BooleanQueryBuilder A new builder instance for the bool context
	 */
	BooleanQueryBuilder function bool(){
		var newPath = variables.queryPath == "query" ? "query.bool" : variables.queryPath & ".bool";
		return new BooleanQueryBuilder( variables.searchBuilder, newPath );
	}

	/**
	 * Creates a new must query context
	 *
	 * @return BooleanQueryBuilder A new builder instance for the must context
	 */
	BooleanQueryBuilder function must(){
		var newPath = variables.queryPath & ".must";
		return new BooleanQueryBuilder( variables.searchBuilder, newPath );
	}

	/**
	 * Creates a new should query context
	 *
	 * @return BooleanQueryBuilder A new builder instance for the should context
	 */
	BooleanQueryBuilder function should(){
		var newPath = variables.queryPath & ".should";
		return new BooleanQueryBuilder( variables.searchBuilder, newPath );
	}

	/**
	 * Creates a new must_not query context
	 *
	 * @return BooleanQueryBuilder A new builder instance for the must_not context
	 */
	BooleanQueryBuilder function mustNot(){
		var newPath = variables.queryPath & ".must_not";
		return new BooleanQueryBuilder( variables.searchBuilder, newPath );
	}

	/**
	 * Creates a new filter query context
	 *
	 * @return BooleanQueryBuilder A new builder instance for the filter context
	 */
	BooleanQueryBuilder function filter(){
		var newPath = variables.queryPath & ".filter";
		return new BooleanQueryBuilder( variables.searchBuilder, newPath );
	}

	/**
	 * Adds a term query at the current query path
	 *
	 * @name  The field name
	 * @value The field value
	 * @boost Optional boost value
	 *
	 * @return SearchBuilder The parent SearchBuilder for continued chaining
	 */
	SearchBuilder function term(
		required string name,
		required any value,
		numeric boost
	){
		var termQuery = { "term" : { "#arguments.name#" : arguments.value } };

		if ( !isNull( arguments.boost ) ) {
			termQuery.term[ arguments.name ] = {
				"value" : arguments.value,
				"boost" : javacast( "float", arguments.boost )
			};
		}

		appendToQueryPath( termQuery );
		return variables.searchBuilder;
	}

	/**
	 * Adds a terms query at the current query path
	 *
	 * @name  The field name
	 * @value The field values (array or list)
	 * @boost Optional boost value
	 *
	 * @return SearchBuilder The parent SearchBuilder for continued chaining
	 */
	SearchBuilder function terms(
		required string name,
		required any value,
		numeric boost
	){
		if ( !isArray( arguments.value ) ) {
			arguments.value = listToArray( arguments.value );
		}

		var termsQuery = { "terms" : { "#arguments.name#" : arguments.value } };

		if ( !isNull( arguments.boost ) ) {
			termsQuery.terms[ arguments.name ] = {
				"value" : arguments.value,
				"boost" : javacast( "float", arguments.boost )
			};
		}

		appendToQueryPath( termsQuery );
		return variables.searchBuilder;
	}

	/**
	 * Adds a match query at the current query path
	 *
	 * @name  The field name
	 * @value The field value
	 * @boost Optional boost value
	 *
	 * @return SearchBuilder The parent SearchBuilder for continued chaining
	 */
	SearchBuilder function match(
		required string name,
		required any value,
		numeric boost
	){
		var matchQuery = { "match" : { "#arguments.name#" : arguments.value } };

		if ( !isNull( arguments.boost ) ) {
			matchQuery.match[ arguments.name ] = {
				"query" : arguments.value,
				"boost" : javacast( "float", arguments.boost )
			};
		}

		appendToQueryPath( matchQuery );
		return variables.searchBuilder;
	}

	/**
	 * Adds a wildcard query at the current query path
	 *
	 * @name  The field name
	 * @value The wildcard pattern
	 * @boost Optional boost value
	 *
	 * @return SearchBuilder The parent SearchBuilder for continued chaining
	 */
	SearchBuilder function wildcard(
		required string name,
		required string value,
		numeric boost
	){
		var wildcardQuery = { "wildcard" : { "#arguments.name#" : { "value" : arguments.value } } };

		if ( !isNull( arguments.boost ) ) {
			wildcardQuery.wildcard[ arguments.name ][ "boost" ] = javacast( "float", arguments.boost );
		}

		appendToQueryPath( wildcardQuery );
		return variables.searchBuilder;
	}

	/**
	 * Adds a range query at the current query path
	 *
	 * @name  The field name
	 * @gte   Greater than or equal to value
	 * @gt    Greater than value
	 * @lte   Less than or equal to value
	 * @lt    Less than value
	 * @boost Optional boost value
	 *
	 * @return SearchBuilder The parent SearchBuilder for continued chaining
	 */
	SearchBuilder function range(
		required string name,
		any gte,
		any gt,
		any lte,
		any lt,
		numeric boost
	){
		var rangeParams = {};

		if ( !isNull( arguments.gte ) ) rangeParams[ "gte" ] = arguments.gte;
		if ( !isNull( arguments.gt ) ) rangeParams[ "gt" ] = arguments.gt;
		if ( !isNull( arguments.lte ) ) rangeParams[ "lte" ] = arguments.lte;
		if ( !isNull( arguments.lt ) ) rangeParams[ "lt" ] = arguments.lt;
		if ( !isNull( arguments.boost ) ) rangeParams[ "boost" ] = javacast( "float", arguments.boost );

		var rangeQuery = { "range" : { "#arguments.name#" : rangeParams } };

		appendToQueryPath( rangeQuery );
		return variables.searchBuilder;
	}

	/**
	 * Adds an exists query at the current query path
	 *
	 * @name The field name to check for existence
	 *
	 * @return SearchBuilder The parent SearchBuilder for continued chaining
	 */
	SearchBuilder function exists( required string name ){
		var existsQuery = { "exists" : { "field" : arguments.name } };
		appendToQueryPath( existsQuery );
		return variables.searchBuilder;
	}

	/**
	 * Private helper method to append a query to the current query path
	 *
	 * @query The query object to append
	 */
	private void function appendToQueryPath( required struct query ){
		var pathParts = listToArray( variables.queryPath, "." );
		var queryRef  = variables.searchBuilder.getQuery();
		var current   = queryRef;

		// Navigate to the target location, creating structures as needed
		for ( var i = 2; i <= arrayLen( pathParts ); i++ ) {
			var part = pathParts[ i ];

			if ( !structKeyExists( current, part ) ) {
				// Determine if this should be an array or struct based on the context
				if ( arrayFind( [ "must", "should", "must_not" ], part ) ) {
					current[ part ] = [];
				} else {
					current[ part ] = {};
				}
			}

			current = current[ part ];
		}

		// Append to array or set in struct
		var lastPart = pathParts[ arrayLen( pathParts ) ];
		if ( arrayFind( [ "must", "should", "must_not" ], lastPart ) ) {
			arrayAppend( current, arguments.query );
		} else {
			structAppend( current, arguments.query, true );
		}
	}

}
