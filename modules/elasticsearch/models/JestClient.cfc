component 
	implements="iNativeClient" 
	accessors=true
	singleton
{

	property name="configObject" inject="Config@cbElasticsearch";
	property name="jLoader" inject="loader@cbjavaloader";
	/**
	* The HTTP Jest Client
	**/
	property name="HTTPClient";
	
	
	/**
	* Configure instance once DI is complete
	**/
	any function onDIComplete(){

		configure();

	}

	function configure(){

		var configSettings = variables.configObject.getConfigStruct();

		var hostConnections = jLoader.create( "java.util.ArrayList" ).init();

		for( var host in configSettings.hosts ){
			arrayAppend( hostConnections, host.serverProtocol & "://" & host.serverName & ":" & host.serverPort );	
		}

		var configBuilder = variables.jLoader
										.create( "io.searchbox.client.config.HttpClientConfig$Builder" )
										.init( hostConnections )
										.multiThreaded( javacast( "boolean", configSettings.multiThreaded ) )
										.defaultMaxTotalConnectionPerRoute( configSettings.maxConnectionsPerRoute )
										.maxTotalConnection( configSettings.maxConnections );

		var factory = variables.jLoader.create( "io.searchbox.client.JestClientFactory" ).init();

		factory.setHttpClientConfig( configBuilder.build() );
		
		variables.HTTPClient = factory.getObject();

	}

	/**
	* Executes an HTTP client transaction
	* @action 	any		A valid Jest client action
	* @returns  any 	A CFML representation of the result
	**/
	any function execute( required any action ){
		
		return deserializeJSON( variables.HTTPClient.execute( arguments.action ).getJSONString() );

	}

	/**
	* Closes any connections to an active pool - not necessary, since Jest is REST-based client
	* @interfaced
	**/
	void function close(){
		return;
	}

	/**
	* Applies an index item
	* @indexBuilder 	IndexBuilder 	An instance of the IndexBuilder object
	* 
	* @return 			iNativeClient 	An implementation of the iNativeClient
	* @interfaced
	**/
	iNativeClient function applyIndex( required IndexBuilder indexBuilder ){

	}

	/**
	* Retrieves a document by ID
	* @id 		any 		The document key
	* @index 	string 		The name of the index
	* @type 	type 		The name of the type
	* @interfaced
	**/
	Document function get( 
		required any id,
		string index,
		string type
	){
		if( isNull( arguments.index ) ){
			arguments.index = variables.configObject.get( "defaultIndex" );
		}

		var actionBuilder = variables.jLoader.create( "io.searchbox.core.Get$Builder" ).init( arguments.index, javacast( "string", arguments.id ) );
		
		if( !isNull( arguments.type ) ){
			actionBuilder.type( arguments.type );
		}

		return execute( actionBuilder.build() );

	}

	/**
	* @document 		Document@cbElasticSearch 		An instance of the elasticsearch Document object
	* 
	* @return 			iNativeClient 					An implementation of the iNativeClient
	* @interfaced
	**/
	iNativeClient function save( required Document document ){

		var updateAction = buildUpdateAction( arguments.document );

		variables.HTTPClient.execute( updateAction );	


	}

	private any function buildUpdateAction( required Document document ){
		var updateBuilder = variables.jLoader
										.create( "io.searchbox.core.Update$Builder" )
										.init( arguments.document.toString() );
		updateBuilder
			.index( arguments.document.getIndex() )
			.type( arguments.document.getType() );

		//Specify the document ID if it is provided in our payload
		if( isNull( arguments.document.getId() ) ){
			updateBuilder.id( arguments.document.getId() );
		}

		return updateBuilder.build();	
	} 

	/**
	* Persists multiple items to the index
	* @documents 		array 					An array of elasticsearch Document objects to persist
	* 
	* @return 			iNativeClient 			An implementation of the iNativeClient
	* @interfaced
	**/
	iNativeClient function saveAll( required array documents ){

		var bulkBuilder = variables.jLoader.create( "io.searchbox.core.Bulk$Builder" ).init();

		for( var document in arguments.documents ){
			
			var updateAction = buildUpdateAction( document );

			bulkBuilder.addAction( updateAction );
		}

		return execute( bulkBuilder.build() );
	}

	/**
	* Execute a client search request
	* @searchBuilder 	SearchBuilder 	An instance of the SearchBuilder object
	* 
	* @return 			iNativeClient 	An implementation of the iNativeClient
	* @interfaced
	**/
	any function executeSearch( required searchBuilder searchBuilder ){

		var searchBuilder = variables.jLoader.create( "io.searchbox.core.Search$Builder" ).init( arguments.searchBuilder.getJSON() );

		return execute( searchBuilder.build() );

	}


	/**
	* Converts common Jest objects ( e.g. reponses  ) in to native CFML types
	* @obj 		any 		The object to convert
	* @interfaced
	**/
	any function toCFML( required any obj ){
		
		if( isNull( arguments.obj ) ) return;
		
		//if we're in a loop iteration and the array item is simple, return it
		if( isSimpleValue( arguments.obj ) ) return BasicDbObject;

		if( isArray( arguments.obj ) ){

			var cfObj = [];

			for( var item in arguments.obj ){
				arrayAppend( cfObj, toCFML( item ) );
			}

		} else {
			var cfObj = {};

			try{

				cfObj.putAll( arguments.obj );

			} catch( any e ){
				
				if(getMetaData(arguments.obj).getName() == 'org.bson.BsonUndefined') return javacast("null", "");

				return arguments.obj;
			}

			//loop our keys to ensure first-level items with sub-documents objects are converted
			for(var key in cfObj){

				if( 
					!isNull( cfObj[ key ] ) 
					&& 
					( 
						isArray( cfObj[ key ] ) 
						|| 
						isStruct( cfObj[ key ] ) 
					) 
				){
					cfObj[ key ] = toCF( cfObj[ key ] );
				}
			
			}
		} 

		return cfObj;
	}


}