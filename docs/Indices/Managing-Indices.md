---
description: Learn how to create, update and delete indices with CBElasticsearch
---

# Managing Indices

Elasticsearch documents are stored in an "index", with the document structure defined by a "mapping". An Elasticsearch index is a JSON document store, and the mapping is a JSON configuration which defines the data type Elasticsearch should use for each document field.

By default, Elasticsearch will dynamically generate these index mapping when a document is saved to the index. See [Dynamic Mappings in Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic-mapping.html) for more details.

## Retrieving information on Indices

To retrieve a list of all indices on the connected cluster, use the client `getIndices` method:

```js
var indexMap = getInstance( "Client@cbElasticsearch" ).getIndices();
```

This will return a struct of all indices ( with the names as keys ), which will provide additional information on each index, such as:

* Any assigned aliases
* The number of documents in the index
* The size of the storage space used for the index in bytes

## Creating an Index

The `IndexBuilder` model assists with the creation and mapping of indices. Mappings define the allowable data types within your documents and allow for better and more accurate search aggregations. Let's say we have a book model that we intend to make searchable via a `bookshop` index. Let's go ahead and create the index using the IndexBuilder:

```js
var indexBuilder = getInstance( "IndexBuilder@cbElasticsearch" ).new( "bookshop" ).save();
```

This will create an empty index which we can begin populating with documents.

## Creating an Explicit Index Mapping

To avoid the inherent troubles with dynamic mappings, you can define an explicit mapping using the `properties` argument:

```js
getInstance( "IndexBuilder@cbElasticsearch" )
    .new(
        name = "bookshop",
        properties = {
            "title" : { "type" : "text" },
            "summary" : { "type" : "text" },
            "description" : { "type" : "text" },
            // denotes a nested struct with additional keys
            "author" : { "type" : "object" },
            // date with specific format type
            "publishDate" : {
                "type" : "date",
                // our format will be = yyyy-mm-dd
                "format" = "strict_date"
            },
            "edition" : { "type" : "integer" },
            "ISBN" : { "type" : "integer" }
        }
    )
    .save();
```
{% hint style="info" %}
While it is not *required* that you explicitly define an index mapping, it is **highly recommended** since Elasticsearch's assumptions about the incoming document data may not always be correct. This leads to issues where the Elasticsearch-generated mapping is wrong and prevents further data from being indexed if it does not match the expected data type.
{% endhint %}

## Using Client.ApplyIndex

In the previous examples, we've created the index and mapping from the IndexBuilder itself. If we wish, we could instead pass the `IndexBuilder` object to the `Client@cbElasticsearch` instance's `applyIndex( required IndexBuilder indexBuilder )` method:

```js
var myNewIndex = indexBuilder.new( "bookshop" )
                    .populate( getInstance( "BookshopIndexConfig@myApp" ).getConfig() );
getInstance( "Client@cbElasticsearch" ).applyIndex( myNewIndex );
```

## Configuring Index Settings

So far we've passed a simple struct of field mappings in to the index properties. If we wanted to add additional settings or configure replicas and shards, we could pass a more comprehensive struct, including a [range of settings](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/index-modules.html) to the `new()` method to do so:

```js
indexBuilder.new(
    "bookshop",
    {
        "settings" : {
            "number_of_shards" : 10,
            "number_of_replicas" : 2,
            "auto_expand_replicas" : true,
            "shard.check_on_startup" : "checksum"
        },
        "mappings" : {
            "properties" : {
                "title" : { "type" : "text" },
                "summary" : { "type" : "text" },
                "description" : { "type" : "text" },
                // denotes a nested struct with additional keys
                "author" : { "type" : "object" },
                // date with specific format type
                "publishDate" : {
                    "type" : "date",
                    // our format will be = yyyy-mm-dd
                    "format" : "strict_date"
                },
                "edition" : { "type" : "integer" },
                "ISBN" : { "type" : "integer" }
            }
        }
    }

);
```

## Updating an Existing Index

The `IndexBuilder` model also provides a `patch()` convenience method for updating the mapping or settings on an index:

```js
indexBuilder.patch(
    index = "bookshop",
    settings = {
        "number_of_shards"      : 10,
        "number_of_replicas"    : 2,
        "auto_expand_replicas"  : true,
        "shard.check_on_startup": "checksum"
    }
);
```

Here's a quick example of using `indexBuilder.patch()` to add two new fields to an existing `reviews` index:

```js
indexBuilder.patch(
    index = "reviews",
    properties = {
        "authorName"   : { "type" : "text" },
        "helpfulRating": { "type" : "integer" }
    }
);
```

## Retrieving Settings for an Index
To retreive a list of all settings for an index you may use the `getSettings` method on the client. 

```js
var indexSettings = getInstance( "Client@CBElasticsearch" ).getSettings( "bookshop" )
```
## Retrieving Mappings for an Index
To retreive a list of the configured mappings for an index you may use the `getMappings` method on the client. 

```js
var mappings = getInstance( "Client@CBElasticsearch" ).getMappings( "reviews" );
```

## Deleting an Index

All good things must come to an end, eh? You can use `Client.deleteIndex()` to delete an existing index:

```js
getInstance( "Client@CBElasticsearch" ).deleteIndex( "reviews" )
```

Or you can use `IndexBuilder.delete()`:

```js
IndexBuilder.new( "reviews" ).delete();
```

## Additional Reading

{% hint style="warning" %}
_Deprecation notice: Custom index types [are deprecated](https://www.elastic.co/guide/en/elasticsearch/reference/master/removal-of-types.html) since Elasticsearch v7.0, and should no longer be used. Only a single type will be accepted in future releases._
{% endhint %}

* [Elasticsearch Mapping Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
* [Index Settings Reference](https://www.elastic.co/guide/en/elasticsearch/guide/current/_index_settings.html)