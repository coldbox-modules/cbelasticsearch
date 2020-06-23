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
    this.version			= "0.2.0+38";
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
    // Auto-parse parent settings
    this.parseParentSettings = true;

    variables.configStruct = {};


    function configure(){

        // Default settings
        settings = {
            //The native client Wirebox DSL for the transport client
            client="HyperClient@cbElasticsearch",
            // The default hosts - an array of host connections
            //  - REST-based clients (e.g. JEST):  round robin connections will be used
            //  - Socket-based clients (e.g. Transport):  cluster-aware routing used
            versionTarget = getSystemSetting( "ELASTICSEARCH_VERSION", '' ),
            hosts = [
                //The default connection is made to http://127.0.0.1:9200
                {
                    serverProtocol: getSystemSetting( "ELASTICSEARCH_PROTOCOL", "http" ),
                    serverName: getSystemSetting( "ELASTICSEARCH_HOST", "127.0.0.1" ),
                    serverPort: getSystemSetting( "ELASTICSEARCH_PORT", 9200 )
                }
            ],
            // The default credentials for access, if any - may also be overridden when searching index collections
            defaultCredentials = {
                "username" : getSystemSetting( "ELASTICSEARCH_USERNAME", "" ),
                "password" : getSystemSetting( "ELASTICSEARCH_PASSWORD", "" )
            },
            // The default index
            defaultIndex           = getSystemSetting( "ELASTICSEARCH_INDEX", "cbElasticsearch" ),
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
            // The maxium number of connections, in total for all Elasticsearch requests
            maxConnections         = getSystemSetting( "ELASTICSEARCH_MAX_CONNECTIONS", 100 ),
            // Read timeout - the read timeout in milliseconds
            readTimeout            = getSystemSetting( "ELASTICSEARCH_READ_TIMEOUT", 3000 ),
            // Connection timeout - timeout attempts to connect to elasticsearch after this timeout
            connectionTimeout      = getSystemSetting( "ELASTICSEARCH_CONNECT_TIMEOUT", 3000 )
        };

        // Custom Declared Points
        interceptorSettings = {
            customInterceptionPoints = ""
        };

        // Custom Declared Interceptors
        interceptors = [];

    }

    /**
    * Fired when the module is registered and activated.
    */
    function onLoad(){
        /**
        * Main Configuration Object Singleton
        **/

        binder.map( "Config@cbElasticsearch" )
                        .to( '#moduleMapping#.models.Config' )
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

}
