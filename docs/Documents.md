---
description: Learn how to create and manage Elasticsearch document records using CBElasticsearch
---

# Managing Documents

Documents are the searchable, serialized objects within your indexes.  As noted above, documents may be assigned a type, allowing separation of schema, while still maintaining searchability across all documents in the index.   Within an index, each document is referenced by an `_id` value.  This `_id` may be set manually ( `document.setId()` ) or, if not provided will be auto-generated when the record is persisted.  Note that, if using numeric primary keys for your `_id` value, they will be cast as strings on serialization.

#### Creating a Document

The `Document` model is the primary object for creating and working with Documents.  Let's say, again, we were going to create a new document in our index.  We would do so, by first creating a `Document` object.

```js
var book = getInstance( "Document@cbelasticsearch" ).new(
    index = "bookshop",
    type = "_doc",
    properties = {
        "title" = "Elasticsearch for Coldbox",
        "summary" = "A great book on using Elasticsearch with the Coldbox framework",
        "description" = "A long descriptio with examples on why this book is great",
        "author" = {
            "id" = 1,
            "firstName" = "Jon",
            "lastName" = "Clausen"
        },
        // date with specific format type
        "publishDate" = dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" ),
        "edition" = 1,
        "ISBN" = 123456789054321
    }
);

book.save();
```

In addition to population during the new method, we could also populate the document schema using other methods:

```js
document.populate( myBookStruct )
```

or by individual setters:

```js
document.setValue(
    "author",
    {
        "firstName" = "Jon",
        "lastName" = "Clausen"
    }
);
```

If we want to manually assign the `_id` value, we would need to explicitly call `setId( myCustomId )` to do so, or would need to provide an `_id` key in the struct provided to the `new()` or `populate()` methods.

#### Retrieving documents

To retrieve an existing document, we must first know the `_id` value.  We can either retrieve using the `Document` object or by interfacing with the `Client` object directly.  In either case, the result returned is a `Document` object, i f found, or null if not found.

Using the `Document` object's accessors:

```js
var existingDocument = getInstance( "Document@cbelasticsearch" )
    .setIndex( "bookshop" )
    .setType( "_doc" )
    .setId( bookId )
    .get();
```

Calling the `get()` method with explicit arguments:

```js
var existingDocument = getInstance( "Document@cbelasticsearch" )
    .get(
        id = bookId,
        index = "bookshop",
        type = "_doc"
    );
```

Calling directly, using the same arguments, from the client:

```js
var existingDocument = getInstance( "Client@cbelasticsearch" )
    .get(
        id = bookId,
        index = "bookshop",
        type = "_doc"
    );
```

The `get` method also accepts a struct of [query parameters](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-get.html#docs-get-api-query-params) to pass to the document retrieval request.  For example, we only want certain items returned in the document JSON, we can pass a `_source_includes` query parameter:

```js
var minimal = getInstance( "Client@cbelasticsearch" )
    .get(
        id = bookId,
        index = "bookshop",
        type = "_doc",
        params = {
            "_source_includes" : "_id,title"
        }
    );
```

This will bring back only the identifier and title in the retrieved document. [A list of available query parameters may be found here](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-get.html#docs-get-api-query-params).

#### Updating a Document

Once we've retrieved an existing document, we can simply update items through the `Document` instance and re-save them.

```js
existingDocument.populate( properties = myUpdatedBookStruct ).save()
```

You can also pass Document objects to the `Client`'s `save()` method:

```js
getInstance( "Client@cbelasticsearch" ).save( existingDocument );
```

#### Save Documents with an Index Refresh

If you need your document available immediately (such as during a test or pipeline), you can pass `refresh = true` to [instruct Elasticsearch to refresh the relevant index shard immediately and synchronously](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-refresh.html):

```js
getInstance( "Client@cbelasticsearch" ).save(
    document = existingDocument,
    refresh = true
);
```

The refresh parameter also accepts a `wait_for` option, which tells Elasticsearch to wait until the next index refresh:

```js
getInstance( "Client@cbelasticsearch" ).save(
    document = existingDocument,
    refresh = "wait_for"
);
```

#### Updating individual document fields

The `patch` method of the Client allows a user to update select fields, bypassing the need for a fully retrieved document.  This is similar to an `UPDATE foo SET bar = 'xyz' WHERE id = :id` query on a relational database.  The method requires an index name, identifier and a struct containing the keys to be updated:

```js
getInstance( "Client@cbelasticsearch" ).patch( 
    "bookshop",
    bookId,
    {
        "title"  : "My Book Title - 1st Edition"
    }
);
```

Nested keys can also be updated using dot-notation:

```js
getInstance( "Client@cbelasticsearch" ).patch(
    "bookshop",
    bookId,
    {
        "author.firstName"  : "Jonathan"
    }
);
```

#### Processing Bulk Operations

Elasticsearch allows to you perform [bulk operations](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html), which allows a developer to queue multiple backend operations on the search indices and send them all at once.  The `processBulkOperation` method allows you to send a payload of operations in one batch. Note that create, update, and index actions require a `source` key, where as `delete` methods only require an `operation` key.  The schema of the `source` key follows the same schema's described in the [Bulk API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html):

```js
var ops = [
    {
        "operation" : { "update" :  { "_index" : "bookshop", "_id" : "xyz" } },
        "source" : {
            "doc" : { "title" : "My Book Title - 1st Edition" }
        }
    },
    {
        "operation" : { "delete" : { "_index" : "otherindex", "_id" : "abc" } }
    },
    {
        "operation" : { "update" : { "_index" : "bookshop", "_id" : "efg" } }
        "source" : {
            "doc" : {
                "title" = "Elasticsearch for Coldbox - 2nd Edition",
                "summary" = "A new version of the original great book on using Elasticsearch with the Coldbox framework",
                "description" = "A long description with examples on why this book is great",
                "author" = {
                    "id" = 1,
                    "firstName" = "Jon",
                    "lastName" = "Clausen"
                },
                // date with specific format type
                "publishDate" = dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" ),
                "edition" = 1,
                "ISBN" = 123456789054321
            },
            "doc_as_upsert" : true
        }
    }
];

getInstance( "Client@cbelasticsearch" ).processBulkOperation( ops, { "refresh" : true } );
```

#### Bulk Saving of Documents

Builk inserts and updates can be peformed by passing an array of `Document` objects to the Client's `saveAll()` method:

```js
var documents = [];

for( var myStruct in myArray ){
    var document = getInstance( "Document@cbelasticsearch" ).new(
        index = myIndex,
        type = myType,
        properties = myStruct
    );

    arrayAppend( documents, document );
}

getInstance( "Client@cbelasticsearch" ).saveAll( documents );
```


### Update by Query

For advanced updates to documents in the index, the `updateByQuery` method can provide a powerful way to make bulk transformations on documents in your index.  The `updateByQuery` method requires the passing of a "script" argument, which is a struct containing two strings - the language and the script. Elasticsearch [supports a number of languages](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-scripting.html) however, most of the time, the "painless" language is the easiest choice.

Let's say, for example, that you need to add a new key, with a default value, to every document in your index where the key does not already exist:

```js
var searchBuilder = getInstance( "SearchBuilder@cbelasticsearch" )
                        .mustNotExist( "isInPrint" );
getInstance( "Client@cbelasticsearch" )
            .updateByQuery(
                searchBuilder,
                {
                    "lang" : "painless"
                    "script" : "ctx._source.isInPrint = true"
                }
            );
```

In the above case, we queried for a lack of existence on the `isInPrint` key and created all documents which matched to use a default value of `false`.

Note the variable `ctx._source` used in the script, which is a reference to the document being iterated in the update loop.  More information on crafting complex, scripted, query-based updates can be found in [the official elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update-by-query.html).

Note that a Painless script containing newlines, tabs, or space indentation will throw a parsing error. To work around this limitation, use CBElasticsearch's `Util.formatToPainless( string script )` method to remove newlines and indentation:

```js
getInstance( "Client@cbelasticsearch" )
            .updateByQuery(
                searchBuilder,
                {
                    "lang" : "painless",
                    "script" : getInstance( "Util@cbelasticsearch" )
                                .formatToPainless( getReindexScript() )
                }
            );
```


#### Deleting a Document

Deleting documents is similar to the process of saving.  The `Document` object may be used to delete a single item.

```js
var document = getInstance( "Document@cbelasticsearch" )
    .get(
        id = documentId,
        index = "bookshop",
        type = books
    );
if( !isNull( document ) ){
    document.delete();
}
```

Documents may also be deleted by passing a `Document` instance to the client:

```js
getInstance( "Client@cbelasticsearch" ).delete( myDocument );
```

Finally, documents may also be deleted by query, using the `SearchBuilder` ( more below ):

```js
getInstance( "SearchBuilder@cbelasticsearch" )
    .new( index="bookshop", type="books" )
    .match( "name", "Elasticsearch for Coldbox" )
    .deleteAll();
```

### Parameters

The search builder also supports the addition of URL parameters, which may be used to transform or modify the behavior of bulk document actions.  Comprehensive lists of these parameters may be found at the official Elasticsearch docs:

* [Update by Query](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update-by-query.html#_url_parameters)
* [Delete by Query](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html)

Of note are the throttling parameters, which are useful in dealing with large documents and/or indices.  By default elasticsearch processes batch operations in groups of 1000 documents.  Depending on the size of your documents and the collection, it may be preferable to throttle the batch to a smaller number of documents per batch:

```js
getInstance( "SearchBuilder@cbelasticsearch" )
    .new( index="bookshop", type="books" )
    .match( "name", "Elasticsearch for Coldbox" )
    .param( "scroll_size", 100 )
    .deleteAll();
```

#### Asynchronous Bulk Operations

Both the `updateByQuery` and `deleteByQuery` methods support a `waitForCompletion` argument. By default, this is set to `true`.  When passed as false, however, the method will return a [`Task` instance](Tasks.md), which can be used to follow up on the completion status of the action process. 

{% hint style="info" %}
You may also provide this argument in the SearchBuilder Params ( see "Parameters" above ): `searchBuilder.param( 'wait_for_completion', false )`, in lieu of providing the argument to the action.  The end result is the same.
{% endhint %}