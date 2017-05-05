/**
*********************************************************************************
* Your Copyright
********************************************************************************
*/
component{

	// Module Properties
	this.title 				= "cbElasticSearch";
	this.author 			= "Jon Clausen <jclausen@ortussolutions.com>";
	this.webURL 			= "";
	this.description 		= "Coldbox Module with Fluent API for ElasticSearch";
	this.version			= "@build.version@+@build.number@";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "cbElasticsearch";
	// Model Namespace
	this.modelNamespace		= "cbElasticsearch";
	// CF Mapping
	this.cfmapping			= "cbElasticsearch";
	// Auto-map models
	this.autoMapModels		= true;
	// Module Dependencies That Must Be Loaded First, use internal names or aliases
	this.dependencies		= [ "cbjavaloader" ];
	
	variables.configStruct = {};

	function configure(){

		// Java Loader Settings
		settings = {

		};

		// Custom Declared Points
		interceptorSettings = {
			customInterceptionPoints = ""
		};

		// Custom Declared Interceptors
		interceptors = [
		];

	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		//Retrieve our module settings
		parseParentSettings();
		
		// load DB jars
		wirebox.getInstance( "loader@cbjavaloader" ).appendPaths( variables.modulePath & "/lib");
		
		/**
		* Main Configuration Object Singleton
		**/

		binder.map("Config@cbElasticsearch")
			.to( '#moduleMapping#.models.Config' )
			.initWith( configStruct=variables.configStruct )
			.threadSafe()
			.asSingleton();

	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){

		// Close all active pool connections - necessary for native driver implementation
		if( Wirebox.containsInstance( "Client@cbElasticsearch" ) ){

			Wirebox.getInstance( "Client@cbElasticsearch" ).close();		
		
		}

	}

	/**
	* Prepare settings for DB Connections.
	*/
	private function parseParentSettings(){
		var oConfig 			= controller.getSetting( "ColdBoxConfig" );
		var configSettings 		= {};
		var esSettings			= oConfig.getPropertyMixin( "elasticsearch", "variables", {} );

		//check if a config has been misplaced within the custom settings structure
		if( structIsEmpty( esSettings ) and structKeyExists( configSettings, "elasticsearch" ) ){
			esSettings = duplicate( configSettings.elasticsearch );
		}		
			
		//default config struct
		configSettings = {
			//The native client DSL
			client="JestClient@cbElasticsearch",
			//The default hosts
			hosts = [
				{
					serverProtocol:'http',
					serverName:'127.0.0.1',
					serverPort:'9200'
				}
			],
			//The default index
			defaultIndex = "cbElasticsearch",
			defaultIndexShards = 3,
			defaultIndexReplicas = 2,
			multiThreaded = true,
			maxConnectionsPerRoute = 5,
			maxConnections = 10
		};

		// Incorporate settings
		structAppend( configSettings, esSettings, true );

		variables.configStruct = configSettings;

	}

}
