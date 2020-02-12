/**
*
* Elasticsearch JEST Native Client
* https://github.com/searchbox-io/Jest
*
* @package cbElasticsearch.models
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component
	accessors="true"
	implements="iNativeClient"
	threadSafe
	singleton
{

	property name="jLoader" inject="loader@cbjavaloader";

	property name="log" inject="logbox:logger:{this}";
	/**
	* The HTTP Jest Client
	**/
	property name="HTTPClient";

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
	* Config provider
	**/
	Config function getConfig() provider="Config@cbElasticsearch"{}

	/**
	 * Util provider
	 */
	Util function getUtil() provider="Util@cbElasticsearch"{}

	/**
	* Document provider
	**/
	Document function newDocument() provider="Document@cbElasticsearch"{}

	/**
	* Task provider
	**/
	Task function newTask() provider="Task@cbElasticsearch"{}

	/**
	* SearchBuilder provider
	**/
	SearchBuilder function newBuilder() provider="SearchBuilder@cbElasticsearch"{}

	/**
	* SearchResult provider
	**/
	SearchResult function newResult() provider="SearchResult@cbElasticsearch"{}

	function init( Config configuration ){
		if( structKeyExists( arguments, "configuration" ) ){
			variables.instanceConfig = arguments.configuration;
		}
	}

	/**
	* Configure instance once DI is complete
	**/
	any function onDIComplete(){

		configure();

	}

	void function configure( Config configuration ){

		lock type="exclusive" name="JestClientConfigurationLock" timeout="10"{
			
			if( isNull( getInstanceConfig() ) ){
				variables.instanceConfig =  getConfig();
			}

			variables.util = getUtil();

			var configSettings = variables.instanceConfig.getConfigStruct();

			var hostConnections = jLoader.create( "java.util.ArrayList" ).init();
	
			for( var host in configSettings.hosts ){
				arrayAppend( hostConnections, host.serverProtocol & "://" & host.serverName & ":" & host.serverPort );
			}
	
			var configBuilder = variables.jLoader
											.create( "io.searchbox.client.config.HttpClientConfig$Builder" )
											.init( hostConnections )
											.multiThreaded( javacast( "boolean", configSettings.multiThreaded ) )
											.maxConnectionIdleTime( javacast( "long", configSettings.maxConnectionIdleTime ), createObject( "java", "java.util.concurrent.TimeUnit" ).SECONDS )
											.defaultMaxTotalConnectionPerRoute( configSettings.maxConnectionsPerRoute )
											.readTimeout( configSettings.readTimeout )
											.connTimeout( configSettings.connectionTimeout )
											.maxTotalConnection( configSettings.maxConnections );
	
			if(
				structKeyExists( configSettings, "defaultCredentials" )
				&& len( configSettings.defaultCredentials.username )
			){
				configBuilder.defaultCredentials( configSettings.defaultCredentials.username, configSettings.defaultCredentials.password );
			}
	
			var factory = variables.jLoader.create( "io.searchbox.client.JestClientFactory" ).init();
	
			factory.setHttpClientConfig( configBuilder.build() );
	
			variables.HTTPClient = factory.getObject();
	
			// perform a little introspect on the start page to see what version we are on
			if( len( configSettings.versionTarget ) ){
				variables.versionTarget = configSettings.versionTarget;
			} else {
				var h = new Http(
					url    = hostConnections[ 1 ],
					method = 'GET'
				);
				if(
					structKeyExists( configSettings, "defaultCredentials" )
					&& len( configSettings.defaultCredentials.username )
				){
					h.addParam( type="header", name="Authorization", value="Basic #toBase64( configSettings.defaultCredentials.username & ':' & configSettings.defaultCredentials.password )#" );
				}
				try{
					var startPage = deSerializeJSON( h.send().getPrefix().fileContent );
					if( isSimpleValue( startPage.version ) ){
						variables.versionTarget = startPage.version;	
					} else {
						variables.versionTarget = startPage.version.number;
					}
				} catch( any e ){
					variables.versionTarget = '6.8.4';
					log.error( "A connection to the elasticsearch server at #hostConnections[ 1 ]# could not be established.  This may be due to an authentication issue or the server may not be available at this time.  The version target has been set to #variables.versionTarget#." );	
				}
			}
	
		}

	}


	/**
	* Closes any connections to the pool and destroys the client singleton
	* @interfaced
	**/
	void function close(){

		variables.HTTPClient.shutdownClient();

		return;

	}


	/**
	* Execute a client search request
	* @searchBuilder 	SearchBuilder 	An instance of the SearchBuilder object
	*
	* @return 			iNativeClient 	An implementation of the iNativeClient
	* @interfaced
	**/
	SearchResult function executeSearch( required searchBuilder searchBuilder ){

        var jSearchBuilder = variables.jLoader.create( "io.searchbox.core.Search$Builder" )
            .init( arguments.searchBuilder.getJSON() );

		var indices = listToArray( arguments.searchBuilder.getIndex() );

		for( var index in indices ){
			jSearchBuilder.addIndex( index );
		}

		if( !isNull( arguments.searchBuilder.getType() ) ){
			if( isMajorVersion( 7 ) ){
				arguments.searchBuilder.term( "_type", arguments.searchBuilder.getType() );
			} else {
				var types = listToArray( arguments.searchBuilder.getType() );
				for( var type in types ){
					jSearchBuilder.addType( type );
				}
			}
		}

		parseParams( arguments.searchBuilder.getParams() ).each( function( param ){
			jSearchBuilder.setParameter( param.name, param.value );
		} );

		var searchResult = execute( jSearchBuilder.build() );

		return newResult().new( searchResult );

	}


	/**
	* Retreives a count of documents matching the given query
	* @searchBuilder 	[SearchBuilder] 	An instance of the SearchBuilder object
	*
	* @return 			numeric         The returned count matching the search parameters
	* @interfaced
	*/
	numeric function count( searchBuilder searchBuilder ){

        var jCountBuilder = variables.jLoader.create( "io.searchbox.core.Count$Builder" )
			.init();

		if( !isNull( arguments.searchBuilder ) ){
			// We have to pull only the query from the builder or any other arguments will throw an error
			var JSONQuery = serializeJSON( { "query" : arguments.searchBuilder.getQuery() }, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false );
			jCountBuilder.query( JSONQuery );
		}

		var indices = listToArray( arguments.searchBuilder.getIndex() );

		for( var index in indices ){
			jCountBuilder.addIndex( index );
		}

		if( !isNull( arguments.searchBuilder.getType() ) ){
			if( isMajorVersion( 7 ) ){
				if( !structKeyExists( arguments.searchBuilder.getQuery(), "match_all" ) ){
					var types = listToArray( arguments.searchBuilder.getType() );
					for( var type in types ){
						arguments.searchBuilder.shouldMatch( "_type", type );
					}
				}
			} else {
				var types = listToArray( arguments.searchBuilder.getType() );
				for( var type in types ){
					jCountBuilder.addType( type );
				}
			}
		}

		var searchResult = execute( jCountBuilder.build() );

		return searchResult[ "count" ];

	}

	/**
	* Verifies whether an index exists
	*
	* @indexName 		string 		the name of the index
	* @interfaced
	**/
	boolean function indexExists( required string indexName ){

		var existsBuilder = variables.jLoader.create( "io.searchbox.indices.IndicesExists$Builder" ).init( arguments.indexName );

		//Our exists method returns no payload so we need to check the status code
		var exists = execute( existsBuilder.build(), true );

		return ( exists.getResponseCode() < 400 );

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

		var getBuilder = variables.jLoader.create( "io.searchbox.indices.mapping.GetMapping$Builder" ).init();
		getBuilder.addIndex( arguments.indexName );

		if( !isMajorVersion( 7 ) ){
			getBuilder.addType( arguments.mapping );
		}

		//Our exists method returns no payload so we need to check the status code
		var mappingResult = execute( getBuilder.build(), true );


		return ( mappingResult.getResponseCode() == 200 && !structIsEmpty( mappingResult.getJSONMap() ) );

	}

	/**
	* Applies an index item ( create/update )
	* @indexBuilder 	IndexBuilder 	An instance of the IndexBuilder object
	*
	* @return 			struct 		A struct representation of the transaction result
	* @interfaced
	**/
	boolean function applyIndex( required IndexBuilder indexBuilder ){

		var indexResult = {};

		if( isNull( arguments.indexBuilder.getIndexName() ) ){
			throw(
				type="cbElasticsearch.JestClient.MissingIndexParameterException",
				message="The index configuration provided does not contain a name.  All indexes must be named."
			);
		}

		var indexDSL = arguments.indexBuilder.getDSL();

		if( !indexExists( indexDSL.name ) ){

			var builder = variables.jloader.create( "io.searchbox.indices.CreateIndex$Builder" ).init( indexDSL.name );

			if( structKeyExists( indexDSL, "settings" ) ){
				builder.settings( util.newHashMap( indexDSL.settings ) );
			}

			if( structKeyExists( indexDSL, "aliases" ) ){
				builder.aliases( util.newHashMap( indexDSL.aliases ) );
			}

			indexResult[ "index" ] = execute( builder.build() );

			if( structKeyExists( indexResult[ "index" ], "error" ) ){
				throw(
					type="cbElasticsearch.JestClient.IndexCreationException",
					message="Index creation returned an error status of #indexResult.index.status#.  Reason: #( isSimpleValue( indexResult.index.error ) ? indexResult.index.error : indexResult.index.error.reason )#",
					extendedInfo=serializeJSON( indexResult[ "index" ], false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
				);
			}

		} else {

			indexResult[ "index" ] = {
				"error"  : true,
				"message": "Index #indexDSL.name# already exists"
			};

		}

		if( structKeyExists( indexDSL, "mappings" ) ){

			indexResult[ "mappings" ] = applyMappings( indexDSL.name, indexDSL.mappings );

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
		var deleteBuilder = variables.jLoader.create( "io.searchbox.indices.DeleteIndex$Builder" ).init( arguments.indexName );

		return execute( deleteBuilder.build() );
    }

    /**
    * Applies a reindex action
    * @interfaced
    *
    * @source      string   The source index name or struct of options
	* @destination string   The destination index name or struct of options
	* @waitForCompletion boolean whether to return the result or an asynchronous task
	* @params any   Additional url params to add to the reindex action. 
	*               Supports multiple formats : `requests_per_second=50&slices=5`, `{ "requests_per_second" : 50, "slices" : 5 }`, or `[ { "name" : "requests_per_second", "value" : 50 } ]` )
	*
	* @return      any 	Struct result of the reindex action if waiting for completion or a Task object if dispatched asnyc
	**/
	any function reindex(
        required any source,
        required any destination,
		boolean waitForCompletion = true,
		any params,
		any script
    ) {
		if( isMajorVersion( 7 ) && isStruct( arguments.source ) ){
			structDelete( arguments.source, "type" );
		}

		var reindexBuilder = variables.jLoader.create( "io.searchbox.indices.reindex.Reindex$Builder" )
		.init(
			generateIndexMap( arguments.source ),
			generateIndexMap( arguments.destination )
		)
		.waitForCompletion( arguments.waitForCompletion );

		if( structKeyExists( arguments, "params" ) ){
			parseParams( arguments.params ).each( function( param ){
				reindexBuilder.setParameter( param.name, param.value );
			} );
		}
		
		if( structKeyExists( arguments, "script" ) ){
			if( isSimpleValue( arguments.script ) ){
				reindexBuilder.script( { "lang" : "painless", "source" : arguments.script } );
			} else {
				reindexBuilder.script( arguments.script );
			}
		}

		var reindexResult =  execute( reindexBuilder.build() );
		if( arguments.waitForCompletion || !structKeyExists( reindexResult, "task" ) ){
			return reindexResult;
		} else {
			return getTask( reindexResult.task );
		}
    }

    private any function generateIndexMap( required any index ) {
        if ( isSimpleValue( arguments.index ) ) {
            return variables.jLoader
                .create( "com.google.common.collect.ImmutableMap" )
                .of( "index", arguments.index );
        }

        if ( ! isStruct( arguments.index ) ) {
            throw( "Invalid type. Pass either a string or a struct of options." );
        }

        return structReduce( arguments.index, function( indexMap, key, value ) {
            if ( key == "query" ) {
                value = serializeJSON( value );
            }
            indexMap.put( key, value );
            return indexMap;
        }, util.newHashMap() );
	}

	/**
	 * Returns a struct containing all indices in the system, with statistics
	 * 
	 * @verbose 	boolean 	whether to return the full stats output for the index
	 */
	struct function getIndices( verbose = false ){
		// we can access all of our indices from the status
		var statsBuilder = variables.jLoader.create( "io.searchbox.indices.Stats$Builder" );
		statsBuilder.refresh( javacast("boolean", true ) )
					.store( javacast( "boolean", true ) )
					.docs( javacast( "boolean", true ) );

		if( arguments.verbose ){

			statsBuilder.fielddata( javacast( 'boolean', true ) )
						.indexing( javacast( "boolean", true ) );
		}

		var statsResult = execute( statsBuilder.build() );

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
		var getBuilder = variables.jLoader.create( "io.searchbox.indices.aliases.GetAliases$Builder" );
		var aliasesResult = execute( getBuilder.build() );

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
        var modifyAliasesBuilder = "";
        for ( var alias in arguments.aliases ) {
            var aliasBuilder = "";
            switch( alias.getAction() ) {
                case "add":
                    aliasBuilder = variables.jLoader
                        .create( "io.searchbox.indices.aliases.AddAliasMapping$Builder" )
                        .init( alias.getIndexName(), alias.getAliasName() )
                        .build();
                    break;
                case "remove":
                    aliasBuilder = variables.jLoader
                        .create( "io.searchbox.indices.aliases.RemoveAliasMapping$Builder" )
                        .init( alias.getIndexName(), alias.getAliasName() )
                        .build();
                    break;
                default:
                    throw( "Unsupported alias action.  Allowed actions are: add, remove" );
            }

            if ( isSimpleValue( modifyAliasesBuilder ) ) {
                modifyAliasesBuilder = variables.jLoader
                    .create( "io.searchbox.indices.aliases.ModifyAliases$Builder" )
                    .init( aliasBuilder );
            } else {
                modifyAliasesBuilder.addAlias( aliasBuilder );
            }
        }

        return execute( modifyAliasesBuilder.build() ).acknowledged;
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

		var putBuilder = variables.jLoader.create( "io.searchbox.indices.mapping.PutMapping$Builder" ).init(
				arguments.indexName,
				isMajorVersion( 7 ) ? javacast( "null", 0 ) : arguments.mappingName,
				JSONMapping
			);

		var mappingResult = execute( putBuilder.build() );

		if( structKeyExists( mappingResult, "error" ) ){

			throw(
				type="cbElasticsearch.JestClient.IndexMappingException",
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
	* Deletes a mapping
	*
	* @indexName 		string 		the name of the index which contains the mapping
	* @mapping 			string 		the mapping ( e.g. type ) to delete
	* @throwOnError 	boolean	  	Whether to throw an error if the mapping could not be deleted ( default=false )
	*
	* @return 			struct 		the deletion transaction response
	**/
	boolean function deleteMapping( required string indexName, required string mapping, boolean throwOnError=false ){

		var deleteBuilder = variables.jLoader.create( "io.searchbox.indices.mapping.DeleteMapping$Builder" ).init( arguments.indexName, arguments.mapping );

		var deleteResult = execute( deleteBuilder.build() );

		if( arguments.throwOnError && structKeyExists( deleteResult, "error" ) ){
			throw(
				type="cbElasticsearch.JestClient.MappingPersistenceException",
				message="The mapping for #mapKey# could not be deleted.  Reason: #( isSimpleValue( deleteResult.error ) ? deleteResult.error : deleteResult.error.reason )#",
				extendedInfo=serializeJSON( deleteResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		return true;

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

		var actionBuilder = variables.jLoader.create( "io.searchbox.core.Get$Builder" )
												.init(
													arguments.index,
													javacast( "string", encodeForUrl( canonicalize( arguments.id, false, false ) ) )
												);

		if(  !isNull( arguments.type ) && !isMajorVersion( 7 ) ){
			actionBuilder.type( arguments.type );
		}

		var retrievedResult = execute( actionBuilder.build() );

		if( structKeyExists( retrievedResult, "error" ) || !retrievedResult.found ){

			return;

		} else {

			var document = newDocument()
								.setId( arguments.id )
								.setIndex( arguments.index )
								.populate( util.ensureNativeStruct( retrievedResult[ "_source" ] ) );

			if( !isNull( arguments.type ) ){
				document.setType( arguments.type );
			}

			return document;
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
		
		if( isMajorVersion( 7 ) ){
			arguments.type = '_doc';
		}

		var actionBuilder = variables.jLoader.create( "io.searchbox.core.MultiGet$Builder$ById" )
												.init(
													arguments.index,
													!isNull( arguments.type ) ? arguments.type : '_doc'
												);
		for( var key in arguments.keys ){
			actionBuilder.addId( javacast( "string", encodeForUrl( canonicalize( key, false, false ) ) ) );
		}

		var retrievedResult = execute( actionBuilder.build() );

		if( !structKeyExists( retrievedResult, "docs" ) ){

			return [];

		} else {

			var documents = [];

			for( var result in retrievedResult.docs ){

				if( !structKeyExists( result, "_source" ) ) continue;

				var document = newDocument().new(
					result[ "_index" ],
					result[ "_type" ],
					util.ensureNativeStruct( result[ "_source" ] )
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
	any function getTask( required string taskId, Task taskObj=newTask() ){
		var taskResult = execute(
			variables.jLoader.create( "io.searchbox.cluster.TasksInformation$Builder" )
								.init()
								.task( arguments.taskId )
								.build()
		);

		if( !structKeyExists( taskResult, "task" ) ){
			throw(
				type="cbElasticsearch.JestClient.InvalidTaskException",
				message="A task with an identifier of #arguments.taskId# could not be found. The error returned was: #( isSimpleValue( taskResult.error ) ? taskResult.error : taskResult.error.reason )#",
				extendedInfo=serializeJSON( taskResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		return taskObj.populate( taskResult );

	}

	/**
	 * Retreives all tasks running on the cluster
	 * 
	 * @interfaced
	 */
	any function getTasks(){
		
		var taskObj = execute(
			variables.jLoader.create( "io.searchbox.cluster.TasksInformation$Builder" )
								.init()
								.setParameter( "detailed", javacast( "boolean", true ) )
								.build()
		);
		var tasks = [];
		taskObj.nodes.keyArray().each( function( node ){
			var nodeObj = taskObj.nodes[ node ];
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
	Document function save( required Document document ){
		var updateAction = buildUpdateAction( arguments.document );
		
		var saveResult = execute( updateAction );

		if( structKeyExists( saveResult, "error" ) ){

			throw(
				type="cbElasticsearch.JestClient.PersistenceException",
				message="Document could not be saved.  The error returned was: #( isSimpleValue( saveResult.error ) ? saveResult.error : saveResult.error.reason )#",
				extendedInfo=serializeJSON( saveResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		arguments.document.setId( saveResult[ "_id" ] );

		return arguments.document;

	}

	/**
	* Deletes a single document
	* @document 		Document 		the Document object for the document to be deleted
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	**/
	boolean function delete( required any document, boolean throwOnError=true ){

		var deleteResult = execute( buildDeleteAction( arguments.document ) );

		if( arguments.throwOnError && structKeyExists( deleteResult, "error" ) ){
			throw(
				type="cbElasticsearch.JestClient.PersistenceException",
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
	any function deleteByQuery( required SearchBuilder searchBuilder, boolean waitForCompletion = true ){

		if( isNull( arguments.searchBuilder.getIndex() ) ){
			throw(
				type="cbElasticsearch.JestClient.DeleteBuilderException",
				message="deleteByQuery() could not be executed because an index was not assigned in the provided SearchBuilder object."
			);
		}

		var deleteBuilder = variables.jLoader
										.create( "io.searchbox.core.DeleteByQuery$Builder" )
										.init(
											serializeJSON( {
												"query" : arguments.searchBuilder.getQuery()
											},
											false,
											listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
										);

		deleteBuilder.addIndex( arguments.searchBuilder.getIndex() );

		if( !isNull( arguments.searchBuilder.getType() ) ){
			if( isMajorVersion( 7 ) ){
				arguments.searchBuilder.term( "_type", arguments.searchbuilder.getType() );
			} else {
				deleteBuilder.addtype( arguments.searchBuilder.getType() );
			}
		}

		parseParams( arguments.searchBuilder.getParams() ).each( function( param ){
			deleteBuilder.setParameter( param.name, param.value );
			if( param.name == 'wait_for_completion' ){
				arguments.waitForCompletion = param.value;
			}
		} );

		if( !arguments.waitForCompletion ){
			deleteBuilder.setParameter( "wait_for_completion", false );
		}

		var deletionResult =  execute( deleteBuilder.build() );
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
	any function updateByQuery( required SearchBuilder searchBuilder, required struct script, boolean waitForCompletion = true ){

		if( isNull( arguments.searchBuilder.getIndex() ) ){
			throw(
				type="cbElasticsearch.JestClient.UpdateBuilderException",
				message="updateByQuery() could not be executed because an index was not assigned in the provided SearchBuilder object."
			);
		}

		var updateBuilder = variables.jLoader
										.create( "io.searchbox.core.UpdateByQuery$Builder" )
										.init(
											serializeJSON( {
												"query" : arguments.searchBuilder.getQuery(),
												"script": arguments.script
											},
											false,
											listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
										);

		updateBuilder.addIndex( arguments.searchBuilder.getIndex() );

		if( !isNull( arguments.searchBuilder.getType() ) ){
			if( isMajorVersion( 7 ) ){
				arguments.searchBuilder.term( "_type", arguments.searchBuilder.getType() );
			} else {
				updateBuilder.addtype( arguments.searchBuilder.getType() );
			}	
		}

		parseParams( arguments.searchBuilder.getParams() ).each( function( param ){
			updateBuilder.setParameter( param.name, param.value );
			if( param.name == 'wait_for_completion' ){
				arguments.waitForCompletion = param.value;
			}
		} );

		if( !arguments.waitForCompletion ){
			updateBuilder.setParameter( "wait_for_completion", false );
		}


		var updateResult =  execute( updateBuilder.build() );
		if( arguments.waitForCompletion ){
			return updateResult;
		} else {
			return getTask( updateResult.task );
		}

	}

	private any function buildDeleteAction( required Document document ){

		if( isNull( arguments.document.getId() ) ){
			throw(
				type="cbElasticsearch.JestClient.DeleteBuilderException",
				message="Document could not be deleted because an _id value was not available in the provided Document object",
				extendedInfo=document.toString()
			);
		}

        var deleteBuilder = variables.jLoader.create( "io.searchbox.core.Delete$Builder" )
            .init( javacast( "string", encodeForUrl( canonicalize( arguments.document.getId(), false, false ) ) ) );

		deleteBuilder.index( arguments.document.getIndex() );

		if( !isNull( arguments.document.getType() ) ){
			if( isMajorVersion( 7 ) ){
				deleteBuilder.type( "_doc" );
			} else {
				deleteBuilder.type( arguments.document.getType() );
			}
		}

		return deleteBuilder.build();
	}

	private any function buildUpdateAction( required Document document ){

		var builder = variables.jLoader
									.create( "io.searchbox.core.Index$Builder" )
									.init( util.newHashMap( arguments.document.getMemento() ) );

		builder.index( arguments.document.getIndex() );

		if( isMajorVersion( 7 ) ){
			builder.type( "_doc" );
		}

		if( !isNull( arguments.document.getType() ) ){
			if( isMajorVersion( 7 ) ){
				document.getMemento()[ "_type" ] = arguments.document.getType();
			} else {
				builder.type( arguments.document.getType() );
			}
		}

		//Specify the document ID if it is provided in our payload
		if( !isNull( arguments.document.getId() ) ){
			//ensure our `_id` is always cast as a string
			builder.id( javacast("string", encodeForUrl( canonicalize( arguments.document.getId(), false, false ) ) ) );
		}

		return builder.build();
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

		var bulkBuilder = variables.jLoader.create( "io.searchbox.core.Bulk$Builder" ).init();

		for( var document in arguments.documents ){

			var updateAction = buildUpdateAction( document );

			bulkBuilder.addAction( updateAction );
		}

		var saveResult = execute( bulkBuilder.build() );

		if( structKeyExists( saveResult, "error" ) ){
			throw(
				type="cbElasticsearch.JestClient.PersistenceException",
				message="Document could not be saved.  The error returned was: #( isSimpleValue( saveResult.error ) ? saveResult.error : saveResult.error.reason )#",
				extendedInfo=serializeJSON( saveResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		var results = [];

		for( var item in saveResult.items ){

			if( arguments.throwOnError && item.index.keyExists( "error" ) ){
				throw(
					type="cbElasticsearch.JestClient.PersistenceException",
					message="A document with an identifier of #item.index[ "_id" ]# could not be saved.  The error returned was: #( isSimpleValue( item.index.error ) ? item.index.error : item.index.error.reason )#",
					extendedInfo=serializeJSON( saveResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
				);
			}
			arrayAppend(
				results,
				{
					"_id"    : item.index[ "_id" ],
					"result" : item.index.keyExists( "result" ) ? item.index.result : javacast( "null", 0 ),
					"error" : item.index.keyExists( "error" ) ? item.index.error : javacast( "null", 0 )
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

		var bulkBuilder = variables.jLoader.create( "io.searchbox.core.Bulk$Builder" ).init();

		for( var doc in arguments.documents ){

			var deleteAction = buildDeleteAction( doc );

			bulkBuilder.addAction( deleteAction );
		}

		var deleteResult = execute( buildBuilder.build() );

		if( arguments.throwOnError && structKeyExists( deleteResult, "error" ) ){

			throw(
				type="cbElasticsearch.JestClient.PersistenceException",
				message="Document could not be deleted.  The error returned was: #( isSimpleValue( deleteResult.error ) ? deleteResult.error : deleteResult.error.reason )#",
				extendedInfo=serializeJSON( deleteResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		return true;



	}

	/**
	* Executes an HTTP client transaction
	* @action 			any			A valid Jest client action
	* @returnObject 	boolean 	Whether to return the JestResult, default to false, which returns a struct
	*
	* @returns  any 	A CFML representation of the result.  If `returnObject` is flagged, will return the client JestResult
	**/
	public any function execute( required any action, returnObject=false ){

		// do a bit of cleanup before the next request
		variables.HTTPClient.getHTTPClient().getConnectionManager().closeExpiredConnections();

		// try catch with a fallback in case our connection has been closed for any reason
		try{
			var JESTResult = variables.HTTPClient.execute( arguments.action );
		} catch( any e ){
			log.error( "An attempt to execute an action on the Elasticsearch server failed. An attempt to reconnect was performed The message received was #e.message#.", e );
			try{
				lock type="exclusive" name="JestClientReConfigurationAttempt" timeout="10"{
					close();
					configure();
				}
				var JESTResult = variables.HTTPClient.execute( arguments.action );
			} catch( any e ){
				log.error( "An attempt to reconnect to the elasticsearch server failed with an error message of #e.message#.", e );
				rethrow;
			}
		}

		if( arguments.returnObject ){
			return JestResult;
		} else {
			return deserializeJSON( JESTResult.getJSONString() );
		}

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
