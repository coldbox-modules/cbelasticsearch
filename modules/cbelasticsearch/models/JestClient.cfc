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
	/**
	* The HTTP Jest Client
	**/
	property name="HTTPClient";

	/**
	* Config provider
	**/
	Config function getConfig() provider="Config@cbElasticsearch"{}

	/**
	* Document provider
	**/
	Document function newDocument() provider="Document@cbElasticsearch"{}

	/**
	* SearchResult provider
	**/
	SearchResult function newResult() provider="SearchResult@cbElasticsearch"{}

	/**
	* Configure instance once DI is complete
	**/
	any function onDIComplete(){

		configure();

	}

	void function configure(){

		var configSettings = getConfig().getConfigStruct();

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
			var types = listToArray( arguments.searchBuilder.getType() );
			for( var type in types ){
				jSearchBuilder.addType( type );
			}
		}

		var searchResult = execute( jSearchBuilder.build() );

		return newResult().new( searchResult );

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
		getBuilder.addType( arguments.mapping );

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
				var settingsMap = variables.jLoader.create( "java.util.HashMap" ).init();

				settingsMap.putAll( indexDSL.settings );

				builder.settings( settingsMap );
			}

			indexResult[ "index" ] = execute( builder.build() );

			if( structKeyExists( indexResult[ "index" ], "error" ) ){
				throw(
					type="cbElasticsearch.JestClient.IndexCreationException",
					message="Index creation returned an error status of #indexResult.index.status#.  Reason: #indexResult.index.error.reason#",
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
	* Applies a single mapping to an index
	* @indexName 				string 		the name of the index
	* @mappingName	 			string 		the name of the mapping
	* @mappingConfig 			struct 		the mapping configuration struct
	* @interfaced
	**/
	struct function applyMapping( required string indexName, required string mappingName, required struct mappingConfig ){

		var putBuilder = variables.jLoader.create( "io.searchbox.indices.mapping.PutMapping$Builder" ).init(
				arguments.indexName,
				arguments.mappingName,
				serializeJSON(
					{
						"#arguments.mappingName#":arguments.mappingConfig
					},
					false,
					listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
				)
			);

		var mappingResult = execute( putBuilder.build() );

		if( structKeyExists( mappingResult, "error" ) ){

			throw(
				type="cbElasticsearch.JestClient.IndexMappingException",
				message="The mapping for #arguments.mappingName# could not be created.  Reason: #mappingResult.error.reason#",
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
				message="The mapping for #mapKey# could not be deleted.  Reason: #deleteResult.error.reason#",
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
			arguments.index = getConfig().get( "defaultIndex" );
		}

		var actionBuilder = variables.jLoader.create( "io.searchbox.core.Get$Builder" )
												.init(
													arguments.index,
													javacast( "string", encodeForUrl( canonicalize( arguments.id, false, false ) ) )
												);

		if( !isNull( arguments.type ) ){
			actionBuilder.type( arguments.type );
		}

		var retrievedResult = execute( actionBuilder.build() );

		if( structKeyExists( retrievedResult, "error" ) || !retrievedResult.found ){

			return;

		} else {

			var document = newDocument()
								.setId( arguments.id )
								.setIndex( arguments.index )
								.populate( retrievedResult[ "_source" ] );

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
			arguments.index = getConfig().get( "defaultIndex" );
		}

		var actionBuilder = variables.jLoader.create( "io.searchbox.core.MultiGet$Builder$ById" )
												.init(
													arguments.index,
													!isNull( arguments.type ) ? arguments.type : 'default'
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
					result[ "_source" ]
				).setId( result[ "_id" ] );

				arrayAppend( documents, document );

			}

			return documents;
		}
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
				message="Document could not be saved.  The error returned was: #saveResult.error.reason#",
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
				message="Document could not be deleted.  The error returned was: #deleteResult.error.reason#",
				extendedInfo=serializeJSON( deleteResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		return true;
	}

	/**
	* Deletes items in the index by query
	* @searchBuilder 		SearchBuilder 		The search builder object to use for the query
	**/
	boolean function deleteByQuery( required SearchBuilder searchBuilder ){

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
			deleteBuilder.addtype( arguments.searchBuilder.getType() );
		}

		var deletionResult = execute( deleteBuilder.build() );


		return javacast( "boolean", structKeyExists( deletionResult, "deleted" ) ? deletionResult.deleted : 0 );

	}

	/**
	* Updates items in the index by query
	* @searchBuilder 		SearchBuilder 		The search builder object to use for the query
	* @script 				struct 				script to process on the query
	**/
	boolean function updateByQuery( required SearchBuilder searchBuilder, required struct script ){

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
			updateBuilder.addtype( arguments.searchBuilder.getType() );
		}

		var updateResult = execute( updateBuilder.build() );

		return javacast( "boolean", structKeyExists( updateResult, "updated" ) ? updateResult.updated : 0 );

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
			deleteBuilder.type( arguments.document.getType() );
		}

		return deleteBuilder.build();
	}

	private any function buildUpdateAction( required Document document ){

		var source = variables.jLoader.create( "java.util.LinkedHashMap" ).init();
		source.putAll( arguments.document.getMemento() );

		var builder = variables.jLoader
									.create( "io.searchbox.core.Index$Builder" )
									.init( source );

		builder.index( arguments.document.getIndex() );

		if( !isNull( arguments.document.getType() ) ){

			builder.type( arguments.document.getType() );
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
	*
	* @return 			array					An array of results for the saved items
	* @interfaced
	**/
	array function saveAll( required array documents ){

		var bulkBuilder = variables.jLoader.create( "io.searchbox.core.Bulk$Builder" ).init();

		for( var document in arguments.documents ){

			var updateAction = buildUpdateAction( document );

			bulkBuilder.addAction( updateAction );
		}

		var saveResult = execute( bulkBuilder.build() );

		if( structKeyExists( saveResult, "error" ) ){
			throw(
				type="cbElasticsearch.JestClient.PersistenceException",
				message="Document could not be saved.  The error returned was: #saveResult.error.reason#",
				extendedInfo=serializeJSON( saveResult, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false )
			);
		}

		var results = [];

		for( var item in saveResult.items ){
			arrayAppend(
				results,
				{
					"_id"    : item.index[ "_id" ],
					"result" : item.index.result
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
				message="Document could not be deleted.  The error returned was: #deleteResult.error.reason#",
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
	private any function execute( required any action, returnObject=false ){

		var JESTResult = variables.HTTPClient.execute( arguments.action );

		if( arguments.returnObject ){
			return JestResult;
		} else {
			return deserializeJSON( JESTResult.getJSONString() );
		}

	}


}
