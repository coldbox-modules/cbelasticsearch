---
description: Learn How to Create Index and Component templates to Ensure Data Mappings
---

# Index Templating

Index templates provide a way to ensure your indices, upon creation are mapped correctly.  You may control both settings and individual field mappings within your documents. 


## Component Templates

In order to map your indices, you must first create a component template which includes your mappings and, optionally, settings for the index. You may use the [Mapping Builder](Mapping-Builder.md) create your mappings DSL or provide it in the form of a DSL struct. 

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

Additional methods are available for retreiving, verifying existence and deleting component templates:

* `getInstance( "Client@cbelasticsearch" ).componentTemplateExists( [ template name] )`
* `getInstance( "Client@cbelasticsearch" ).getComponentTemplate( [ template name] )`
* `getInstance( "Client@cbelasticsearch" ).deleteComponentTemplate( [ template name] )`

Note that a component template may not be deleted if it is in use by an Index template.  In order to delete it, you must first delete the index template.


## Index Templates

Now that we have created a component template, we can use it in an Index template.  Index templates define a matching index ( or Data Stream ) name pattern to which any new indexes created with this naming pattern will have the template applied.  Multiple component templates may be used in an array.

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
            "other-component-template" 
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
All Component and Index template updates are applied as upsert operations - meaning that the `@version` key will be incremented if a new version of a template is applied.

Additional methods are available for retreiving, verifying existence and deleting component templates:

* `getInstance( "Client@cbelasticsearch" ).indexTemplateExists( [ template name] )`
* `getInstance( "Client@cbelasticsearch" ).getIndexTemplate( [ template name] )`
* `getInstance( "Client@cbelasticsearch" ).deleteIndexTemplate( [ template name] )`

Note that an index template may not be deleted if it is in use by a data stream.  In order to delete it, you must first delete any data streams which use the template or modify the template used in that data stream.

