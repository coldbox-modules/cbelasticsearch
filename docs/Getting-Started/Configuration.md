---
description: Learn CBElasticsearch module config, environment variable support, and more.
---

# Configuration

Once you have installed the module, you may add a custom configuration, specific to your environment, by adding an `cbElasticsearch` configuration object to your `moduleSettings` inside your `Coldbox.cfc` configuration file.

By default the following are in place, without additional configuration:

```
moduleSettings = {
    "cbElasticsearch" = {
        //The native client Wirebox DSL for the transport client
        client="HyperClient@cbelasticsearch",
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
    }
};
```

At the current time only the REST-based [Hyper] native client is available. Support is in development for a socket based-client. For most applications, however the REST-based native client will be a good fit.

{% hint style="warning" %}
_Elasticsearch v8 Note:  Elasticsearch version greater than 8.0.0 have [XPack security](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-settings.html) enabled by default.  In order to disable security you must pass the `xpack.security.enabled=false` environment variable to the service, or add this configuration to your `elasticsearch.yml` file. Without security disabled, you will need to provide credentials._
{% endhint %}

## Configuration via Environment Variables

Since the default settings will read from environment variables if they exist, we can easily configure cbElasticsearch from a `.env` file:

```bash
# .env

# Configure elasticsearch connection
ELASTICSEARCH_HOST=localhost
ELASTICSEARCH_PORT=9222
ELASTICSEARCH_PASSWORD=B0xify_3v3ryth1ng

# Configure data storage and retrieval
ELASTICSEARCH_INDEX=books
ELASTICSEARCH_SHARDS=5
ELASTICSEARCH_REPLICAS=0
ELASTICSEARCH_MAX_CONNECTIONS=100
ELASTICSEARCH_READ_TIMEOUT=3000
ELASTICSEARCH_CONNECT_TIMEOUT=3000
```

You will need to read these settings into the coldfusion server upon server start via `commandbox-dotenv` or some other method.

{% hint style="warning" %}
For security reasons, make sure to add `.env` to your `.gitignore` file to avoid committing environment secrets to github/your git server.
{% endhint %}

## Request Parameter Overrides

In addition to global configuration settings, you can override request-specific parameters on a per-call basis. This is useful when you need different timeouts or settings for specific operations.

### Builder-Level Overrides

Builder objects (like `IndexBuilder`, `SearchBuilder`, `Document`, etc.) extend `BaseModel` and support fluent configuration of request parameters using the `.with*()` method:

```cfc
// Create an index with a custom 10-second timeout
get( "IndexBuilder@cbelasticsearch" )
    .new( name = "books" )
    .withTimeout( 10 )
    .save();
```

Here's an example of setting a custom header on a search builder:

```cfc
// Search with custom headers
get( "SearchBuilder@cbelasticsearch" )
    .new()
    .withHeader( "X-Custom-Header", "MyValue" )
    .setQuery( ... )
    .execute();
```

### Direct Client Method Overrides

All public methods in `HyperClient` accept a `requestOverrides` struct as the final parameter. This allows you to pass request-specific configuration directly to the client:

```cfc
// Check if index exists with a 45-second timeout
get( "HyperClient@cbelasticsearch" )
    .indexExists( "foo", { "timeout" : 45 } );

// Get index settings with custom timeout
get( "HyperClient@cbelasticsearch" )
    .getSettings( "myIndex", { "timeout" : 30 } );

// Search with request overrides
get( "HyperClient@cbelasticsearch" )
    .executeSearch( 
        searchBuilder, 
        { "timeout" : 60, "readTimeout" : 5000 } 
    );
```

### Merging Overrides

When both builder-level and client-level overrides are provided, they are merged together with client-level overrides taking precedence:

```cfc
var builder = get( "IndexBuilder@cbelasticsearch" )
    .new( name = "books" )
    .withTimeout( 10 );  // Builder-level: 10 seconds

// Client call with override - the 30-second timeout wins
get( "HyperClient@cbelasticsearch" )
    .applyIndex( builder, { "timeout" : 30 } );
```

### Available Override Parameters

Any HyperRequest parameters can be overridden on a per-request basis. These include:

- `timeout` - Connection timeout in seconds
- `username` - Username for authentication
- `password` - Password for authentication
- `maximumRedirects` - Maximum number of redirects to follow
- `retries` - Number of times to retry a request in case of failure
- `proxyUser` - Username for proxy authentication
- `proxyPassword` - Password for proxy authentication
- `headers` - Struct of custom headers to include in the request - use `.withHeader( "X-Custom-Header", "MyValue" )` to fluently set headers on builders