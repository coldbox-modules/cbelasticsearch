/**
Module Directives as public properties
this.title 				= "Title of the module";
this.author 			= "Author of the module";
this.webURL 			= "Web URL for docs purposes";
this.description 		= "Module description";
this.version 			= "Module Version";
this.viewParentLookup   = (true) [boolean] (Optional) // If true, checks for views in the parent first, then it the module.If false, then modules first, then parent.
this.layoutParentLookup = (true) [boolean] (Optional) // If true, checks for layouts in the parent first, then it the module.If false, then modules first, then parent.
this.entryPoint  		= "" (Optional) // If set, this is the default event (ex:forgebox:manager.index) or default route (/forgebox) the framework
									       will use to create an entry link to the module. Similar to a default event.
this.cfmapping			= "The CF mapping to create";
this.modelNamespace		= "The namespace to use for registered models, if blank it uses the name of the module."
this.dependencies 		= "The array of dependencies for this module"

structures to create for configuration
- parentSettings : struct (will append and override parent)
- settings : struct
- interceptorSettings : struct of the following keys ATM
	- customInterceptionPoints : string list of custom interception points
- interceptors : array
- layoutSettings : struct (will allow to define a defaultLayout for the module)
- routes : array Allowed keys are same as the addRoute() method of the SES interceptor.
- wirebox : The wirebox DSL to load and use

Available objects in variable scope
- controller
- appMapping (application mapping)
- moduleMapping (include,cf path)
- modulePath (absolute path)
- log (A pre-configured logBox logger object for this object)
- binder (The wirebox configuration binder)
- wirebox (The wirebox injector)

Required Methods
- configure() : The method ColdBox calls to configure the module.

Optional Methods
- onLoad() 		: If found, it is fired once the module is fully loaded
- onUnload() 	: If found, it is fired once the module is unloaded

*/
component {

	// Module Properties
	this.title 				= "SecondaryCluster";
	this.author 			= "";
	this.webURL 			= "";
	this.description 		= "";
	this.version			= "1.0.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= false;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = false;
	// Module Entry Point
	this.entryPoint			= "SecondaryCluster";
	// Inherit Entry Point
	this.inheritEntryPoint 	= false;
	// Model Namespace
	this.modelNamespace		= "SecondaryCluster";
	// CF Mapping
	this.cfmapping			= "SecondaryCluster";
	// Auto-map models
	this.autoMapModels		= false;
	// Module Dependencies
	this.dependencies 		= [ "cbElasticsearch" ];

	function configure(){

		// module settings - stored in modules.name.settings
		settings = {
			versionTarget = '7.0.0',
			hosts = [
				//In this example, our secondary is on the same server, different port
				{
					serverProtocol: "http",
					serverName: "elasticsearch-cluster2",
					serverPort: 9200
				}
			],
			// keep these credentials, but leave blank
			defaultCredentials = {
				"username" : "",
				"password" : ""
			},
			defaultIndex           = "otherData",
			// The default number of shards to use when creating an index
			defaultIndexShards     = getSystemSetting( "ELASTICSEARCH_SHARDS", 5 ),
			// The default number of index replicas to create
			defaultIndexReplicas   = getSystemSetting( "ELASTICSEARCH_REPLICAS", 0 ),
			// Whether to use separate threads for client transactions
			multiThreaded          = true,
			// The maximum amount of time to wait until releasing a connection (in seconds)
			maxConnectionIdleTime = 30,
			// The maximum number of connections allowed per route ( e.g. search URI endpoint )
			maxConnectionsPerRoute = 10,
			// The maxium number of connectsion, in total for all Elasticsearch requests
			maxConnections         = getSystemSetting( "ELASTICSEARCH_MAX_CONNECTIONS", 100 ),
			// Read timeout - the read timeout in milliseconds
			readTimeout            = getSystemSetting( "ELASTICSEARCH_READ_TIMEOUT", 3000 ),
			// Connection timeout - timeout attempts to connect to elasticsearch after this timeout
			connectionTimeout      = getSystemSetting( "ELASTICSEARCH_CONNECT_TIMEOUT", 3000 )
		};

	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){

		// map a new singleton instance of the config client
        binder.map( "Config@SecondaryCluster" )
                        .to( 'cbElasticsearch.models.Config' )
                        .threadSafe()
                        .asSingleton();

		var secondaryConfig = wirebox.getInstance( "Config@SecondaryCluster" );

		// override the module-injected config struct to our new configuration
		// note that we need a full config structure passed in as an override to the coldbox settings
		secondaryConfig.setConfigStruct( settings );

		// note that we are using the native JEST client rather than Client@cbElasticsearch
		binder.map( "Client@SecondaryCluster" )
								.to( "cbElasticsearchJest.models.JestClient" )
								.initWith( configuration=secondaryConfig )
								.threadSafe()
								.asSingleton();


	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
		// Close all active pool connections - necessary for native driver implementation
		if( Wirebox.containsInstance( "Client@SecondaryCluster" ) ){

			Wirebox.getInstance( "Client@SecondaryCluster" ).close();

		}
	}

}