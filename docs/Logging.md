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

For more information on configuring log appenders for your application, see the [Coldbox documentation](https://coldbox.ortusbooks.com/getting-started/configuration/coldbox.cfc/configuration-directives/logbox)
