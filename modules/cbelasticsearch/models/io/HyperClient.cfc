/**
*
* Elasticsearch Hyper Native Client
*
* @package cbElasticsearch.models
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component
	accessors="true"
	threadSafe
	singleton
{

    property name="log" inject="logbox:logger:{this}";

	/**
	* The Elasticsearch version target for this client
	**/
	property name="versionTarget";

	/**
	 * Instance configuration object
	 */
	property name="instanceConfig";

	/**
	 * Utility object
	 */
	property name="util";

    /**
     * Pool singleton
     */
    property name="nodePool";


	/**
	* Config provider
	**/
	cbElasticsearch.models.Config function getConfig() provider="Config@cbElasticsearch"{}

	/**
	 * Util provider
	 */
    cbElasticsearch.models.util.Util function getUtil() provider="Util@cbElasticsearch"{}

    /**
     * Pool provider
     */
    cbElasticsearch.models.io.HyperPool function newPool() provider="HyperPool@cbElasticsearch"{}

	/**
	* Document provider
	**/
	cbElasticsearch.models.Document function newDocument() provider="Document@cbElasticsearch"{}

	/**
	* Task provider
	**/
    cbElasticsearch.models.Task function newTask() provider="Task@cbElasticsearch"{}
    

	/**
	* SearchBuilder provider
	**/
	cbElasticsearch.models.SearchBuilder function newBuilder() provider="SearchBuilder@cbElasticsearch"{}

	/**
	* SearchResult provider
	**/
	cbElasticsearch.models.SearchResult function newResult() provider="SearchResult@cbElasticsearch"{}

	function init( cbElasticsearch.models.Config configuration ){
		if( structKeyExists( arguments, "configuration" ) ){
			variables.instanceConfig = arguments.configuration;
        }
        
        return this;
	}

	/**
	* Configure instance once DI is complete
	**/
	any function onDIComplete(){

		configure();

	}

	void function configure( cbElasticsearch.models.Config configuration ){

		lock type="exclusive" name="HyperClientConfigurationLock" timeout="10"{

			if( isNull( getInstanceConfig() ) ){
				variables.instanceConfig = getConfig();
			}

			variables.util = getUtil();

			var configSettings = variables.instanceConfig.getConfigStruct();
			
			variables.nodePool = newPool().configure( variables.instanceConfig );

			// perform a little introspect on the start page to see what version we are on
			if( len( configSettings.versionTarget ) ){
				variables.versionTarget = configSettings.versionTarget;
			} else {

				var startPage = variables.nodePool
                                .newRequest( 
                                    "",
                                    "GET"
								)
								.send()
								.json();

				try{
					if( isSimpleValue( startPage.version ) ){
						variables.versionTarget = startPage.version;
					} else {
						variables.versionTarget = startPage.version.number;
					}
				} catch( any e ){
					variables.versionTarget = '7.0.0';
					log.error( "A connection to the elasticsearch server could not be established.  This may be due to an authentication issue or the server may not be available at this time.  The version target has been set to #variables.versionTarget#." );
				}
			}


        }

	}


	/**
    * Closes any connections to the pool and destroys the client singleton
    * Not utilized as connections to the pool resources with this client are not maintained
	* @interfaced
	**/
	void function close(){
		return;
	}


	/**
	* Execute a client search request
	* @searchBuilder 	SearchBuilder 	An instance of the SearchBuilder object
	*
	* @return 			iNativeClient 	An implementation of the iNativeClient
	* @interfaced
	**/
	cbElasticsearch.models.SearchResult function executeSearch( required cbElasticsearch.models.searchBuilder searchBuilder ){

        var requestBuilder = variables.nodePool
                                .newRequest( 
                                    SearchBuilder.getIndex() & '/_search',
                                    "POST"
                                )
                                .setBody( arguments.searchBuilder.getJSON() )
                                .asJSON();

		parseParams( arguments.searchBuilder.getParams() ).each( function( param ){
            requestBuilder.setQueryParam( param.name, param.value );
        } );
        
        var response = requestBuilder.send();

        if( response.getStatusCode() == 200 ){
            return newResult().new( response.json() );
        } else {
            onResponseFailure( response );
        }

    }
    


	/**
	* Retreives a count of documents matching the given query
	* @searchBuilder 	[SearchBuilder] 	An instance of the SearchBuilder object
	*
	* @return 			numeric         The returned count matching the search parameters
	* @interfaced
	*/
	numeric function count( required cbElasticsearch.models.searchBuilder searchBuilder ){

        var requestBuilder = variables.nodePool
                                .newRequest( 
                                    SearchBuilder.getIndex() & '/_count',
                                    "POST"
                                )
                                .setBody( serializeJSON( 
                                    { 
                                        "query" : arguments.searchBuilder.getQuery() 
                                    }, 
                                    false, 
                                    listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false  )
                                )
                                .asJSON();
        
        var response = requestBuilder.send();

        if( response.getStatusCode() == 200 ){
            return response.json()[ "count" ];
        } else {
            onResponseFailure( response );
        }

	}

	/**
	* Verifies whether an index exists
	*
	* @indexName 		string 		the name of the index
	* @interfaced
	**/
	boolean function indexExists( required string indexName ){

        return ( 
            variables.nodePool
            .newRequest( 
                arguments.indexName,
                "HEAD"
            ).send()
            .getStatusCode() < 400 
        );

	}

	/**
	* Verifies whether an index mapping exists
	*
	* @indexName 		string 		the name of the index
	* @mapping 			string 		the name of the mapping
	* @interfaced
	**/
	boolean function indexMappingExists(
		required string indexName,
		required string mapping
	){

        var request =  variables.nodePool
                        .newRequest( 
                            arguments.indexName & '/mapping/' & arguments.mapping,
                            "HEAD"
                        ).send();
        return ( 
           
            request.getStatusCode() == 200
            &&
            !structIsEmpty( request.json() ) 
        );

	}

	/**
	* Applies an index item ( create/update )
	* @indexBuilder 	IndexBuilder 	An instance of the IndexBuilder object
	*
	* @return 			struct 		A struct representation of the transaction result
	* @interfaced
	**/
	boolean function applyIndex( required cbElasticsearch.models.IndexBuilder indexBuilder ){

		var indexResult = {};

		if( isNull( arguments.indexBuilder.getIndexName() ) ){
			throw(
				type="cbElasticsearch.HyperClient.InvalidIndexException",
				message="The index configuration provided does not contain a name.  All indexes must be named."
			);
		}

		var indexDSL = arguments.indexBuilder.getDSL();

		var indexName = indexDSL.name;
		structDelete( indexDSL, "name" );

		if( structKeyExists( indexDSL, "aliases") && structIsEmpty( indexDSL.aliases ) ){
			structDelete( indexDSL, "aliases" );
		}

		if( 
			isMajorVersion( 7 )
			&& structKeyExists( indexDSL, "mappings" ) 
			&& !structIsEmpty( indexDSL.mappings )
			&& !structKeyExists( indexDSL.mappings, "properties" )
		){
			if( indexDSL.mappings.keyArray().len() > 1 ){
				throw(
					type="cbElasticsearch.HyperClient.InvalidMappingException",
					message="Elasticsearch no longer supports multiple types per index. The following types were found:  #indexDSL.mappings.keyArray().toList()# Please adjust your mapping to reflect only one type"
				);
			}
			indexDSL.mappings = indexDSL.mappings[ indexDSL.mappings.keyArray()[ 1 ] ];
		}

		if( 
			isMajorVersion( 7 )
			&& structKeyExists( indexDSL, "mappings" )
			&& structKeyExists( indexDSL.mappings, "_all" )
		){
			structDelete( indexDSL.mappings, "_all" );
		}

		if( !indexExists( indexName ) ){

            var requestBuilder =  variables.nodePool
                        .newRequest( 
                            indexName,
                            "PUT"
                        )
                        .setBody( 
							serializeJSON( 
								indexDSL, 
								false, 
								listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false 
							)
						 )
                        .asJSON();


            var response = requestBuilder.send();

            if( response.getStatusCode() < 299 ){
                indexResult[ "index" ] = response.json();
                if( structKeyExists( indexResult[ "index" ], "error" ) ){
                    throw(
                        type="cbElasticsearch.HyperClient.IndexCreationException",
                        message="Index creation returned an error status of #indexResult.index.status#.  Reason: #( isSimpleValue( indexResult.index.error ) ? indexResult.index.error : indexResult.index.error.reason )#",
                        extendedInfo=serializeJSON( indexResult[ "index" ], false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
                    );
                }
            } else {
                onResponseFailure( response );
            }

		} else {

			indexResult[ "index" ] = {
				"error"  : true,
				"message": "Index #indexDSL.name# already exists"
            };

            if( structKeyExists( indexDSL, "mappings" ) ){
                indexResult[ "mappings" ] = applyMappings( indexDSL.name, indexDSL.mappings );
            }

		}

		return true;

	}


	/**
	* Deletes an index
	*
	* @indexName 		string 		the name of the index to be deleted
	*
	**/
	struct function deleteIndex( required string indexName ){
		return variables.nodePool
                .newRequest( 
                    arguments.indexName,
                    "DELETE"
                )
                .send()
                .json();
    }

    /**
    * Applies a reindex action
    * @interfaced
    *
    * @source               string      The source index name or struct of options
	* @destination          string      The destination index name or struct of options
	* @waitForCompletion    boolean     Whether to return the result or an asynchronous task
	* @params               any         Additional url params to add to the reindex action.
    *                                   Supports multiple formats : `requests_per_second=50&slices=5`, `{ "requests_per_second" : 50, "slices" : 5 }`, or `[ { "name" : "requests_per_second", "value" : 50 } ]` )
    * @script               any         A script to run while reindexing.
    * @throwOnError         boolean     Whether to throw an exception if the reindexing fails.  This flag is
    *                                   only used if `waitForCompletion` is `true`.
	*
	* @return               any 	    Struct result of the reindex action if waiting for completion or a Task object if dispatched asnyc
	**/
	any function reindex(
        required any source,
        required any destination,
		boolean waitForCompletion = true,
		any params,
        any script,
        boolean throwOnError = true
    ) {
        
        var requestBuilder = variables.nodePool
                                .newRequest( 
                                    "_reindex",
                                    "POST"
                                ).setQueryParam(
                                    "wait_for_completion",
                                    arguments.waitForCompletion
                                );
        
        var body = {
            "source" : generateIndexMap( arguments.source ),
            "dest" : generateIndexMap( arguments.destination )
        };


		if( structKeyExists( arguments, "params" ) ){
			parseParams( arguments.params ).each( function( param ){
				requestBuilder.setQueryParam( param.name, param.value );
			} );
		}

		if( structKeyExists( arguments, "script" ) ){
			if( isSimpleValue( arguments.script ) ){
                body[ "script" ] = { "lang" : "painless", "source" : reReplace(arguments.script,"\n|\r|\t","","ALL") };
			} else {
                body[ "script" ] = arguments.script;
			}
		}
        
        requestBuilder.setBody(
            serializeJSON(
                body,
				false,
				listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
			)
        );

		var reindexResult = requestBuilder.send().json();

        if ( arguments.waitForCompletion && arguments.throwOnError ) {

            if ( reindexResult.keyExists( "failures" ) && reindexResult.failures.len() ) {
                throw(
                    type = "cbElasticsearch.HyperClient.ReindexFailedException",
                    message = "The reindex action failed with response code [#reindexResult.status#].  There were #reindexResult.failures.len()# errors.",
                    extendedInfo = serializeJSON(
						reindexResult,
						false,
						listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
					)
                );
            } else if ( reindexResult.keyExists( "error" ) ) {
                throw(
                    type = "cbElasticsearch.HyperClient.ReindexFailedException",
                    message = "The reindex action failed with response code [#reindexResult.status#].  The cause of this exception was #reindexResult.error.reason#",
                    extendedInfo = serializeJSON(
						reindexResult,
						false,
						listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
					)
                );
            }
        }

		if ( arguments.waitForCompletion || !structKeyExists( reindexResult, "task" ) ) {
			return reindexResult;
		} else {
			return getTask( reindexResult.task );
		}
    }

    private any function generateIndexMap( required any index ) {
        if ( isSimpleValue( arguments.index ) ) {
            return { "index" : arguments.index };
        } else if ( ! isStruct( arguments.index ) ) {
            throw( "Invalid type. Pass either a string or a struct of options." );
        }

        return structReduce( arguments.index, function( indexMap, key, value ) {
            indexMap.put( key, value );
            return indexMap;
        }, {} );
	}

	/**
	 * Returns a struct containing all indices in the system, with statistics
	 *
	 * @verbose 	boolean 	whether to return the full stats output for the index
	 */
	struct function getIndices( verbose = false ){

        var statsRequest = variables.nodePool
                .newRequest( 
                    "_stats",
                    "get"
                );

		var statsResult = statsRequest.send().json();

		if( arguments.verbose ){
			return statsResult.indices;
		} else {
			// var scoping this outside of the reduce method seems to prevent missing data on ACF, post-reduction
			var indexMap = {};
			// using an each loop as keys seem to be skipped on ACF
			statsResult.indices.keyArray().each( function( key ){
				indexMap[ key ] = {
					"uuid" : statsResult.indices[ key ][ "uuid" ],
					"size_in_bytes": statsResult.indices[ key ][ "total" ][ "store" ][ "size_in_bytes" ],
					"docs": statsResult.indices[ key ][ "total" ][ "docs" ][ "count" ]
				};
			} );
			return indexMap;
		}
	}

	/**
	 * Returns a struct containing the mappings of all aliases in the cluster
	 *
	 * @aliases
	 */
	struct function getAliases(){
        var aliasesResult = variables.nodePool
                            .newRequest( 
                                "_alias"
                            )
                            .setThrowOnError( true )
                            .send()
                            .json();

		// var scoping this outside of the reduce method seems to prevent missing data on ACF, post-reduction
		var aliasesMap = {
			"aliases" : {},
			"unassigned" : []
		};

		// using an each loop since reduce seems to cause an empty "unassigned" array to disappear on Lucee 5 and keys to come up missing on ACF
		aliasesResult.keyArray().each(
			function( indexName ){
				if( structKeyExists( aliasesResult[ indexName], "aliases" ) && !structIsEmpty( aliasesResult[ indexName].aliases ) ){
					// we need to scope this for the ACF compiler
					var indexObj = aliasesResult[ indexName];
					indexObj.aliases.keyArray().each( function( alias ){
						aliasesMap.aliases[ alias ] = indexName;
					} );
				} else {
					aliasesMap.unassigned.append( indexName );
				}
			}
		);

		return aliasesMap;

	}

  /**
  * Applies an alias (or array of aliases)
  *
	* @aliases    AliasBuilder    An AliasBuilder instance (or array of instances)
	*
	* @return     boolean 		  Boolean result as to whether the operations were successful
	**/
	boolean function applyAliases( required any aliases ) {
        arguments.aliases = isArray( arguments.aliases ) ? arguments.aliases : [ arguments.aliases ];
        var requestBody = { "actions" : [] };
        for ( var alias in arguments.aliases ) {
            requestBody.actions.append(
                {
                    "#alias.getAction()#" : {  
                        "index" : alias.getIndexName(),
                        "alias" : alias.getAliasName()
                    }
                }
            );
		}

        return variables.nodePool
                        .newRequest( 
                            "_aliases",
                            "POST"
                        )
                        .setBody( 
                            serializeJSON(
                                requestBody,
                                false,
                                listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
                            )
                        )
                        .asJSON()
                        .setThrowOnError( true )
                        .send()
                        .json()
                        .acknowledged;

	}


	/**
	* Applies a single mapping to an index
	* @indexName 				string 		the name of the index
	* @mappingName	 			string 		the name of the mapping
	* @mappingConfig 			struct 		the mapping configuration struct
	* @interfaced
	**/
	struct function applyMapping( required string indexName, string mappingName, required struct mappingConfig ){

		if( isMajorVersion( 7 ) ){
			// remove v7 unsupported keys
			var unsupported = [ "_all" ];
			unsupported.each( function( remove ){
				structDelete( mappingConfig, remove );
			} );

			var JSONMapping = serializeJSON(
				arguments.mappingConfig,
				false,
				listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
			);
		} else {
			var JSONMapping = serializeJSON(
					{
						"#arguments.mappingName#":arguments.mappingConfig
					},
					false,
					listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
				);
        }

        var mappingResult = variables.nodePool
                            .newRequest( 
                                "#arguments.indexName#/_mapping",
                                "PUT"
                            )
                            .setBody( JSONMapping )
                            .asJSON()
                            .setThrowOnError( true )
                            .send()
                            .json();

		if( structKeyExists( mappingResult, "error" ) ){

			throw(
				type="cbElasticsearch.HyperClient.InvalidMappingException",
				message="The mapping for #arguments.mappingName# could not be created.  Reason: #( isSimpleValue( mappingResult.error ) ? mappingResult.error : mappingResult.error.reason )#",
				extendedInfo=serializeJSON( mappingResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);

		} else{

			return mappingResult;

		}
	}


	/**
	* Applies multiple mappings to an index
	* @indexName 		string 		The name of the index
	* @mappings 		struct 		a struct containing the mapping configuration
	* @interfaced
	**/
	struct function applyMappings( required string indexName, required struct mappings ){

		var mappingResults = {};

		for( var mapKey in arguments.mappings ){

			mappingResults[ mapKey ] = applyMapping( arguments.indexName, mapKey, arguments.mappings[ mapKey ] );

		}

		return mappingResults;

	}


	/**
	* Retrieves a document by ID
	* @id 		any 		The document key
	* @index 	string 		The name of the index
	* @type 	type 		The name of the type
	* @interfaced
	*
	* @return 	any 		Returns a Document object if found, otherwise returns null
	**/
	any function get(
		required any id,
		string index,
		string type
	){
		if( isNull( arguments.index ) ){
			arguments.index = variables.instanceConfig.get( "defaultIndex" );
        }

        if( isNull( arguments.type ) || isMajorVersion( 7 ) ){
            arguments.type = '_doc';
        }
        
        var retrievedResult = variables.nodePool
                            .newRequest( 
                                "#arguments.index#/#arguments.type#/#urlEncodedFormat( arguments.id )#"
                            )
                            .setThrowOnError( false )
                            .send();

        if( 
            retrievedResult.getStatusCode() != 200
            ||
            structKeyExists( retrievedResult.json(), "error" ) 
            || 
            !retrievedResult.json().found  
        ){
            return;
        } else {
            return newDocument()
                    .setId( arguments.id )
                    .setIndex( arguments.index )
                    .setType( arguments.type )
                    .populate( retrievedResult.json()[ "_source" ] );
        }

	}

	/**
	* Gets multiple items when provided an array of keys
	* @keys 	array 		An array of keys to retrieve
	* @index 	string 		The name of the index
	* @type 	type 		The name of the type
	* @interfaced
	*
	* @return 	array 		An array of Document objects
	**/
	array function getMultiple(
		required array keys,
		string index,
		string type
	){
		if( isNull( arguments.index ) ){
			arguments.index = variables.instanceConfig.get( "defaultIndex" );
		}

        var requestBody = { "docs" : [] };

        arguments.keys.each( function( requested ){
            if( isStruct( requested ) ){
                requestBody.docs.append( 
                    {
                        "_id" : requested.keyExists( "_id" ) ? requested._id : requested.id,
                        "_index" : requested.keyExists( "_index" ) ? requested._index : index
                    }
                );
            } else {
                requestBody.docs.append( 
                    {
                        "_id" : requested,
                        "_index" : index
                    }
                );
            }
        } );

        var retrievedResult = variables.nodePool
                                .newRequest( 
									"_mget",
									"POST"
                                )
                                .setBody( 
                                    serializeJSON(
                                        requestBody,
                                        false,
                                        listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
                                    )
                                )
                                .asJSON()
                                .send()
								.json();

		if( !structKeyExists( retrievedResult, "docs" ) ){

			return [];

		} else {

			var documents = [];

			for( var result in retrievedResult.docs ){

				if( !structKeyExists( result, "_source" ) ) continue;

				var document = newDocument().new(
					result[ "_index" ],
					result[ "_type" ],
					result[ "_source" ]
				).setId( result[ "_id" ] );

				arrayAppend( documents, document );

			}

			return documents;
		}
	}

	/**
	 * Retreives a task and its status
	 *
	 * @taskId          string                          The identifier of the task to retreive
	 * @taskObj         Task                            The task object used for population - defaults to a new task
	 *
	 * @interfaced
	 */
	any function getTask( required string taskId, cbElasticsearch.models.Task taskObj=newTask() ){

        var taskResult = variables.nodePool
                                .newRequest( "_tasks/#arguments.taskId#" )
                                .send();

        if(  taskResult.getStatusCode() != 200 ){
			taskResult = taskResult.json();
            throw(
				type="cbElasticsearch.JestClient.InvalidTaskException",
				message="A task with an identifier of #arguments.taskId# could not be found. The error returned was: #( isSimpleValue( taskResult.error ) ? taskResult.error : taskResult.error.reason )#",
				extendedInfo=serializeJSON( taskResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
        }

        return taskObj.populate( taskResult.json() );


	}

	/**
	 * Retreives all tasks running on the cluster
	 *
	 * @interfaced
	 */
	any function getTasks(){

        var tasksResult = variables.nodePool
                            .newRequest( "_tasks" )
                            .setQueryParam( "detailed", true )
                            .send()
                            .json();

                            var tasks = [];
		tasksResult.nodes.keyArray().each( function( node ){
			var nodeObj = tasksResult.nodes[ node ];
			nodeObj.tasks.keyArray().each( function( taskId ){
				var taskProperties = nodeObj.tasks[ taskId ];
				tasks.append( newTask().populate( taskProperties) );
			} );
		} );

		return tasks;
	}

	/**
	* @document 		Document@cbElasticSearch 		An instance of the elasticsearch Document object
	*
	* @return 			iNativeClient 					An implementation of the iNativeClient
	* @interfaced
	**/
	cbElasticsearch.models.Document function save( required cbElasticsearch.models.Document document ){

       if( isNull( document.getId() ) ){
        var saveRequest = variables.nodePool
                            .newRequest( 
                                "#document.getIndex()#/_doc",
                                "POST" 
                            );
       } else {
        var saveRequest = variables.nodePool
                            .newRequest( 
                                "#document.getIndex()#/_doc/#urlEncodedFormat( document.getId() )#",
                                "PUT" 
                            );
       }


       var saveResult = saveRequest
                                .setBody( 
                                    serializeJSON( 
                                        document.getMemento(), 
                                        false, 
                                        listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false 
                                    ) 
                                )
								.send()
								.json();

		if( structKeyExists( saveResult, "error" ) ){

			throw(
				type="cbElasticsearch.HyperClient.SaveException",
				message="Document could not be saved.  The error returned was: #( isSimpleValue( saveResult.error ) ? saveResult.error : saveResult.error.reason )#",
				extendedInfo=serializeJSON( saveResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
        }

		arguments.document.setId( saveResult[ "_id" ] );

		arguments.document.setMemento( arguments.document.getMemento() );

		return arguments.document;

	}

	/**
	* Deletes a single document
	* @document 		Document 		the Document object for the document to be deleted
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	**/
	boolean function delete( required any document, boolean throwOnError=true ){

		var deleteResult = variables.nodePool
                            .newRequest( 
                                "#document.getIndex()#/_doc/#urlEncodedFormat( document.getId() )#",
                                "DELETE" 
                            )
                            .send()
                            .json();

		if( arguments.throwOnError && structKeyExists( deleteResult, "error" ) ){
			throw(
				type="cbElasticsearch.HyperClient.DocumentDeletionException",
				message="Document could not be deleted.  The error returned was: #( isSimpleValue( deleteResult.error ) ? deleteResult.error : deleteResult.error.reason )#",
				extendedInfo=serializeJSON( deleteResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		return true;
	}

	/**
	* Deletes items in the index by query
	* @searchBuilder 		SearchBuilder 		The search builder object to use for the query
	* @waitForCompletion    boolean             Whether to block the request until completion or return a task which can be checked
	**/
	any function deleteByQuery( required cbElasticsearch.models.SearchBuilder searchBuilder, boolean waitForCompletion = true ){

		if( isNull( arguments.searchBuilder.getIndex() ) ){
			throw(
				type="cbElasticsearch.HyperClient.DeleteByQuery",
				message="deleteByQuery() could not be executed because an index was not assigned in the provided SearchBuilder object."
			);
        }
        
        var deleteRequest = variables.nodePool.newRequest( 
                                "#arguments.searchBuilder.getIndex()#/_delete_by_query",
                                "POST" 
                            );

        
		parseParams( arguments.searchBuilder.getParams() ).each( function( param ){
			deleteRequest.setQueryParam( param.name, param.value );
			if( param.name == 'wait_for_completion' ){
				arguments.waitForCompletion = param.value;
			}
        } );
        
        if( !arguments.waitForCompletion ){
			deleteRequest.setQueryParam( "wait_for_completion", false );
        }
        
        deleteRequest.setBody(
            serializeJSON( 
                {
                    "query" : arguments.searchBuilder.getQuery()
                },
                false,
                listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false 
            )
        );

        var deletionResult =  deleteRequest.send().json();
        
		if( arguments.waitForCompletion ){
			return deletionResult;
		} else {
			return getTask( deletionResult.task );
		}

	}

	/**
	* Updates items in the index by query
	* @searchBuilder 		SearchBuilder 		The search builder object to use for the query
	* @script 				struct 				script to process on the query
	* @waitForCompletion    boolean             Whether to block the request until completion or return a task which can be checked
	**/
	any function updateByQuery( required cbElasticsearch.models.SearchBuilder searchBuilder, required struct script, boolean waitForCompletion = true ){

		if( isNull( arguments.searchBuilder.getIndex() ) ){
			throw(
				type="cbElasticsearch.HyperClient.UpdateByQuery",
				message="updateByQuery() could not be executed because an index was not assigned in the provided SearchBuilder object."
			);
        }
        
        var updateRequest = variables.nodePool.newRequest( 
                                "#arguments.searchBuilder.getIndex()#/_update_by_query",
                                "POST" 
                            )
                            .setBody(
                                reReplace(
                                    serializeJSON(
                                        {
                                            "query" : arguments.searchBuilder.getQuery(),
                                            "script": arguments.script
                                        },
                                        false,
                                        listFindNoCase( "Lucee", server.coldfusion.productname )
                                        ? "utf-8" : false
                                    ),
                                    "\n|\r|\t","","ALL"
                                )
                            );

		parseParams( arguments.searchBuilder.getParams() ).each( function( param ){
			updateRequest.setQueryParam( param.name, param.value );
			if( param.name == 'wait_for_completion' ){
				arguments.waitForCompletion = param.value;
			}
		} );

		if( !arguments.waitForCompletion ){
			updateRequest.setQueryParam( "wait_for_completion", false );
		}


        var updateResult =  updateRequest.send().json();
        
		if( arguments.waitForCompletion ){
			return updateResult;
		} else {
			return getTask( updateResult.task );
		}

    }
    
	/**
	* Persists multiple items to the index
	* @documents 		array 					An array of elasticsearch Document objects to persist
	* @throwOnError     boolean                 Whether to throw an exception on error on individual documents which were not persisted
	*
	* @return 			array					An array of results for the saved items
	* @interfaced
	**/
	array function saveAll( required array documents, boolean throwOnError=false ){

        var requests = [];

        arguments.documents.each( function( doc ){
            // ensure the _id value is normalized in to the doc for upserts
            var memento = doc.getMemento();
            if( !isNull( doc.getId() ) ){
                memento[ "_id" ] = doc.getId();
			}
			
            requests.append(
                {
                    "doc" : memento,
					"doc_as_upsert" : true,
					"_index" : doc.getIndex()
                }
            );
		} );

        var saveResult = variables.nodePool.newRequest( 
								"_bulk",
								"POST" 
							)
							.setBody( 
								requests.reduce( 
									function( acc, action ){
										var updateObj = {
											"update" : {
												"_index" : action._index
											}
										};
										
										if( action.doc.keyExists( "_id" ) ){
											updateObj.update[ "_id" ] = action.doc._id;
										}

										structDelete( action, "_index" );
										structDelete( action.doc, "_id" );

										// action directive
										acc &= serializeJSON(
										updateObj, 
										false, 
										listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
										) & chr(10);

										// document directive
										acc &= serializeJSON( 
											action, 
											false, 
											listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
										) & chr(10);
										
										return acc;
									},
									""
								)
							)
							.send()
                            .json();


		if( arguments.throwOnError && structKeyExists( saveResult, "error" ) ){
			throw(
				type="cbElasticsearch.HyperClient.BulkSaveException",
				message="Documents could not be saved.  The error returned was: #( isSimpleValue( saveResult.error ) ? saveResult.error : saveResult.error.reason )#",
				extendedInfo=serializeJSON( saveResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		var results = [];

		for( var item in saveResult.items ){

			if( arguments.throwOnError && item.update.keyExists( "error" ) ){
				throw(
					type="cbElasticsearch.HyperClient.BulkSaveException",
					message="A document with an identifier of #item.update[ "_id" ]# could not be saved.  The error returned was: #( isSimpleValue( item.update.error ) ? item.update.error : item.update.error.reason )#",
					extendedInfo=serializeJSON( saveResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
				);
			}
			arrayAppend(
				results,
				{
					"_id"    : item.update[ "_id" ],
					"_index" : item.update[ "_index" ],
					"result" : item.update.keyExists( "result" ) ? item.update.result : javacast( "null", 0 ),
					"error" : item.update.keyExists( "error" ) ? item.update.error : javacast( "null", 0 )
				}
			);
		}

		return results;
	}

	/**
	* Deletes documents from an array of documents or IDs
	* @documents 	array 		Either an array of Document objects
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	**/
	any function deleteAll(
		required array documents,
		boolean throwOnError=false
	){

        
        var requests = [];

        arguments.documents.each( function( doc ){
            requests.append(
                {
                    "delete" : { "_index" : doc.getIndex(), "_id" : doc.getId() }
                }
            );
        } );

        var deleteResult = variables.nodePool.newRequest( 
                                "_bulk",
                                "POST" 
                            )
                            .setBody( 
                                requests.reduce( 
                                    function( acc, action ){
                                        acc &= serializeJSON( 
                                            action, 
                                            false, 
                                            listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
										) & chr(13);
										return acc;
                                    },
                                    ""
                                )
                            )
                            .send()
                            .json();


		if( arguments.throwOnError && structKeyExists( deleteResult, "error" ) ){

			throw(
				type="cbElasticsearch.HyperClient.PersistByQuery",
				message="Document could not be deleted.  The error returned was: #( isSimpleValue( deleteResult.error ) ? deleteResult.error : deleteResult.error.reason )#",
				extendedInfo=serializeJSON( deleteResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		return true;

    }
    
    
    function onResponseFailure( required Hyper.models.HyperResponse response ){
        throw( 
            type = "cbElasticsearch.invalidRequest",
            message = "Your request was invalid.  The response returned was #serializeJSON( response.getData() )#"
        );
    }

	/**
	 * Parses a parameter argument.
	 * upports multiple formats : `requests_per_second=50&slices=5`, `{ "requests_per_second" : 50, "slices" : 5 }`, or `[ { "name" : "requests_per_second", "value" : 50 } ]` )
	 *
	 * @params any the parameters to filter and transform
	 */
	array function parseParams( required any params ){
		if( isArray( arguments.params ) ){
			// assume this is the return format - [ { "name" : name, "value", "value" } ]
			return arguments.params;
		} else if( isSimpleValue( arguments.params ) ){
			return listToArray( urlDecode( arguments.params ), "&" ).map( function( paramString ){
				var paramName = listFirst( paramString, "=" );
				var paramValue = listLast( paramString, "=" );
				return {
					"name" : paramName,
					// the conditional allows us to accept a param like `&wait_for_completion`
					"value" : ( paramValue != paramName ) ? paramValue : true
				};
			} );
		} else {
			return arguments.params.keyArray().map( function( key ){
				return { "name" : key, "value" : params[ key ] };
			} );
		}
	}

	/**
	 * Returns a boolean as to whether the target version matches a major version
	 *
	 * @versionNumber
	 */
	private boolean function isMajorVersion( required numeric versionNumber ){
		return listGetAt( variables.versionTarget, 1, "." ) == versionNumber;
	}


}
