/**
*
* Elasticsearch Search Result Object
* 
* @package cbElasticsearch.models
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
* 
*/
component accessors="true"{

	/**
	* The array of result hits
	**/
	property name="hits";

	/**
	* The array of result of aggregations
	**/
	property name="aggregations";

	/**
	* The total number of hits
	**/
	property name="hitCount";

	/**
	* The paging limit
	**/
	property name="limit";

	/**
	* The starting record number
	**/
	property name="start";

	/**
	* The maximum score of the hits retrieved
	**/
	property name="maxScore";

	/**
	* The execution time, in MS
	**/
	property name="executionTime";

	function init(){
		variables.start    = 0;
		variables.hits     = [];
		variables.hitCount = 0;
		variables.maxScore = 0;
	}

	Document function newDocument() provider="Document@cbElasticsearch"{}


	/**
	* Creates a new SearchResult instance
	* @properties 		struct 		A search result struct ( e.g. JEST Client result object ) to populate the results object
	**/
	SearchResult function new( struct properties ){

		init();
		
		if( structKeyExists( arguments, "properties" ) ){

			populate( arguments.properties );
	
		}

		return this;


	}

	/**
	* Populates the search result object from a struct
	* @properties 		struct 		A search result struct ( e.g. JEST Client result object ) to populate the results object
	**/
	SearchResult function populate( required struct properties ){

		if( structKeyExists( arguments.properties, "hits" ) ){
			var hits = arguments.properties.hits;
		} else {
			var hits = arguments.properties;
		}

		// Throw if our configuration doesn't contain a valid search response
		if( !isStruct( hits ) || !structKeyExists( hits, "total" ) ){

			var error = {
				type            = "cbElasticsearch.SearchResult.ClientErrorException",
				message         = "The properties provided to the populate() method do not contain a valid search response",
				extendedInfo 	= serializeJSON( arguments.properties )
			};

			if( structKeyExists( arguments.properties, "error" ) ){
				error.message &= " Reason: #arguments.properties.error.reason#"
			}

			throw( argumentCollection=error );

		}

		if( structKeyExists( arguments.properties, "aggregations" ) ){
			varaibles.aggregations = arguments.properties.aggregations;
		}

		variables.hitCount = hits[ "total" ];

		if( structKeyExists( hits, "max_score" ) ){
			variables.maxScore = hits[ "max_score" ];		
		}

		return populateHits( hits.hits );
	}


	/**
	* Populates the hits of the search with documents
	* @hits 	array 		The array of search results hits
	**/
	SearchResult function populateHits( required array hits ){
		
		variables.hits = [];

		for( var hit in arguments.hits ){
			var doc = newDocument().populate( hit[ "_source" ] );
			
			doc.setIndex( hit[ "_index" ] );
			
			if( structKeyExists( hit, "_type" ) ){
				doc.setType( hit[ "_type" ] );
			}

			doc.setId( hit[ "_id" ] );

			doc.setScore( hit[ "_score" ] );

			arrayAppend( 
				variables.hits, 
				doc
			);
		}

		return this;

	}
}