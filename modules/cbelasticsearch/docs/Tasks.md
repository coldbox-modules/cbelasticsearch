Elasticsearch Tasking
====================


When performing bulk operations - [reindexing](Indexes.md), [query-based updating or deletions](Documents.md) - a parameter may be provided which allows the job to run in a non-blocking manner.  The method that Elasticsearch uses to monitor the completion of these jobs is called a [task](https://www.elastic.co/guide/en/elasticsearch/reference/current/tasks.html).  In the `reindex`, `updateByQuery`, and `deleteByQuery` methods of the client, the argument `waitForCompletion` may be passed.  When set to false a `Task` object can be returned which will provide the status of the task and allow you to refresh through completion.


An example, using the reindex method and flushing the status output to the browser, might look something like:

```
var oldIndex = "books_v1";
var newIndex = "books_v2";
var reindexTask = getInstance( "Client@cbElasticsearch" )
                        .reindex(
                            source = oldIndex,
                            destination = newIndex,
                            waitForCompletion = false,
                            params = {
                                // throttle our reindexing tasks to ensure we don't kill the ES server on a big index - https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-throttle
                                "requests_per_second" : 50,
                                // slice the reindex to concurrent 5 batches at a time - https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-automatic-slice
                                "slices" : 5
                            }
                        );

while( !reindexTask.isComplete() ){
    var status = reindexTask.getStatus();
    writeOutput( "Waiting for task to complete.  #status.created# documents of #status.total# documents have been migrated to #newIndex#" );
    flush();
}
```

The `isComplete` method also accepts an argument of `delay` to slow down the rate at which it re-checks the completion of the task.  Using the above example, we could check only every 5 seconds by passing 5000 milliseconds as the `delay` argument:

```
while( !reindexTask.isComplete( delay=5000 ) ){
    var status = reindexTask.getStatus();
    writeOutput( "<p>Waiting for task to complete.  #status.created# documents of #status.total# documents have been migrated to #newIndex#.</p>" );
    flush();
}
```

At time a reindex process may be marked as complete, but the documents were not transfered. If this happens ( e.g. `getStatus().total != getStatus().created` ), or the `reindexTask.getStatus().total` count is not the correct number of documents in your index, you can inspect the content of `reindexTask.getResponse()` to determine the reindexing errors.

When managing large indexes, a task-based approach to bulk operations can allow you to optimize the resource usage of both your Elasticsearch and CFML Application servers.