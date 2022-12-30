---
description: Learn how to transform incoming data in an Elasticsearch Ingest Pipeline.
---

# Ingest Pipelines

Elasticsearch allows you to create pipelines which pre-process inbound documents and data.  Methods are available to create, read, update and delete pipelines.  For more information on defining processors, conditionals and options see the (PUT Pipeline)[https://www.elastic.co/guide/en/elasticsearch/reference/master/put-pipeline-api.html] and (Processor)[https://www.elastic.co/guide/en/elasticsearch/reference/master/ingest-processors.html] documentation.


## Creating a Pipeline

Let's say we want to automatically set a field on a document when we save it. We can add a processor on the ingest of documents like so:

```js
var myPipeline = getInstance( "Pipeline@cbelasticsearch" ).new( {
						"id" : "foo-pipeline",
						"description" : "A test pipeline",
						"version" : 1,
						"processors" : [
							{
								"set" : {
									"if" : "ctx.foo == null",
									"field" : "foo",
									"value" : "bar"
								}
							}
						]
					} );
```

With this pipeline, if a value of `foo` is not defined ( note that `ctx` is the document reference in the `if` conditional ) in the inbound document, then the value of that field will automatically be set to `'bar'`.

We can save/apply this pipeline in one of two ways.

Through the pipeline object:

```js
myPipeline.save();
```

Or through the client:

```js
getInstance( "Client@cbElasticsearch" ).applyPipeline( myPipeline );
```

Note that if you are using a [secondary cluster](Configuration.md), you will need to perform your CRUD operations through the client, as the `save` method in the pipeline object will route through the top level client. 

## Retrieving pipeline definitions

If we know the name of our pipeline, we can retreive the definition from Elasticsearch by using the `getPipeline` method of the client: 

```js
getInstance( "Client@cbElasticsearch" ).getPipeline( "foo-pipeline" );
```

If we need to retreive the definitions of all configured pipelines we can call the `getPipelines` method:

```js
getInstance( "Client@cbElasticsearch" ).getPipelines();
```


## Updating a Pipeline

We can modify pipelines using the pipeline object, as well. Let's do this by retrieving the existing pipeline, updating and then saving it:

```js
var pipeline = getInstance( "Pipeline@cbElasticsearch" )
				.new( getInstance( "Client@cbElasticsearch" )
				.getPipeline( "foo-pipeline" ) );

pipeline.addProcessor(
    {
        "set" : {
            "if" : "ctx.foo == 'baz'",
            "field" : "foo",
            "value" : "bar"
        }
    }
).save();
```

Now we've added a processor stating that if our `foo` value is `baz`, set it to `bar`.  Newly saved/ingested documents using this pipeline will never have a value of `baz` for the `foo` key.

## Deleting a Pipeline

We can delete a pipeline by using the identifier, or by passing the wildcard `*`, which delete all configured ingest pipelines on the server. 

```js
getInstance( "Client@cbElastisearch" )
	.deletePipeline( "foo-pipeline" );
```

## Using pipelines When Saving Documents

Pipelines may be used when saving individual or multiple documents. See the [Documents](Documents.md) section for more information on document creation.

To save an individual document, with pipeline processing:

```js
myDocument.setPipeline( 'foo-pipeline' ).save();
```

For multiple documents, the pipeline may be set in the document, prior to the `saveAll` call.  Note, however, that all documents provided in the bulk save must share the same pipeline, as elasticsearch does not support multiple pipelines in bulk saves.  Attempting to save multiple documents with different pipelines will throw an error. Alternately, you may pass the pipeline in as a param to the `saveAll` call:

```js
getInstance( "Client@cbElasticsearch" )
	.saveAll( documents=myDocuments, params={ "pipeline" : "foo-pipeline" } );
```