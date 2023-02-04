---
description: Learn How to Create Index and Component templates to Ensure Data Mappings
---

# Index Templating

Index templates provide a way to ensure your indices are mapped correctly upon creation.  You may control both settings and individual field mappings within your documents. 

{% hint style="info" %}Check out the [Elasticsearch "Index Templates" documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-templates.html) for further reading on this subject.{% endhint %}

## Component Templates

In order to map your indices, you must first create a [component template](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-component-template.html) which includes your mappings and (optionally) settings for the index. You may use the [Mapping Builder](Mapping-Builder.md) to create your mapping DSL or provide it in the form of a DSL struct. 

```js
var mappings = getInstance( "MappingBuilder@cbelasticsearch" )
                    .create( function( mapping ){
                        mapping.keyword( "id" );
                        mapping.text( "description" );
                        mapping.date( "@timestamp" );
                        mapping.object( "meta", function( mapping ){
                            mapping.date( "createdTime" ).format( "date_time_no_millis" );
                            mapping.date( "modifiedTime" ).format( "date_time_no_millis" );
                            mapping.text( "changelog" );
                            mapping.keyword( "createdBy" );
                            mapping.keyword( "modifiedBy" );
                        } );
                    } );

getInstance( "Client@cbelasticsearch" ).applyComponentTemplate(
    "my-component-template",
    { 
        "template" :{
            "settings" : {
                    "index.refresh_interval" : "5s",
                    "number_of_replicas"     : 0,
                    "number_of_shards"       : 1,
                    "index.lifecycle.name"   : "my-lifecycle-policy"
            },
            "mappings" : mappings.toDSL()
        }
    }
);
```

Additional methods are available for managing component templates:

* `getInstance( "Client@cbelasticsearch" ).componentTemplateExists( [ template name] )`
* `getInstance( "Client@cbelasticsearch" ).getComponentTemplate( [ template name] )`
* `getInstance( "Client@cbelasticsearch" ).deleteComponentTemplate( [ template name] )`

Note that a component template may not be deleted if it is in use by an Index template.  In order to delete it, you must first delete the index template.

## Index Templates

Now that we have created a component template, we can use it in an [Index template](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-templates.html).  Index templates define a matching index ( or Data Stream ) name pattern to which any new indexes created with this naming pattern will have the template applied.  Multiple component templates may be used in an array.

Note, that if a `data_stream` key is provided in the definition, any writes to a matching index pattern will be created as a data stream.

```js
getInstance( "Client@cbelasticsearch" ).applyIndexTemplate(
    // the index template name
    "my-index-template",
    {
        // The pattern of the inbound index to apply this template. Only applies the template to newly created indices
        "index_patterns" : [ "my-index-*" ],
        "composed_of" : [
            // some other component template
            "other-component-template",
            "my-component-template" 
        ],
        // The presence of this key creates a data stream for any matching index pattern. If it is absent an index will be created when data is received
        "data_stream" : {},
        // A priority - allows you to prioritize the order in which templates are applied with similar patterns
        "priority" : 150,
        // An optional struct of arbitrary meta information for the template
        "_meta" : {
            "description" : "My global index template"
        }
    }
);
```
All Component and Index template updates are applied as _upsert_ operations - meaning that the `@version` key will be incremented if a new version of a template is applied.

Additional methods are available for managing idnex templates:

* `getInstance( "Client@cbelasticsearch" ).indexTemplateExists( [ template name] )`
* `getInstance( "Client@cbelasticsearch" ).getIndexTemplate( [ template name] )`
* `getInstance( "Client@cbelasticsearch" ).deleteIndexTemplate( [ template name] )`

Note that an index template may not be deleted if it is in use by a data stream.  In order to delete it, you must first delete any data streams which use the template or modify the template used in that data stream.

