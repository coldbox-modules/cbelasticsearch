/**
*
* Elasticsearch Search Result Object
*
* @package cbElasticsearch.models
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component accessors="true" {

	/**
	* The array of result hits
	**/
	property name="hits";

	/**
	* The array of result of aggregations
	**/
    property name="aggregations";

    /**
	* The struct result of suggestions
	**/
	property name="suggestions";

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
	* If the search is collapsed, this will be the pagination total count for the result set
	**/
	property name="collapsedCount";

	/**
	* If the search is collapsed, this will contain a map of collapsed key value/count pairs
	**/
	property name="collapsedOccurrences";

	/**
	* The execution time, in MS
	**/
	property name="executionTime";

	property name="Util" inject="Util@cbElasticsearch";

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

			var errorReason = ( arguments.properties.keyExists( "error" ) 
								&& arguments.properties.error.keyExists( "root_cause" ) 
							  )
								? " Reason: #arguments.properties.error.root_cause.reason#" 
								: ( 
									structKeyExists( arguments.properties, "error" ) 
									? " Reason: #arguments.properties.error.reason#" 
									: "" 
								  );

			throw(

				type            = "cbElasticsearch.SearchResult.ClientErrorException",
				message         = "The server did not return a valid search response. This may be due to syntax errors in your query or credentials." & errorReason,
				extendedInfo 	= variables.Util.toJSON( arguments.properties )

			);

		}

		if( structKeyExists( arguments.properties, "aggregations" ) ){
			variables.aggregations = arguments.properties.aggregations;

			if( variables.aggregations.keyExists( "collapsed_count" ) ){
				variables.collapsedCount = variables.aggregations[ "collapsed_count" ].value;
				structDelete( variables.aggregations, "collapsed_count" );
			}

			if( variables.aggregations.keyExists( "collapsed_occurrences" ) ){
				variables.collapsedOccurrences = variables.aggregations[ "collapsed_occurrences" ].buckets.reduce(
					function( result, item ){
						arguments.result[ item.key ] = item.doc_count;
						return result;
					},
					{}
				);
				structDelete( variables.aggregations, "collapsed_occurrences" );
			}

			if( variables.aggregations.isEmpty() ) variables.aggregations = javacast( "null", 0 );
        }

        if ( structKeyExists( arguments.properties, "suggest" ) ) {
			variables.suggestions = arguments.properties.suggest;
		}

		variables.hitCount = isSimpleValue( hits[ "total" ] ) ? hits[ "total" ] : hits[ "total" ][ "value" ];

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

			if( structKeyExists( hit, "_score" ) ){
				doc.setScore( hit[ "_score" ] );
			}

			if ( structKeyExists( hit, "highlight" ) ) {
				doc.setHighlights( hit[ "highlight" ] );
			}

			arrayAppend(
				variables.hits,
				doc
			);
		}

		return this;

	}
}
