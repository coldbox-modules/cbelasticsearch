# Elasticsearch for the Coldbox Platform



## LICENSE
Apache License, Version 2.0.


Installation
============

Via CommandBox:  `install cbelasticsearch`


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
	// The default index
	defaultIndex = "cbElasticsearch",
	// The default number of shards to use when creating an index
	defaultIndexShards = 3,
	// The default number of index replicas to create
	defaultIndexReplicas = 0
	// Whether to use separate threads for client transactions 
	multiThreaded = true,
	// The maximum number of connections allowed per route ( e.g. search URI endpoint )
	maxConnectionsPerRoute = 10,
	// The maxium number of connectsion, in total for all Elasticsearch requests
	maxConnections = 100
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

Documents are the searchable, serialized objects within your indexes.  As noted above, documents may be assigned a type, allowing separation of schema, while still maintaining searchability across all documents in the index.   Within an index, each document is referenced by an `_id` value.  This `_id` may be set manually ( `document.setId()` ) or, if not provided will be auto-generated when the record is persisted.  Note that, if using numeric primary keys for your `_id` value, they will be cast as strings on serialization. 

#### Creating a Document

The `Document` model is the primary object for creating and working with Documents.  Let's say, again, we were going to create a `book` typed document in our index.  We would do so, by first creating a Documen object.

```
var book = getInstance( "Document@cbElasticsearch" ).new( 
	index="bookshop",
	type="book",
	properties = {
		"title"      : "Elasticsearch for Coldbox",
		"summary"    : "A great book on using Elasticsearch with the Coldbox framework",
		"description": "A long descriptio with examples on why this book is great",
		"author"     : {
			"id"       : 1
			"firstName": "Jon",
			"lastName" : "Clausen"
		},
		// date with specific format type
		"publishDate": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" ),
		"edition"    : 1,
		"ISBN"       : 123456789054321
	}
);

book.save();
```

In addition to population during the new method, we could also populate the document schema using other methods:

```
document.populate( myBookStruct )
```

or by individual setters:

```
document.setValue( 
	"author", 
	{
		"firstName" : "Jon",
		"lastName"  : "Clausen"
	} 
);
```

If we want to manually assign the `_id` value, we would need to explicitly call `setId( myCustomId )` to do so, or would need to provide an `_id` key in the struct provided to the `new()` or `populate()` methods.

#### Retrieving documents

To retrieve an existing document, we must first know the `_id` value.  We can either retrieve using the `Document` object or by interfacing with the `Client` object directly.  In either case, the result returned is a `Document` object, i f found, or null if not found.

Using the `Document` object's accessors:

```
var existingDocument = getInstance( "Document@Elasticsearch" )
							.setIndex( 'bookshop' )
							.setTitle( 'book' )
							.setId( bookId )
							.get(); 
```

Calling the get() method with explicit arguments:

```
var existingDocument = getInstance( "Document@cbElasticsearch" )
							.get( 
								id    = bookId,
								index = 'bookshop',
								type  = 'book'
							);
```

Calling directly, using the same arguments, from the client:

```
var existingDocument = getInstance( "Client@cbElasticsearch" )
							.get( 
								id    = bookId,
								index = 'bookshop',
								type  = 'book'
							);


```

#### Updating a Document

Once we've retrieved an existing document, we can simply update items through the `Document` instance and re-save them.

```
existingDocument.populate( properties=myUpdatedBookStruct ).save()
```

You can also pass Document objects to the `Client`'s `save()` method:

```
getInstance( "Client@cbElasticsearch" ).save( existingDocument );
```

#### Bulk Inserts and Updates

Builk inserts and updates can be peformed by passing an array of `Document` objects to the Client's `saveAll()` method:

```
var docments = [];

for( var myStruct in myArray ){
	var document = getInstance( "Document@cbElasticsearch" ).new( 
		index      = myIndex,
		type       = myType,
		properties = myStruct
	);

	arrayAppend( documents, doucument );
}

getInstance( "Client@cbElasticsearch" ).saveAll( documents );

```

#### Deleting a Document

Deleting documents is similar to the process of saving.  The `Document` object may be used to delete a single item.

```
var document = getInstance( "Document@cbElasticsearch" )
				.get( 
					id    = documentId, 
					index = "bookshop", 
					type  = books 
				);
if( !isNull( document ) ){
	document.delete();
}
```

Documents may also be deleted by passing a `Document` instance to the client:

```
getInstance( "Client@cbElasticsearch" ).delete( myDocument );
```

Finally, documents may also be deleted by query, using the `SearchBuilder` ( more below ):

```
getInstance( "searchBuilder@cbElasticsearch" )
		.new( index="bookshop", type="books" )
		.match( "name", "Elasticsearch for Coldbox" )
		.deleteAll();
```


Searching Documents
===================

The `SearchBuilder` object offers an expressive syntax for crafting detailed searches with ranked results.  To perform a simple search for matching documents documents, using Elasticsearch's automatic scoring, we would use the `SearchBuilder` like so:

```
var searchResults = getInstance( "searchBuilder@cbElasticsearch" )
						.new( index="bookshop", type="books" )
						.match( "name", "Elasticsearch" )
						.execute();
```

By default this search will return an array of `Document` objects ( or an empty array if no results are found ), with a descending match score as the sort.

To output the results of our search, we would use a loop, accessing the `Document` methods:

```
for( var resultDocument in searchResult ){
	var resultScore     = resultDocument.getScore();
	var documentMemento = resultDocument.getMemento();
	var bookName        = documentMemento.name;
	var bookDescription = documentMemento.description;
}
```

The "memento" is our structural representation of the document. We can also use the built-in method of the Document object:

```
for( var resultDocument in searchResult ){
	var resultScore     = resultDocument.getScore();
	var bookName        = resultDocument.getValue( "name" );
	var bookDescription = resultDoument.getValue( "description" );
}
```

#### Search matching


#### Exact matching

The `term()` method allows a means of specifying an exact match of all documents in the search results.  An example use case might be only to search for active documents:

```
searchBuilder.term( 'isActive', 1 );
```

Or a date range:

```
searchBuilder.term( 'publishDate', '2017-05-13' );
```

#### Boosting individual matches

The `match()` method of the `SearchBuilder` also allows for a `boost` argument.  When provided, results which match the term will be ranked higher in the results:

```
searchBuilder
		.match( "shortDescription", "Elasticsearch" )
		.match( "description", "Elasticsearch" )
		.match( 
			name="name", 
			value="Elasticsearch",
			boost=.5
		);
```

In the above example, documents with a `name` field containing "Elasticsearch" would be boosted in score higher than those which only find the value in the short or long description.

#### Advanced Query DSL

The SearchBuilder also allows full use of the [Elasticsearch query language](https://www.elastic.co/guide/en/elasticsearch/reference/current/_introducing_the_query_language.html), allowing detailed configuration of queries, if the basic `match()`, `sort()` and `aggregate()` methods are not enough to meet your needs. There are several methods to provide the raw query language to the Search Builder.  One is during instantiation.  

In the following we are looking for matches of active records with "Elasticsearch" in the name, description, or shortDescription fields. We are also looking for a phrase match of "is awesome" and are boosting the score of the applicable document, if found.

```
var search = getInstance( "SearchBuilder@cbElasticsearch" )
					.new( 
						index = "bookshop",
						type = "books",
						properties = {
							"query":{
								"term" : {
									"isActive" : 1
								},
								"match" : {
									"name"            : "Elasticsearch",
									"description"     : "Elasticsearch",
									"shortDescription": "Elasticsearch"
								},
								"match_phrase" : {
									"description" : {
										"query" : "is awesome",
										"boost" : 2
									}
								},

							}
						}
					)
					.execute();
```

For more information on Elasticsearch query DSL, the [Search in Depth Documentation](https://www.elastic.co/guide/en/elasticsearch/guide/current/search-in-depth.html) is an excellent starting point.


#### Sorting Results

The `sort()` method also allows you to specify custom sort options.  To sort by author last name, instead of score, we would simply use:

```
searchBuilder.sort( "author.lastName", "asc" );
```

While our documents would still be scored, the results order would be changed to that specified.




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