# Elasticsearch for the Coldbox Platform



## LICENSE
Apache License, Version 2.0.


Installation
============

Via CommandBox:  `install cbelasticsearch`


Instructions
============


The elasticsearch module for the Coldbox Platform provides you with a fluent search interface for Elasticsearch, in addition to a CacheBox Cache provider and a Logbox Appender.  Both the cache provider and logbox appender rely on Wirebox DSL mappings to the Elasticsearch client.  As such additional Wirebox configuration is necessary to use them outside of the Coldbox context.

Installation
============

Via CommandBox:  `install cbelasticsearch`


Requirements
============

* Coldbox >= v4.5
* Elasticsearch  >= v5.0 and < v7.0
* Lucee >= v4.5 or Adobe Coldfusion >= v11

_Note:  Most of the REST-based methods will work on Elasticsearch versions older than v5.0.  A notable exception is the multi-delete methods, which use the [delete by query](https://www.elastic.co/guide/en/elasticsearch/reference/5.4/docs-delete-by-query.html) functionality of ES5.  As such, Cachebox and Logbox functionality would be limited._

_Note:  Elasticsearch 7.0+ is not currently supported due to the bundled [Jest client](https://github.com/searchbox-io/Jest/issues/644), specifically because of changes to [type handling in Elasticsearch 7.0](https://github.com/searchbox-io/Jest/issues/641)._


********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
#### HONOR GOES TO GOD ABOVE ALL
Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"...but we glory in tribulations also: knowing that tribulation worketh patience; And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the Holy Ghost which is given unto us. ." Romans 5:5

### THE DAILY BREAD
 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12
