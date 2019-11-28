Configuration
=============

Once you have installed the module, you may add a custom configuration, specific to your environment, by adding an `cbElasticsearch` configuration object to your `moduleSettings` inside your `Coldbox.cfc` configuration file.

By default the following are in place, without additional configuration:

```
moduleSettings = {
    "cbElasticsearch" = {
        // The native client Wirebox DSL for the transport client
        client = "JestClient@cbElasticsearch",
        // The default hosts - an array of host connections
        //  - REST-based clients (e.g. JEST):  round robin connections will be used
        //  - Socket-based clients (e.g. Transport):  cluster-aware routing used
        hosts = [
            // The default connection is made to http://127.0.0.1:9200
            {
                serverProtocol = "http",
                serverName = "127.0.0.1",
                // Socket-based connections will use 9300
                serverPort = "9200"
            }
        ],
        // The default index
        defaultIndex = "cbElasticsearch",
        // The default number of shards to use when creating an index
        defaultIndexShards = 3,
        // The default number of index replicas to create
        defaultIndexReplicas = 0,
        // Whether to use separate threads for client transactions
        multiThreaded = true,
        // The maximum number of connections allowed per route ( e.g. search URI endpoint )
        maxConnectionsPerRoute = 10,
        // The maxium number of connectsion, in total for all Elasticsearch requests
        maxConnections = 100
    }
};
```

At the current time only the REST-based [JEST] native client is available. Support is in development for a socket based-client.  For most applications, however the REST-based native client will be a good fit.

## Connection to secondary Elasticsearch Clusters

As of the current version, the module conventions only allow for a default connection to one cluster.  Multi-cluster native configuration is planned for a future major release, as it will be a breaking change.  You may, however, create a separate instance of the client to connect to a different cluster.  Since this needs to be accomplished after the module is loaded, the easiest way to do this is to create an application-specific module which is dedicated to connecting to that cluster.  A major caveat, at this time, however is that native CRUD methods in the `Document`, `SearchBuilder`, `IndexBuilder`, and `ElasticsearchAppender` components will not work, as they are hard-wired to connect to the main client.  As such, execution will need to be performed through the separate client instance.  If you wish to use the secondary cluster for logging, a new Appender will also need to be created.

Below is an example of creating a secondary client connection to an alternate cluster.

1. First create a new application module

```
box coldbox create module name=SecondaryCluster directory=modules_app dependencies=cbElasticsearch
```
_Note: the above command will also create `views`, `models` and `handlers` directories. These can be removed as they will not be used._

2. Once your module is created, open up the `ModuleConfig.cfc` and add `cbElasticsearch` to `this.dependencies`

3. Now change the `settings` object in the `configure()` method to use your new configuration. Note that we have omitted the `client` key.  We do this in order to prevent usage of member functions in the internal objects, by ensuring an error is thrown if we attempt to invoke them. All transactions need to pass through the client. 

```
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
```

4. Now that we have our settings in place, add our new bindings to the internals `onLoad` method

```
// map a new singleton instance of the config client
binder.map( "Config@SecondaryCluster" )
                .to( 'cbelasticsearch.models.Config' )
                .threadSafe()
                .asSingleton();

var secondaryConfig = wirebox.getInstance( "Config@SecondaryCluster" );

// override the module-injected config struct to our new configuration
// note that we need a full config structure passed in as an override to the coldbox settings
secondaryConfig.setConfigStruct( settings );

// note that we are using the native JEST client rather than Client@cbElasticsearch
binder.map( "Client@SecondaryCluster" )
                        .to( "cbElasticsearch.models.JestClient" )
                        .initWith( configuration=secondaryConfig )
                        .threadSafe()
                        .asSingleton();

```

5. After you have created your bindings, make sure you add a closing routine in your `onUnload` method for the client when the module is unloaded ( e.g. during a framework reinit ):

```
// Close all active pool connections - necessary for native driver implementation
if( wirebox.containsInstance( "Client@SecondaryCluster" ) ){
    wirebox.getInstance( "Client@SecondaryCluster" ).close();
}
```

Now you may perform a search, considering the caveat that the search must now be executed through the client:

```
var searchBuilder = getInstance( "SearchBuilder@cbElasticsearch" ).new( "myOtherIndex" );
searchBuilder.term( "foo", "bar" );

var searchResult = getInstance( "Client@SecondaryCluster" ).executeSearch( searchBuilder );
```

Document saves, retreivals, and deletions would need to be routed through the client, as well, rather than using the `save()` function:

```
var newDocument = getInstance( "Document@cbElasticsearch" ).new( { "id" : createUUID(), "foo" : "bar" } );
getInstance( "Client@SecondaryCluster" ).save( newDocument );


var existingDocument = getInstance( "Client@SecondaryCluster" ).get( newDocument.getId() );
getInstance( "Client@SecondaryCluster" ).delete( existingDocument );
```

As you can see, connecting to a secondary Elasticsearch cluster, while not as fluent, is workable.  Version 2.0 of this module has multi-cluster support planned via the native configuration.


## Tests

To run the test suite you need a running instance of ElasticSearch.  We have provided a `docker-compose.yml` file in
the root of the repo to make this easy as possible.  Run `docker-compose up --build` ( omit the `--build` after the first startup ) in the root of the project and open
`http://localhost:8080/tests/runner.cfm` to run the tests.

If you would prefer to set this up yourself, make sure you start this app with the correct environment variables set:

```ini
ELASTICSEARCH_PROTOCOL=http
ELASTICSEARCH_HOST=127.0.0.1
ELASTICSEARCH_PORT=9200
```
