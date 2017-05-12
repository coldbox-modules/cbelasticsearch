# Elasticsearch for the Coldbox Platform



## LICENSE
Apache License, Version 2.0.


Installation
============

Via CommandBox:  `install elasticsearch`


Instructions
============

The elasticsearch module for the Coldbox Platform provides you with a fluent search interface for Elasticsearch, in addition to a CacheBox Cache provider and a Logbox Appender.  Both the cache provider and logbox appender rely on Wirebox DSL mappings to the Elasticsearch client.  As such additional Wirebox configuration is necessary to use them outside of the Coldbox context.

Requirements
============

* Coldbox ^v4.3
* Elasticsearch  ^v5.0
* Lucee ^v4.5 | Adobe Coldfusion ^v10

_Note:  While only Elasticsearch 5.0 and above is supported, most of the REST-based methods will work on previous versions.  A notable exception is the multi-delete methods, which use the [delete by query](https://www.elastic.co/guide/en/elasticsearch/reference/5.4/docs-delete-by-query.html) functionality of ES5.  As such, Cachebox and Logbox functionality would be limited._

Configuration
=============

Once you have installed the module, you may add a custom configuration, specific to your environment, by adding an `elasticsearch` configuration object to your `Coldbox.cfc` configuration file.

By default the following are in place, without additional configuration:


```
elasticsearch = {
	//The native client Wirebox DSL for the transport client
	client="JestClient@cbElasticsearch",
	// The default hosts - an array of host connections
	//  - REST-based clients (e.g. JEST):  round robin connections will be used
	//  - Socket-based clients (e.g. Transport):  cluster-aware routing used
	hosts = [
		//The default connection is made to http://127.0.0.1:9200
		{
			serverProtocol:'http',
			serverName:'127.0.0.1',
			//Socket-based connections will use 9300
			serverPort:'9200'
		}
	],
	//The default index
	defaultIndex = "cbElasticsearch",
	//The default number of shards to use when creating an index
	defaultIndexShards = 3,
	//The default number of index replicas to create
	defaultIndexReplicas = 0
};
```

As pre-1.0 release, only the REST-based [JEST] native client is available. Support is in development for a socket based-client.  For most applications, however 

Creating Indexes
================

#### Indexing Basics

Elasticsearch documents are stored in "indexes", each which contain a "type".

It's easy to think of Elasticsearch indexes as the RDBMS equivalent of a database, and types as the equivalent of a table, however there are notable differences in the underlying architecture.

[Elasticsearch engineer Adrien Grand on the comparisons](https://www.elastic.co/blog/index-vs-type):

> the way data is stored is so different that any comparisons can hardly make sense, and this ultimately led to an overuse of types in cases where they were more harmful than helpful.

> An index is stored in a set of shards, which are themselves Lucene indices. This already gives you a glimpse of the limits of using a new index all the time: Lucene indices have a small yet fixed overhead in terms of disk space, memory usage and file descriptors used. For that reason, a single large index is more efficient than several small indices: the fixed cost of the Lucene index is better amortized across many documents.

On types:

> types are a convenient way to store several types of data in the same index, in order to keep the total number of indices low for the reasons exposed above... One nice property of types is that searching across several types of the same index comes with no overhead compared to searching a single type: it does not change how many shard results need to be merged

- From [Index vs. Type on the Elastic blog](https://www.elastic.co/blog/index-vs-type).

In short, indexes have a higher overhead and disallow the aggregation of search results between types.  If it is desired that your application search interfaces return multiple entity or domain types, then those should respresent distinctive types within a single index, allowing them to be aggregated, sorted, and ordered in search results.


#### Creating and Mapping an Index

The `IndexBuilder` model assists with the creation and mapping of indexes. Mappings define the allowable data types within your documents and allow for better and more accurate search aggregations.  Let's say we have a book model that we intend to make searchable.  We are storing this in our `bookshop` index, under the type of `book`.  Let's create the index (if it doesn't exist) and map the type of `book`:

```
var indexBuilder = getInstance( "IndexBuilder@cbElasticsearch" ).new( 
	"bookshop",
	{
		"books":{
			"_all":       { "enabled": false  },
			"properties" : {
				"title" : {"type":"string"},
				"summary" : {"type":"string"},
				"description" : {"type":"string"},
				// denotes a nested struct with additional keys
				"author" : {"type":"object"},
				// date with specific format type
				"publishDate" {
					"type":"date",
					//Our format will be: yyyy-mm-dd
					"format" :"strict_date"
				},
				"edition" : {"type" : "integer"},
				"ISBN" : {"type" : "integer"}
			}
		}
	}

).save()

```


We can also add mappings after the `new()` method is called:

```
// instantiate the index builder
var indexBuilder = getInstance( "IndexBuilder@cbElasticsearch" ).new( "bookshop" );
// our mapping struct
var booksMapping = {
	"_all":       { "enabled": false  },
	"properties" : {
		"title" : {"type":"string"},
		"summary" : {"type":"string"},
		"description" : {"type":"string"},
		// denotes a nested struct with additional keys
		"author" : {"type":"object"},
		// date with specific format type
		"publishDate" {
			"type":"date",
			//Our format will be: yyyy-mm-dd
			"format" :"strict_date"
		},
		"edition" : {"type" : "integer"},
		"ISBN" : {"type" : "integer"}
	}
}

// add the mapping and save
indexBuilder.addMapping( "books", booksMapping ).save();
```

Note that, in the above examples, we are applying the index and mappings directly from within the object, itself, which is intuitive and fast. We could also pass the `IndexBuilder` object to the `Client@cbElasticsearch` instance's `applyIdex( required IndexBuilder indexBuilder )` method, if we wished.

If an explicit mapping is not specified when the index is created, Elasticsearch will assign types when the first document is saved.  

We've also passed a simple struct in to the index properties.  If we wanted to add additional settings or configure replicas and shards, we could pass a more comprehensive struct, including a [range of settings](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/index-modules.html) to the `new()` method to do so:

```
indexBuilder.new(  
	"bookshop",
	{
		"settings" : {
			"number_of_shards" : 10,
			"number_of_replicas" : 2,
			"auto_expand_replicas" :true,
			"shard.check_on_startup" : "checksum"
		},
		"mappings" : {
			"books":{
				"_all": { "enabled": false  },
				"properties" : {
					"title" : {"type":"string"},
					"summary" : {"type":"string"},
					"description" : {"type":"string"},
					// denotes a nested struct with additional keys
					"author" : {"type":"object"},
					// date with specific format type
					"publishDate" {
						"type":"date",
						//Our format will be: yyyy-mm-dd
						"format" :"strict_date"
					},
					"edition" : {"type" : "integer"},
					"ISBN" : {"type" : "integer"}
				}
			}
		}
	}

);
```

*Additional Reading:*

* [Elasticsearch Mapping Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
* [Index Settings Reference](https://www.elastic.co/guide/en/elasticsearch/guide/current/_index_settings.html)



Managing Documents
==================

#### Creating a Document

#### Updating a Document

#### Deleting a Document

Searching Documents
===================

The 

********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
####HONOR GOES TO GOD ABOVE ALL
Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the 
Holy Ghost which is given unto us. ." Romans 5:5

###THE DAILY BREAD
 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12