---
description: Learn how to define an Elasticsearch index mapping using the fluent MappingBuilder syntax in CBElasticsearch
---

# Mapping Builder

Introduced in `v1.0.0`, the MappingBuilder model provides a fluent closure-based sytax for defining and mapping indexes. This builder can be accessed by injecting it into your components:

```js
component {
    property name="builder" inject="MappingBuilder@cbElasticSearch";
}
```

The `new` method of the `IndexBuilder` also accepts a closure as the second (`properties`) argument. If a closure is passed, a `MappingBuilder` instance is passed as an argument to the closure:

```js
indexBuilder.new( "elasticsearch", function( builder ) {
    return {
        "_doc" = builder.create( function( mapping ) {
            mapping.text( "title" );
            mapping.date( "createdTime" ).format( "date_time_no_millis" );
        } )
    };
} );
```

The `MappingBuilder` has one primary method: `create`. `create` takes a callback with a `MappingBlueprint` object, usually aliased as `mapping`.

## Mapping Blueprint

The `MappingBlueprint` gives a fluent api to defining a mapping. It has methods for all the ElasticSearch mapping types:

```js
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

As seen above, `object` expects a closure which will be provided another `MappingBlueprint`. The results will be set as the `properties` of the `object` call.

## Parameters

Parameters can be chained on to a mapping type. Parameters are set using `onMissingMethod` and will use the method name (as snake case) as the parameter name and the first argument passed as the parameter value.

```js
builder.create( function( mapping ) {
    mapping.text( "title" ).fielddata( true );
    mapping.date( "createdTime" ).format( "date_time_no_millis" );
} )
```

> You can also add parameters using the `addParameter( string name, any value )` or `setParameters( struct map )` methods.

The only exception to the parameters functions is `fields` which expects a closure argument and allows you to create multiple field definitions for a mapping.

```js
builder.create( function( mapping ) {
    mapping.text( "city" ).fields( function( mapping ) {
        mapping.keyword( "raw" );
    } );
} );
```

## Reuse Mapping bits with "Partials"

The Mapping Blueprint also has a way to reuse mappings. Say for instance you have a `user` mapping that gets repeated for managers as well.

The partial method accepts three different kinds of arguments:

1. A closure
1. A component with a `getPartial` method
1. A WireBox mapping to a component with a `getPartial` method

The first approach is a simple way to reuse a mapping partials in the same index.
The second two approaches work better for partials that are reused across multiple indices.

```js
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
