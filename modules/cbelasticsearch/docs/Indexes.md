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

In short, indexes have a higher overhead and make the aggregation of search results between types very more expensive.  If it is desired that your application search interfaces return multiple entity or domain types, then those should respresent distinctive types within a single index, allowing them to be aggregated, sorted, and ordered in search results.

### Retrieving information on Indices

To retrieve a list of all indices on the connected cluster, use the client `getIndices` method:

```
var indexMap = getInstance( "Client@cbElasticsearch" ).getIndices();
```

This will return a struct of all indexes ( with the names as keys ), which will provide additional information on each index, such as:

* Any assigned aliases
* The number of documents in the index
* The size of the storage space used for the index in bytes


#### Creating and Mapping an Index


The `IndexBuilder` model assists with the creation and mapping of indexes. Mappings define the allowable data types within your documents and allow for better and more accurate search aggregations.  Let's say we have a book model that we intend to make searchable.  We are storing this in our `bookshop` index, under the type of `book`.  Let's create the index (if it doesn't exist) and map the type of `book`:

```
var indexBuilder = getInstance( "IndexBuilder@cbElasticsearch" ).new(
    "bookshop",
    {
        "books" = {
            "_all" = { "enabled" = false },
            "properties" = {
                "title" = { "type" = "string" },
                "summary" = { "type" = "string" },
                "description" = { "type" = "string" },
                // denotes a nested struct with additional keys
                "author" = { "type" = "object" },
                // date with specific format type
                "publishDate" = {
                    "type" = "date",
                    // our format will be = yyyy-mm-dd
                    "format" = "strict_date"
                },
                "edition" = { "type" = "integer" },
                "ISBN" = { "type" = "integer" }
            }
        }
    }
).save();
```

If you use Elasticsearch > 6, replace above "type":"string" with "type":"text" (Elasticsearch has dropped the string type and is now using text).

We can also add mappings after the `new()` method is called:

```
// instantiate the index builder
var indexBuilder = getInstance( "IndexBuilder@cbElasticsearch" ).new( "bookshop" );
// our mapping struct
var booksMapping = {
    "_all" = { "enabled" = false },
    "properties" = {
        "title" = { "type" = "string" },
        "summary" = { "type" = "string" },
        "description" = { "type" = "string" },
        // denotes a nested struct with additional keys
        "author" = { "type" = "object" },
        // date with specific format type
        "publishDate" = {
            "type" = "date",
            // our format will be = yyyy-mm-dd
            "format" = "strict_date"
        },
        "edition" = { "type" = "integer" },
        "ISBN" = { "type" = "integer" }
    }
};
```

_Deprecation notice:  The index "type" ( e.g. "books" ) [has now been deprecated](https://www.elastic.co/guide/en/elasticsearch/reference/master/removal-of-types.html) in recent versions of Elasticsearch, and should no longer be used. Only a single type will be accepted in future releases._

Note that, in the above examples, we are applying the index and mappings directly from within the object, itself, which is intuitive and fast. We could also pass the `IndexBuilder` object to the `Client@cbElasticsearch` instance's `applyIndex( required IndexBuilder indexBuilder )` method, if we wished.

If an explicit mapping is not specified when the index is created, Elasticsearch will assign types when the first document is saved.

We've also passed a simple struct in to the index properties.  If we wanted to add additional settings or configure replicas and shards, we could pass a more comprehensive struct, including a [range of settings](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/index-modules.html) to the `new()` method to do so:

```
indexBuilder.new(
    "bookshop",
    {
        "settings" = {
            "number_of_shards" = 10,
            "number_of_replicas" = 2,
            "auto_expand_replicas" = true,
            "shard.check_on_startup" = "checksum"
        },
        "mappings" = {
            "books" = {
                "_all" = { "enabled" = false },
                "properties" = {
                    "title" = { "type" = "string" },
                    "summary" = { "type" = "string" },
                    "description" = { "type" = "string" },
                    // denotes a nested struct with additional keys
                    "author" = { "type" = "object" },
                    // date with specific format type
                    "publishDate" = {
                        "type" = "date",
                        // our format will be = yyyy-mm-dd
                        "format" = "strict_date"
                    },
                    "edition" = { "type" = "integer" },
                    "ISBN" = { "type" = "integer" }
                }
            }
        }
    }

);
```

The `IndexBuilder` model also provides a convenience method for updating the mapping or settings on an index:

```
indexBuilder.patch(
    "bookshop",
    settings = {
            "number_of_shards" = 10,
            "number_of_replicas" = 2,
            "auto_expand_replicas" = true,
            "shard.check_on_startup" = "checksum"
        }
    }
);
```

```
indexBuilder.patch(
    "bookshop",
    properties = {
            "number_of_shards" = 10,
            "number_of_replicas" = 2,
            "auto_expand_replicas" = true,
            "shard.check_on_startup" = "checksum"
        }
    }
);
```
*Additional Reading:*

* [Elasticsearch Mapping Guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
* [Index Settings Reference](https://www.elastic.co/guide/en/elasticsearch/guide/current/_index_settings.html)

### Retrieving information on Aliases

The client's `getAliases` method allows you to retrieve a map containing information on aliases in use in the connected cluster.

```
var aliasMap = getInstance( "Client@cbElasticsearch" ).getAliases();
```

The corresponding object will have two keys: `aliases` and `unassgined`. The former is a map of aliases with their corresponding index, the latter is an array of indexes which are unassigned to any alias.


## Alias Builder

cbElasticSearch offers the `AliasBuilder` for assistance in adding and removing index aliases.

For creating an alias:

```
getWireBox().getInstance( "AliasBuilder@cbElasticSearch" )
    .add( indexName = "myIndex", aliasName = "newAlias" )
    .save();
```

For removing an alias:

```
getWireBox().getInstance( "AliasBuilder@cbElasticSearch" )
    .remove( indexName = "otherIndex", aliasName = "randomAlias" )
    .save();
```

For bulk operations, use the cbElasticSearch client's `applyAliases` method. These operations are performed in the same transaction (i.e. atomic), so it's safe to use for switching the alias from one index to another.

```
var removeAliasAction = getWireBox().getInstance( "AliasBuilder@cbElasticSearch" )
    .remove( indexName = "testIndexName", aliasName = "aliasNameOne" );
var addNewAliasAction = getWireBox().getInstance( "AliasBuilder@cbElasticSearch" )
    .add( indexName = "testIndexName", aliasName = "aliasNameTwo" );

variables.client.applyAliases(
    // a single alias action can also be provided
    aliases = [ removeAliasAction, addNewAliasAction ]
);
```

## Mapping Builder

Introduced in `v1.0.0` the MappingBuilder model provides a fluent closure-based sytax for defining and mapping indexes.
This builder can be accessed by injecting it into your components:

```
component {
    property name="builder" inject="MappingBuilder@cbElasticSearch";
}
```

The `new` method of the `IndexBuilder` also accepts a closure as the second (`properties`) argument.  If a closure is passed, a `MappingBuilder` instance is passed as an argument to the closure:

```
indexBuilder.new( "elasticsearch", function( builder ) {
    return {
        "_doc" = builder.create( function( mapping ) {
            mapping.text( "title" );
            mapping.date( "createdTime" ).format( "date_time_no_millis" );
        } )
    };
} );
```

The `MappingBuilder` has one primary method: `create`.  `create` takes a callback with a `MappingBlueprint` object, usually aliased as `mapping`.

## Mapping Blueprint

The `MappingBlueprint` gives a fluent api to defining a mapping.  It has methods for all the ElasticSearch mapping types:

```
builder.create( function( mapping ) {
    mapping.text( "title" );
    mapping.date( "createdTime" ).format( "date_time_no_millis" );
    mapping.object( "user", function( mapping ) {
        mapping.keyword( "gender" );
        mapping.integer( "age" );
        mapping.object( "name", function( mapping ) {
            mapping.text( "first" );
            mapping.text( "last" );
        } );
    } );
} )
```

As seen above, `object` expects a closure which will be provided another `MappingBlueprint`.  The results will be set as the `properties` of the `object` call.

## Parameters

Parameters can be chained on to a mapping type.  Parameters are set using `onMissingMethod` and will use the method name (as snake case) as the parameter name and the first argument passed as the parameter value.

```
builder.create( function( mapping ) {
    mapping.text( "title" ).fielddata( true );
    mapping.date( "createdTime" ).format( "date_time_no_millis" );
} )
```

> You can also add parameters using the `addParameter( string name, any value )` or `setParameters( struct map )` methods.

The only exception to the parameters functions is `fields` which expects a closure argument and allows you to create multiple field definitions for a mapping.

```
builder.create( function( mapping ) {
    mapping.text( "city" ).fields( function( mapping ) {
        mapping.keyword( "raw" );
    } );
} );
```

## Partials

The Mapping Blueprint also has a way to reuse mappings.  Say for instance you have a `user` mapping that gets repeated for managers as well.

The partial method accepts three different kinds of arguments:
1. A closure
1. A component with a `getPartial` method
1. A WireBox mapping to a component with a `getPartial` method

```
var partialFn = function( mapping ) {
    return mapping.object( "user", function( mapping ) {
        mapping.integer( "age" );
        mapping.object( "name", function( mapping ) {
            mapping.text( "first" );
            mapping.text( "last" );
        } );
    } );
};

builder.create( function( mapping ) {
    mapping.partial( "manager", partialFn );
    mapping.partial( definition = partialFn ); // uses the partial's defined name, `user` in this case
} );
```

The first approach is great for partials that are reused in the same index.
The second two approaches work better for partials that are reused across indexes.

#### Reindexing

On occassion, due to a mapping or settings change, you will need to reindex data
from one index to another.  You can do this by calling the `reindex` method
on the `Client`.

```
getInstance( "Client@cbElasticsearch" )
    .reindex( "oldIndex", "newIndex" );
```

If you want the work to be done asynchronusly, you can pass `false` to the
`waitForCompletion` flag.  When this flag is set to false the method will return a [`Task` instance](Tasks.md), which can be used to follow up on the completion status of the reindex process.

```
getInstance( "Client@cbElasticsearch" )
    .reindex(
        source = "oldIndex",
        destination = "newIndex",
        waitForCompletion = false
    );
```

If you have more settings or constraints for the reindex action, you can pass
a struct containing valid options to `source` and `destination`.

```
getInstance( "Client@cbElasticsearch" )
    .reindex(
        source = {
            "index": "oldIndex",
            "type": "testdocs",
            "query": {
                "term": {
                    "active": true
                }
            }
        },
        destination = "newIndex"
    );
```

You may also pass a script in to the reindex method to transform objects as they are being transferred from one index to another:

```
getInstance( "Client@cbElasticsearch" )
    .reindex(
        source = {
            "index": "oldIndex",
            "type": "testdocs",
            "query": {
                "term": {
                    "active": true
                }
            }
        },
        destination = "newIndex",
        script = {
            "lang" : "painless",
            "source" : "if( ctx._source.foo != null && ctx._source.foo == 'baz' ){ ctx._source.foo = 'bar'; }"
        }
    );
```

If you `waitForCompletion` and the reindex action fails, a `cbElasticsearch.JestClient.ReindexFailedException`
will be thrown.  You can disable the exception by passing `false` to the `throwOnError` parameter.
