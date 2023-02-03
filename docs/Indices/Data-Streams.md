---
description: Learn How to use Data Streams for time series data
---

# Data Streams

Since v7 Elasticsearch offers the ability to use Data streams for time series or rotational data.  A data stream uses an [Index Template](Templates.md) to automatically create backing indices for the data.  Depending on the [lifecycle configuration](Index-Lifecycles.md), data may be rotated out to separate indices, snapshots or deleted altogether.  Because the creation of a data stream requires a number of dependencies to be created, the process of implementing is a bit more complex.  The steps, in order would be:

1.  Create a lifecycle policy for your data stream
2.  Create one or more [component templates](Templates.md) for your data stream index mappings/settings. You may also use pre-configured system templates, like log settings, when applicable.
3.  Create an [index template](Templates.md) using your component template(s)
3.  Create your data stream - either manually, or by pushing data


Let's take a look at what this might look like for a new logging data stream.  The [built in Log appender](../Logging.md) for this module, if you want to see a more in-depth example.

## Create a lifecycle policy

We will create a policy to:

1. Start with 2 shards in the "hot" phase ( new data ) and force rollover of old data if any shard grows to more than 1GB
2. Transition to the "warm" phase at 7 days, shrink to 1 shard and make the backing index for the phase read-only.
3. Delete the data after 60 days

```js
var policyBuilder = getInstance( "ILMPolicyBuilder@cbelasticsearch" )
                        .new( "my-new-policy" )
                        .hotPhase( shards = 2, rollover = "1gb" )
                        .warmPhase( age=7, shards = 1, readOnly = true )
                        .withDeletion( age = 60 )
                        .save();
```

## Create a component template

Next we'll create a component template to  handle some custom fields and settings in our logs, as well as to assign index templates which use it to the lifecycle policy created above.

```js
var mappings = getInstance( "MappingBuilder@cbelasticsearch" )
                    .create( function( mapping ){
                        mapping.date( "@timestamp" );
                        mapping.object( "event", function( mapping ){
                            mapping.text( "message" );
                            mapping.keyword( "application" );
                            mapping.keyword( "version" );
                        } );
                    } );
getInstance( "Client@cbelasticsearch" ).applyComponentTemplate(
    "my-component-template",
    { 
        "template" :{
            "settings" : {
                    "index.lifecycle.name"   : "my-new-policy"
            },
            "mappings" : mappings.toDSL()
        }
    }
);
```

## Create an index template

Now we'll create an index template to use our component template, as well as the built-in logging templates in Elasticsearch

```js
getInstance( "Client@cbelasticsearch" ).applyIndexTemplate(
    // the index template name
    "my-index-template",
    {
        // The pattern of the inbound index to apply this template. Only applies the template to newly created indices
        "index_patterns" : [ "my-index-*" ],
        "composed_of" : [
            // built-in templates
            "logs-mappings",
            "data-streams-mappings",
            "logs-settings", 
            // custom template
            "my-component-template" 
        ],
        // The presence of this key creates a data stream for any matching index pattern.
        "data_stream" : {},
        // A priority - allows you to prioritize the order in which templates are applied with similar patterns
        "priority" : 150,
        // An optional struct of arbitrary meta information for the template
        "_meta" : {
            "description" : "My data stream index template"
        }
    }
);
```

### Create our data stream

Now we can create our data stream in one of two ways. We can either send data to an index matching the pattern or we can create it manually.  Let's do both:

Create a data stream manually without data:
```js
getInstance( "Client@cbElasticsearch" ).ensureDataStream( "my-index-foo" );
```
This will create the data stream and backing indices for the data stream named `my-index-foo`.  

Create a data stream by adding data
```js
getInstance( "Document@cblasticsearch" )
        .new( "my-index-bar" )
        .populate(
            {
                "@timestamp" : now(),
                "event" : {
                    "message" : "This is a new event!",
                    "application" : "MyApplicationName",
                    "version" : 1.0.0
                }
            }
        ).create();
```
This will create the data stream and backing indices for the data stream named `my-index-bar`.


Data streams can be a powerful way to ensure that time series data remains relevant and purges itself when there is no longer a need for it. You can also use data streams for a mapping change between versions of your application indices. 


