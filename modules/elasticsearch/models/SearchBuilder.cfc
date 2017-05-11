/**
*
* Elasticsearch Search Builder Object
* 
* @package cbElasticsearch.models
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
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
	* Property containing an array of sort commands
	**/
	property name="sorting";

	/**
	* Property containing an elasticsearch scripting dsl string
	**/
	property name="script";

	/**
	* When performing matching searches, the type of match to specify
	**/
	property name="matchType";

	// Optional search defaults
	property name="maxRows";
	property name="startRow";


	function onDIComplete(){
		
		reset();		
		
	}

	function reset(){
		
		variables.index        	= variables.configObject.get( "defaultIndex" );
		
		var nullDefaults = [ "id","sorting","aggregations","script","maxRows","sortRows" ]
		
		//ensure defaults, in case we are re-using a search builder with new()
		variables.matchType    	= "any";
		variables.query 		= {};

		for( var default in nullDefaults ){
			if( !isNull( variables[ default ] ) ){
				variables[ default ] = javacast( "null", 0 );
			}
		}
	}

	/**
	* Client provider
	**/
	Client function getClient() provider="Client@cbElasticsearch"{}

	/**
	* Persists the document to Elasticsearch
	**/
	function execute(){
		return getClient().executeSearch( this );
	}
	

	/**
	* Populates a new SearchBuilder object
	* @index 		string 		the name of the index to search
	* @type 		string 		the index type identifier
	* @properties 	struct		a struct representation of the search
	**/
	SearchBuilder function new( 
		string index, 
		string type, 
		struct properties 
	){
		reset();

		if( !isNull( arguments.index ) ){
			variables.index = arguments.index;
		}

		if( !isNull( arguments.type ) ){
			variables.type = arguments.type;
		}

		if( !isNull( arguments.properties ) ){
		
			for( var propName in arguments.properties ){

				switch( propName ){
						
					case "match":{

						if( !structKeyExists( variables.query, "match" ) ){
							variables.query[ "match" ] = {}
						}

						structAppend( variables.query.match, arguments.properties[ propName ] );					
						
						break;

					}
					case "aggregations":{

						if( !isStruct( arguments.properties[ propName ] ) ){
							throw( 
								type    = "cbElasticsearch.SearchBuilder.AggregationException",
								message = "The value #serializeJSON( arguments.properties[ propName ] )# could not be converted to a valid aggregation"
							);
						}

						for( var aggregationKey in arguments.properties[ propName ] ){
							aggregation( aggregationKey, arguments.properties[ propName ][ aggregationKey ] );
						}

						break;

					}
					case "sort":{

						sort( arguments.properties[ propName ] );

						break;

					}
					default:{

						match( 
							propName, 
							arguments.properties[ propName ] 
						);
								
					}

				}
			}	

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
	SearchBuilder function term( 
		required string name, 
		required any value, 
		numeric boost
	){
		if( !structKeyExists( variables.query, "term" ) ){
			
			variables.query[ "term" ] = {};

		}
		
		if( !isNull( arguments.boost ) ){		
	
			variables.query[ "term" ][ arguments.name ] = {
				"value" : arguments.value,
				"boost" : javacast( "float", arguments.boost )
			}
	
		} else {
	
			variables.query[ "term" ][ arguments.name ] = arguments.value;
	
		}

		return this;

	}


	/**
	* Applies a match requirement to the search builder query
	* https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html
	* 
	* @name 		string 		the name of the key to search
	* @value 		string 		the value of the key
	* @matchType 	string 		a match type ( default="all" )
	* @boost 		numeric		A numeric boost option for any exact matches
	* @options 		struct 		An additional struct map of Elasticsearch query options to 
	*							pass in to the match parameters ( e.g. - operator, zero_terms_query, etc )
	**/
	SearchBuilder function match( 
		required string name, 
		required any value, 
		string matchType=variables.matchType, 
		numeric boost,
		struct options
	){

		if( !structKeyExists( variables.query, "match" ) ){
			
			variables.query[ "match" ] = {};

		}

		if( !isNull( arguments.boost ) ){		
	
			variables.query[ "match" ][ arguments.name ] = {
				"query" : arguments.value,
				"boost" : javacast( "float", arguments.boost )
			}
	
		} else {
	
			variables.query[ "match" ][ arguments.name ] = arguments.value;
	
		}

		if( !isNull( arguments.options ) ){

			//convert our query to the long form DSL so we can append options
			if( !isStruct( variables.query[ "match" ][ arguments.name ] ) ){
				
				variables.query[ "match" ][ arguments.name ] = {
					"query" : arguments.value
				};

			}
			
			

			for( var optionKey in arguments.options ){

				variables.query[ "match" ][ arguments.name ][ optionKey ]=arguments.options[ optionKey ];
			
			}
		}

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
		
		if( isNull( variables.aggregations ) ){
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
			
		if( isNull( variables.sorting ) ){
			variables.sorting = [];
		}

		// represents the actual sort array passed to the client
		if( isArray( arguments.sort ) ){

			arrayAppend( variables.sorting, arguments.sort, true );
		
		// a friendly `[fieldName] [ORDER]` like we would use with SQL ( e.g. `name ASC` )
		} else if( isSimpleValue( arguments.sort ) && isNull( arguments.sortConfig ) ) {

			var sortDirectives = listToArray( arguments.sort, "," );

			for( var sortDirective in sortDirectives ){
				var directiveItems = listToArray( sortDirective, " " );

				arrayAppend( 
					variables.sorting, 
					{
						"#directiveItems[ 1 ]#" : { "order" : arrayLen( directiveItems ) > 1 ? lcase( directiveItems[ 2 ] ) : "asc" }
					} 
				);

			}

		// name value argument pair
		} else if( isSimpleValue( arguments.sort ) && !isNull( arguments.sortConfig ) ) {

			// Our sort config argument can be a complex struct or a simple value
			arrayAppend( variables.sorting, {
				arguments.sort : isStruct( arguments.sortConfig ) ? arguments.sortConfig : { "order" : arguments.sortConfig }
			} );

		// Structural representation, which will be treated as individual items in the sort array
		} else if( isStruct( arguments.sort ) ){

			for( var sortKey in arguments.sort ){
			
				arrayAppend( 
					variables.sorting, 
					{
						"#sortKey#" : { "order"	: arguments.sort[ sortKey ] }
					} 
				);

			}

		// Throw hard if we have no idea how to handle the provided search configuration
		} else {
			
			throw( 
				type    = "cbElasticsearch.SearchBuilder.InvalidSortArgumentException",
				message = "The provided sort argument #serializeJSON( arguments.sort )# could not be parsed to a valid SearchBuilder sort configuration"
			);

		}


		return this;


	}

	struct function getDSL(){
		var dsl = {
			"query" : variables.query
		}

		if( !isNull( variables.aggregations ) ){
			dsl[ "aggs" ] = variables.aggregations
		}

		if( !isNull( variables.script ) ){
			dsl[ "script" ] = variables.script;
		}

		if( !isNull( variables.sorting ) ){

			//we used a linked hashmap for sorting to maintain order
			dsl[ "sort" ] = createObject( "java", "java.util.LinkedHashMap" ).init();

			for( var sort in variables.sorting ){
				dsl.sort.putAll( sort );
			}
		}

		if( variables.matchType != 'any' ){
			switch( variables.matchType ){
				case "all":{
					dsl["query"][ "match_all" ] = {};
					if( !isNull( varibles.matchBoost ) ){
						dsl["query"][ "match_all" ][ "boost" ] = variables.matchBoost
					}
					break;
				}
				case "none":{
					dsl["query"][ "match_none" ] = {};
					if( !isNull( varibles.matchBoost ) ){
						dsl["query"][ "match_none" ][ "boost" ] = variables.matchBoost
					}
					break;
				}
			}
		}

		return dsl;
	}

	string function getJSON(){

		return serializeJSON( getDSL() );
	}

}