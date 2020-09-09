Logging
=======

cbElasticsearch comes pre-packaged with two logging appenders which can be configured in your Coldbox application to capture log messages and store them for later search and retrieval.  The appenders differ in the manner in which they store data within the elasticsearch index.

- `LogstashAppender` - This appender stores its log data in indexes named by the rotation frequency.  Log data is never deleted. Instead, new indexes are created at intervals specified by the `rotation` property, which defaults to "daily" but can be set to "monthly", "weekly" or "hourly".  
- `ElasticsearchAppender` - This appender stores its log data in a single index, with a specified rotation frequency and period of retention.  During rotation, any documents which are older than the specified `rotationDays` value are purged from the elasticsearch index.

Appenders may be configured in your Coldbox configuration like so:


```
logBox = {
    // Define Appenders
    appenders = {
        console = {
            class="coldbox.system.logging.appenders.ConsoleAppender"
        },
        elasticsearch = {
            class="cbelasticsearch.models.logging.ElasticsearchAppender",
            properties = {
                // the name of the index to store log data in - defaults to logbox
                "index"            : "myapp-logs",
                // the number of days to retain logs
				"rotationDays"     : 30,
                // perform the rotation purge every this number of minutes
				"rotationFrequency": 5
            }
        },
        logstash = {
            class="cbelasticsearch.models.logging.LogstashAppender",
            properties = {
                // the index prefix to use - prior to the rotational timestamps - defaults to ".logstash-[applicationName]"
                "index"            : "myapp-logs",
                // the frequency of index rotation
				"rotation"     : "daily"
            }
        }

    },
    // Root Logger - appends error messages to all appenders
    root = { levelmax="ERROR", appenders="*" }
};
```

For more information on configuring log appenders for your application, see the [Coldbox documentation](https://coldbox.ortusbooks.com/getting-started/configuration/coldbox.cfc/configuration-directives/logbox)