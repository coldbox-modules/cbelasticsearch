---
description: Learn how to transform incoming data in an Elasticsearch Ingest Pipeline.
---

# Logging

cbElasticsearch comes pre-packaged with two logging appenders which can be configured in your Coldbox application to capture log messages and store them for later search and retrieval.  The appenders differ in the manner in which they store data within the elasticsearch index.

- `LogstashAppender` - This appender stores its log data in indexes named by the rotation frequency.  Log data is never deleted. Instead, new indexes are created at intervals specified by the `rotation` property, which defaults to "daily" but can be set to "monthly", "weekly" or "hourly".  
- `ElasticsearchAppender` - This appender stores its log data in a single index, with a specified rotation frequency and period of retention.  During rotation, any documents which are older than the specified `rotationDays` value are purged from the elasticsearch index.

Appenders may be configured in your Coldbox configuration like so:


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
                "migrateIndices"  : false
            }
        }

    },
    // Root Logger - appends invo messages to all appenders - except those with a specified `levelMax` like above
    root = { levelmax="INFO", appenders="*" }
};
```

For more information on configuring log appenders for your application, see the [Coldbox documentation](https://coldbox.ortusbooks.com/getting-started/configuration/coldbox.cfc/configuration-directives/logbox)