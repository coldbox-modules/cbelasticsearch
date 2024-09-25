---
description: Learn how to transform incoming data in an Elasticsearch Ingest Pipeline.
---

# Logging

cbElasticsearch comes pre-packaged with a logging appenders which can be configured in your Coldbox application to capture log messages and store them for later search and retrieval.

The  `LogstashAppender` uses a time-series data stream to cycle log data through a configured lifecycle policy.  By default data is retained for 365 days.  If you wish to provide a different configuration or retention period, you can do so by specifying a custom `lifeCyclePolicy` setting to the appender.  [More on Index LifeCycles here](Indices/Index-Lifecycles.md).

Appenders may be configured in your Coldbox configuration.  Alternately, you can [install the `logstash` module ](https://logstash.ortusbooks.com/getting-started/introduction), which will auto-register appenders for you.  Note that the Logstash module already installs with `cbElasticsearch` and will register it so you only need one module or the other.


```js
logBox = {
    // Define Appenders
    appenders = {
        console = {
            class="coldbox.system.logging.appenders.ConsoleAppender"
        },
        logstash = {
            class="cbelasticsearch.models.logging.LogstashAppender",
            // The log level to use for this appender - in this case only errors and above are logged to Elasticsearch
            levelMax = "ERROR",
            // Appender configuration
            properties = {      
                // The pattern used for the data stream configuration.  All new indices with this pattern will be created as data streams        
                "dataStreamPattern" : "logs-coldbox-*",
                // The data stream name to use for this appenders logs
                "dataStream" : "logs-coldbox-logstash-appender",
                // The ILM policy name to create for transitioning/deleting data
                "ILMPolicyName"   : "cbelasticsearch-logs",
                // The name of the component template to use for the index mappings
                "componentTemplateName" : "cbelasticsearch-logs-mappings",
                // The name of the index template whic the data stream will use
                "indexTemplateName" : "cbelasticsearch-logs",
                // Retention of logs in number of days
                "retentionDays"   : 365,
                // an optional lifecycle full policy https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-put-lifecycle.html
                "lifecyclePolicy" : javacast( "null", 0 ),
                // The name of the application which will be transmitted with the log data and used for grouping
                "applicationName" : "My Application name",
                // A release version to use for your logs
                "releaseVersion"  : "1.0.0",
                // The number of shards for the backing data stream indices
                "indexShards"     : 1,
                // The number of replicas for the backing indices
                "indexReplicas"   : 0,
                // The max shard size at which the hot phase will rollover data
                "rolloverSize"    : "10gb",
                // Whether to migrate any indices used in v2 of this module over to data streams - only used if an `index` key ( v2 config ) is provided to the properties
                "migrateIndices"  : false,
                // Whether to allow log events to fail quietly.  When turned on, any errors received when saving log entries will not throw but will be logged out to other appenders
                "throwOnError"    : true
            }
        }

    },
    // Root Logger - appends into messages to all appenders - except those with a specified `levelMax` like above
    root = { levelmax="INFO", appenders="*" }
};
```

For more information on configuring LogBox log appenders for your application, see the [Coldbox documentation](https://coldbox.ortusbooks.com/getting-started/configuration/coldbox.cfc/configuration-directives/logbox)


# Detached Appenders

The logging capbilities of the Elasticsearch module extend beyond the framework LogBox appenders. In a era of big data an analytics, developers also have the ability to create custom appenders appenders for ad-hoc use in storing messages, collecting metrics, or for use in aggregations.   Simple messages can be logged or even raw messages which adhere to the [Elastic Common Schema](https://www.elastic.co/guide/en/ecs/current/index.html).  By using detached appenders, you can capture custom information for later reference.

## Creating a Detached Appender

To create a detached appender, use the `AppenderService` method `createDetachedAppender( string name, struct properties )`.  The properties passed can be any of the above, or you can omit those and the default properties will be used:
```
getInstance( "AppenderService@cbelasticsearch" )
    .createDetachedAppender(
        "myCustomAppender",
        {
                        
            "retentionDays"         : 30,
            "applicationName"       : "Custom Appender Logs",
            "rolloverSize"          : "1gb"
        }
    );
```

Now we can log messages to this appender on an ad-hoc basis by calling the methods in the Appender service.

### Logging a single message

We can log a traditional single message by using the `logToAppender` method of the Appender service. This is familiar to many Coldbox developers:

```java
getInstance( "AppenderService@cbelasticsearch" )
    .logToAppender(
        "myCustomAppender",
        "This is my custom log message which contains information I need to search later",
        "info",
        {
            // labels are stored as exact match keywords which allow you aggregate and filter the log messages
            // These are promoted to the root labels object
            "labels" : {
                "manager" : "Jim Leyland",
                "team" : "Detroit Tigers"
            },
            // Any other key value pairs become part of the log entry extra info, which is searchable but not filterable
            "person" : {
                "firstName" : "Jim",
                "lastName" : "Leyland",
                "teams" : [
                    "Detroit Tigers",
                    "Pittsburg Pirates",
                    "Colorado Rockies"
                ],
                "hallOfFamer" : true,
                "inductionYear" : 2024
            }
        }
    );
```


### Logging one or more raw formatted messages

If you are comfortable assembling your own JSON and want to ship those log entries to elasticsearch raw, you can do so by usin the `logRawToAppender` method of the Appender service.  This functionality can also allow you to assemble a series of logs and ship them all off in one bulk operation.  The `messages` argument to the function may be a single entry struct, or it may be an array of multiple message which adhere to the [Elastic Common Schema](https://www.elastic.co/guide/en/ecs/current/index.html).

```java
getInstance( "AppenderService@cbelasticsearch" )
    .logRawToAppender(
        "myCustomAppender",
        [
            {
                "@timestamp" : now(),
                "log"        : {
                    "level"    : "info",
                    "logger"   : "myCustomLogger",
                    "category" : "CustomEvents"
                },
                "message" : "This is my custom log message which contains information I need to search later",
                "event"   : {
                    "action" : event.getCurrentAction(),
                    "duration" : myProcessingDurationNanos,
                    "created"  : now(),
                    "severity" : 4,
                    "category" : "myCustomLogger",
                    "dataset"  : "cfml",
                    "timezone" : createObject( "java", "java.util.TimeZone" ).getDefault().getId()
                },
                "file" : { "path" : CGI.CF_TEMPLATE_PATH },
                "url"  : {
                    "domain" : CGI.SERVER_NAME,
                    "path"   : CGI.PATH_INFO,
                    "port"   : CGI.SERVER_PORT,
                    "query"  : CGI.QUERY_STRING,
                    "scheme" : lCase( listFirst( CGI.SERVER_PROTOCOL, "/" ) )
                },
                "http"    : {
                    "request" : { "referer" : CGI.HTTP_REFERER },
                },
                "labels" :  {
                    "manager" : "Jim Leyland",
                    "team" : "Detroit Tigers",
                    "hallOfFameYear" : "2024"
                },
                "package" : {
                    "name"    : getProperty( "applicationName" ),
                    "version" : "1.1.0",
                    "type"    : "cfml",
                    "path"    : expandPath( "/" )
                },
                "host"       : { "name" : CGI.HTTP_HOST, "hostname" : CGI.SERVER_NAME },
                "client"     : { "ip" : CGI.REMOTE_ADDR },
                "user"       : {},
                "user_agent" : { "original" : CGI.HTTP_USER_AGENT },
                "error" : {
                    "type"      : "message",
                    "level"     : level,
                    "message"   : loge.getMessage(),
                    "extrainfo" : serializeJSON(
                        {
                            "person" : {
                                "firstName" : "Jim",
                                "lastName" : "Leyland",
                                "teams" : [
                                    "Detroit Tigers",
                                    "Pittsburg Pirates",
                                    "Colorado Rockies"
                                ],
                                "hallOfFamer" : true,
                                "inductionYear" : 2024
                            }
                        }
                    )
                }
            },
            ... and so on ...
        ]
    );
```

See our docs [on search](https://cbelasticsearch.ortusbooks.com/searching/search) and [aggregations](https://cbelasticsearch.ortusbooks.com/searching/aggregations) for more information on how to assemble custom reports and aggregations of your logged data.

