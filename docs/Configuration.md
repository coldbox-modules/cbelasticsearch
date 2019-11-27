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
