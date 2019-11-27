Managing Documents
==================

Documents are the searchable, serialized objects within your indexes.  As noted above, documents may be assigned a type, allowing separation of schema, while still maintaining searchability across all documents in the index.   Within an index, each document is referenced by an `_id` value.  This `_id` may be set manually ( `document.setId()` ) or, if not provided will be auto-generated when the record is persisted.  Note that, if using numeric primary keys for your `_id` value, they will be cast as strings on serialization.

#### Creating a Document

The `Document` model is the primary object for creating and working with Documents.  Let's say, again, we were going to create a `book` typed document in our index.  We would do so, by first creating a `Document` object.

```
var book = getInstance( "Document@cbElasticsearch" ).new(
    index = "bookshop",
    type = "book",
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
        "publishDate" = dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" ),
        "edition" = 1,
        "ISBN" = 123456789054321
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
        "firstName" = "Jon",
        "lastName" = "Clausen"
    }
);
```

If we want to manually assign the `_id` value, we would need to explicitly call `setId( myCustomId )` to do so, or would need to provide an `_id` key in the struct provided to the `new()` or `populate()` methods.

#### Retrieving documents

To retrieve an existing document, we must first know the `_id` value.  We can either retrieve using the `Document` object or by interfacing with the `Client` object directly.  In either case, the result returned is a `Document` object, i f found, or null if not found.

Using the `Document` object's accessors:

```
var existingDocument = getInstance( "Document@cbElasticsearch" )
    .setIndex( "bookshop" )
    .setType( "book" )
    .setId( bookId )
    .get();
```

Calling the `get()` method with explicit arguments:

```
var existingDocument = getInstance( "Document@cbElasticsearch" )
    .get(
        id = bookId,
        index = "bookshop",
        type = "book"
    );
```

Calling directly, using the same arguments, from the client:

```
var existingDocument = getInstance( "Client@cbElasticsearch" )
    .get(
        id = bookId,
        index = "bookshop",
        type = "book"
    );
```

#### Updating a Document

Once we've retrieved an existing document, we can simply update items through the `Document` instance and re-save them.

```
existingDocument.populate( properties = myUpdatedBookStruct ).save()
```

You can also pass Document objects to the `Client`'s `save()` method:

```
getInstance( "Client@cbElasticsearch" ).save( existingDocument );
```

#### Bulk Inserts and Updates

Builk inserts and updates can be peformed by passing an array of `Document` objects to the Client's `saveAll()` method:

```
var documents = [];

for( var myStruct in myArray ){
    var document = getInstance( "Document@cbElasticsearch" ).new(
        index = myIndex,
        type = myType,
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
        id = documentId,
        index = "bookshop",
        type = books
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
getInstance( "SearchBuilder@cbElasticsearch" )
    .new( index="bookshop", type="books" )
    .match( "name", "Elasticsearch for Coldbox" )
    .deleteAll();
```

#### Reindexing

On occassion, due to a mapping or settings change, you will need to reindex data
from one index to another.  You can do this by calling the `reindex` method
on the `Client`.

```
getInstance( "Client@cbElasticsearch" )
    .reindex( "oldIndex", "newIndex" );
```

If you want the work to be done asynchronusly, you can pass `false` to the
`waitForCompletion` flag.

```
getInstance( "Client@cbElasticsearch" )
    .reindex(
        source = "oldIndex",
        destination = "newIndex"
        waitForCompletion = false
    );
```

If you have more settings or constriants for the reindex action, you can pass
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