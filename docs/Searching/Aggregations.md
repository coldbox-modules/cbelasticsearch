---
description: Learn how to summarize or "aggregate" data with cbElasticsearch
---

# Aggregations

In some cases, you aren't interested in searching documents as you are in retrieving specific information stored within each document. It is for such a purpose that Elasticsearch provides the ability to aggregate, or summarize, index data.

## Creating an Aggregation

cbElasticsearch's `SearchBuilder` provides an `aggregation()` method for simple aggregation definitions:

```js
searchBuilder.aggregation( string name, struct options )
```

## Max Aggregation

Here's an example of a [max aggregation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-max-aggregation.html) using SearchBuilder:

```js
searchBuilder.aggregation( "last_updated", { "max": { "field": "meta.timestamp" } } )
```

This aggregation will retrieve the most recent date value stored in `meta.timestamp`.

## Terms Aggregation

Use a terms aggregation to return an array of term "buckets", one per value:

```js
searchBuilder.aggregation( "movie_genres", { "terms": { "field": "genre" } } )
```

## Working with Aggregations

To run the query and retrieve aggregations, call `searchBuilder.execute()` followed by `getAggregations()`. `getAggregations()` will return a key/value struct where the key is your provided aggregation name:

```js
var data = mySearch.aggregation( "last_updated", { "max": { "field": "meta.timestamp" } } )
                    .execute()
                    .getAggregations()[ "last_updated" ];
```

For a simple metrics aggregation, you should be able to use the `value` or `value_as_string` keys of the returned aggregation:

```js
function getLastUpdateTime(){
    var aggregation = getSearchBuilder()
                        .new( "exams" )
                        .aggregation( "last_updated", { "max": { "field": "meta.timestamp" } } )
                        .execute()
                        .getAggregations();
                
    return aggregation[ "last_updated" ][ "value_as_string" ];
}
```

In contrast, bucket aggregations return a `buckets` array which can be used as-is or mapped into a separate result entirely:

```js
function getMovieGenres(){
    var aggregations = getSearchBuilder()
                        .new( "exams" )
                        .aggregation( "genres", { "terms": { "field": "genre" } })
                        .execute()
                        .getAggregations();
                
    return aggregations[ "genres" ].buckets.map( ( term ) => term.key );
}
```

{% hint style="info" %}
For a full break down on aggregations, check out the [ElasticSearch aggregation reference](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html).
{% endhint %}