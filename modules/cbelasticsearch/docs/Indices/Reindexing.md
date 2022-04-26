---
description: Sometimes indices get messy. Learn how to reindex your data in CBElasticsearch.
---

# Reindexing

On occasion, due to a mapping or settings change, you will need to reindex data
from one index (the "source") to another (the "destination"). You can do this by calling the `reindex` method on CBElasticsearch's `Client` component.

```js
getInstance( "Client@cbElasticsearch" )
    .reindex( "oldIndex", "newIndex" );
```

## Asynchronous Reindexing

If you want the work to be done asynchronusly, you can pass `false` to the `waitForCompletion` flag. When this flag is set to false the method will return a [`Task` instance](../Tasks.md), which can be used to follow up on the completion status of the reindex process.

```js
getInstance( "Client@cbElasticsearch" )
    .reindex(
        source = "oldIndex",
        destination = "newIndex",
        waitForCompletion = false
    );
```

## Additional Reindex Options

If you have more settings or constraints for the reindex action, you can pass a struct containing valid options to `source` and `destination`.

```js
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

## Transforming Documents via a Reindex Script

You may also pass a script in to the `reindex` method to transform objects as they are being transferred from one index to another:

```js
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

## Handling Reindex Errors

If you `waitForCompletion` and the reindex action fails, a `cbElasticsearch.HyperClient.ReindexFailedException` will be thrown. You can disable the exception by passing `false` to the `throwOnError` parameter:

```js
getInstance( "Client@cbElasticsearch" )
    .reindex(
        source = "oldIndex",
        destination = "newIndex",
        waitForCompletion = false,
        throwOnError = false
    );
```

{% hint style="info" %}
As always, check out the Elasticsearch documentation for more specifics on [what reindexing is and how it works](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html).
{% endhint %}