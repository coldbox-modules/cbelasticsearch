# Fluent Query Placement Control - BooleanQueryBuilder

This enhancement adds fluent convenience methods for precise control of query item placement within boolean query structures.

## Problem Statement

Previously, users had to manually manipulate query structures for precise placement:

```coldfusion
var q = search.getQuery();
param q.bool = {};
param q.bool.filter = {};
param q.bool.filter.bool.must = [];
arrayAppend( q.bool.filter.bool.must, {
    "wildcard" : {
        "fieldName" : {
            "value" : "queryValue"
        }
    }
} );
```

## Solution

The new fluent API allows intuitive query building:

```coldfusion
// Same result as manual approach above:
search.bool().filter().bool().must().wildcard( "fieldName", "queryValue" );

// Other examples:
search.must().term( "status", "active" );
search.should().match( "title", "elasticsearch" );
search.filter().range( "price", gte = 10, lte = 100 );
search.mustNot().exists( "deletedAt" );
```

## Available Methods

### Entry Points from SearchBuilder
- `bool()` - Creates boolean query context at `query.bool`
- `must()` - Direct access to `query.bool.must[]`
- `should()` - Direct access to `query.bool.should[]` 
- `mustNot()` - Direct access to `query.bool.must_not[]`
- `filter()` - Direct access to `query.bool.filter`

### Chaining Methods in BooleanQueryBuilder
- `bool()` - Add nested boolean context
- `must()` - Add must array context
- `should()` - Add should array context  
- `mustNot()` - Add must_not array context
- `filter()` - Add filter context

### Query Methods (return SearchBuilder for continued chaining)
- `term( name, value, [boost] )` - Exact term match
- `terms( name, values, [boost] )` - Multiple term matches
- `match( name, value, [boost] )` - Full-text match
- `wildcard( name, pattern, [boost] )` - Wildcard pattern match
- `range( name, [gte], [gt], [lte], [lt], [boost] )` - Range query
- `exists( name )` - Field existence check

## Complex Query Examples

### Nested Boolean Logic
```coldfusion
// Creates: query.bool.filter.bool.should[]
search.bool().filter().bool().should()
    .match( "title", "elasticsearch" )
    .match( "description", "search engine" );
```

### Mixed Query Types
```coldfusion
search
    .must().term( "status", "published" )
    .should().match( "title", "important" )
    .filter().range( "publishDate", gte = "2023-01-01" )
    .mustNot().exists( "deletedAt" );
```

### Deeply Nested Structures
```coldfusion
// Equivalent to: query.bool.must[].bool.filter.bool.should[]
search.bool().must().bool().filter().bool().should()
    .wildcard( "tags", "*elasticsearch*" );
```

## Backward Compatibility

All existing SearchBuilder methods continue to work unchanged:

```coldfusion
// Old API still works
search.mustMatch( "title", "test" );
search.filterTerm( "status", "active" );

// Can be mixed with new API
search.mustMatch( "title", "test" )
    .must().term( "category", "tech" );
```

## Generated Query Structures

The fluent API generates standard Elasticsearch query DSL:

```json
{
  "query": {
    "bool": {
      "must": [
        { "term": { "status": "active" } }
      ],
      "should": [
        { "match": { "title": "elasticsearch" } }
      ],
      "filter": {
        "range": {
          "price": { "gte": 10, "lte": 100 }
        }
      },
      "must_not": [
        { "exists": { "field": "deletedAt" } }
      ]
    }
  }
}
```

This enhancement significantly improves the developer experience for building complex Elasticsearch queries while maintaining full backward compatibility.