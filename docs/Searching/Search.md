---
description: Learn how to search documents with CBElasticsearch
---

# Searching Documents

The `SearchBuilder` object offers an expressive syntax for crafting detailed searches with ranked results. To perform a simple search for matching documents documents, using Elasticsearch's automatic scoring, we would use the `SearchBuilder` like so:

```js
var searchResults = getInstance( "SearchBuilder@cbelasticsearch" )
    .new( index="bookshop", type="books" )
    .match( "name", "Elasticsearch" )
    .execute();
```

By default this search will return an array of `Document` objects ( or an empty array if no results are found ), with a descending match score as the sort.

To output the results of our search, we would use a loop, accessing the `Document` methods:

```js
for( var resultDocument in searchResults.getHits() ){
    var resultScore     = resultDocument.getScore();
    var documentMemento = resultDocument.getMemento();
    var bookName        = documentMemento.name;
    var bookDescription = documentMemento.description;
}
```

The "memento" is our structural representation of the document. We can also use the built-in method of the Document object:

```js
for( var resultDocument in searchResults.getHits() ){
    var resultScore     = resultDocument.getScore();
    var bookName        = resultDocument.getValue( "name" );
    var bookDescription = resultDoument.getValue( "description" );
}
```

## Search matching


### Exact matching

The `term()` method allows a means of specifying an exact match of all documents in the search results. An example use case might be only to search for active documents:

```js
searchBuilder.term( "isActive", 1 );
```

Or a date:

```js
searchBuilder.term( "publishDate", "2017-05-13" );
```

### Boosting individual matches

The `match()` method of the `SearchBuilder` also allows for a `boost` argument. When provided, results which match the term will be ranked higher in the results:

```js
searchBuilder
    .match( "shortDescription", "Elasticsearch" )
    .match( "description", "Elasticsearch" )
    .match(
        name = "name",
        value = "Elasticsearch",
        boost = 0.5
    );
```
In the above example, documents with a `name` field containing "Elasticsearch" would be boosted in score higher than those which only find the value in the short or long description.


## Wildcards

There are times when you want to be able to match a portion of a `keyword`-mapped field in elasticsearch. The `wildcard` method allows you to do this. Let's say I wanted to match any documents with a `name` key containing `Elastic`. I could use the following method to match those documents:

```js
searchBuilder.keyword( "name", "Elastic" );
```

This would match any documents with a `name` keyword field containing `Elasticsearch` or `Elasticache`. It is important to note that wildcard queries are exceptionally slow, compared to `term`/`must`/`should` queries, as they require recursion through the entire index of document values to obtain their matches.

We can also boost matches and make this a conditional to an existing query:

```js
searchBuilder.shouldMatch( "shortDescription", "Elastic", 1 )
             .wildcard( "name", "Elastic", 5, "should" );
```

In the above query we change the `operator` argument for the wildcard query to "should" to ensure that the match becomes an "or" for the short description or the wildcard. In addition, we boost the wildcard results 5 times above the short description matched results.

## Sorting Results

The `sort()` method also allows you to specify custom sort options. To sort by author last name, instead of score, use:

```js
searchBuilder.sort( "author.lastName", "asc" );
// OR 
searchBuilder.sort( "author.lastName ASC" );
```

While our documents would still be scored, the results order would be changed to the specified alphabetical order on the author's last name.

The `sort()` method also accepts a full sort config:

```js
searchBuilder.sort( "post_date", {
    "order" : "asc",
    "format": "strict_date_optional_time_nanos"
} );
```

Calling `.sort()` multiple times will append the sort configurations to allow fine-tuning the sort order:

```js
searchBuilder.sort( "author.lastName", "asc" );
searchBuilder.sort( "author.age", "DESC" );
```

{% hint style="info" %}
For more information on sorting search results, check out [Elasticsearch: Sort search results](https://www.elastic.co/guide/en/elasticsearch/reference/8.1/sort-search-results.html#sort-search-results)
{% endhint %}

### Paging Through Query Results

The `size` and `from` search options allow adjusting the page size and start row, respectively, of the configured search:

```js
searchBuilder.setFrom( 11 );
searchBuilder.setSize( 10 );
```

The number of matched documents will be in the `SearchResult`'s `getHitCount()` value:

```js
var totalRows = result.getHitCount();
```

{% hint style="info" %}
Be sure to read the [Elasticsearch "Paginate Search Results" documentation](https://www.elastic.co/guide/en/elasticsearch/reference/8.7/paginate-search-results.html), as paging too deeply can adversely affect CPU and memory usage.
{% endhint %}

### Script Fields

SearchBuilder also supports [Elasticsearch script fields](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-fields.html#script-fields), which allow you to evaluate field values at search time for each document hit:

```js
searchBuilder.addScriptField( "interestCost",{
    "script": {
        "lang": "painless",
        "source": "return doc['price'].size() != 0 ? doc['price'].value * (params.interestRate/100): null",
        "params": { "interestRate": 5.5 }
    }
} );
```

This will result in an `"interestCost"` field in the `fields` property on the `Document` object:

```js
var interest = searchBuilder.execute().getHits().map( (document) => document.getFields()["interestCost"] ); // 5.50
```

### Runtime Fields

Elasticsearch also supports defining runtime fields, which are fields defined in the index mapping but populated at search time via a script. You can [define these in the index mapping](../Indices/Managing-Indices.md#creating-runtime-fields), or [define them at search time](#define-runtime-fields-at-search-time).

{% hint style="info" %}
See [Managing-Indices](../Indices/Managing-Indices.md#creating-runtime-fields) for more information on creating runtime fields.
{% endhint %}

Runtime fields can be fetched via the `setFields()` or `addField()` methods, and will appear in the `Document` object's `fields` struct. This example retrieves the `"fuel_usage_in_mpg"` runtime field as well as the indexed `"make"` and `"model"` fields:

```js
var hits = searchBuilder.new( "itinerary" )
             .setFields( [ "fuel_mpg", "make", "model" ] )
             .execute()
             .getHits();
// OR
var hits = searchBuilder.new( "itinerary" )
             .addField( "fuel_mpg" )
             .addField( "make" )
             .addField( "model" )
             .execute()
             .getHits();
```

Once you have a search response, you can use the `.getFields()` method to retrieve the specified fields from the search document:

```js
for( hit in hits ){
    var result = hit.getFields();
    writeOutput( "This #result.make# #result.model# gets #fuel_mpg#/gallon" );
}
```

To access document `fields` as well as the `_source` properties, use`hit.getDocument( includeFields = true)`:

```js
var result = searchBuilder.execute();
for( hit in result.getHits() ){
    var document = document.getDocument( includeFields = true );
    writeOutput( "This #document.make# #document.model# gets #fuel_mpg#/gallon" );
}
```


### Define Runtime Fields At Search Time

Elasticsearch also allows you to [define runtime fields at search time](https://www.elastic.co/guide/en/elasticsearch/reference/current/runtime-search-request.html), and unlike [script fields](#script-fields) these runtime fields are available to use in aggregations, search queries, and so forth.

```js
searchBuilder.addRuntimeMapping( "hasPricing", {
	"type" : "boolean",
	"script": {
		"source": "doc.containsKey( 'price' )"
	}
} );
```

Using `.addField()` ensures the field is returned with the document upon query completion:

```js
searchBuilder.addRuntimeMapping( "hasPricing", ... ).addField( "hasPricing" );
```

We can then retrieve the result field via the `getFields()` method:

```js
var documentsWithPricing = searchBuilder.execute()
	.getHits()
	.filter( (document) => document.getFields()["hasPricing"] );
```

or inlined with the document mento using `hit.getDocument( includeFields = true )`.

### Advanced Query DSL

The SearchBuilder also allows full use of the [Elasticsearch query language](https://www.elastic.co/guide/en/elasticsearch/reference/current/_introducing_the_query_language.html), allowing full configuration of your search queries. There are several methods to provide the raw query language to the Search Builder. One is during instantiation.

In the following we are looking for matches of active records with "Elasticsearch" in the `name`, `description`, or `shortDescription` fields. We are also looking for a phrase match of "is awesome" and are boosting the score of the applicable document, if found.

```js
var search = getInstance( "SearchBuilder@cbelasticsearch" )
    .new(
        index = "bookshop",
        type = "books",
        properties = {
            "query" = {
                "term" = {
                    "isActive" = 1
                },
                "match" = {
                    "name" = "Elasticsearch",
                    "description" = "Elasticsearch",
                    "shortDescription" = "Elasticsearch"
                },
                "match_phrase" = {
                    "description" = {
                        "query" = "is awesome",
                        "boost" = 2
                    }
                }
            }
        }
    )
    .execute();
```

After instantion, you can use the `.param()` and `.bodyParam()` methods to set [query parameters](https://www.elastic.co/guide/en/elasticsearch/reference/8.7/search-search.html#search-search-api-query-params) and [body parameters](https://www.elastic.co/guide/en/elasticsearch/reference/8.7/search-search.html#search-search-api-request-body), respectively.

```js
var response = getInstance( "SearchBuilder@cbelasticsearch" )
    .new( "bookshop" )
    .sort( "publishDate DESC" )
    // match everything
    .setQuery( { "match_all": {} } )
    // Query parameter: return the document version with each hit
    .param( "version", true )
    // Body parameter: return a relevance score for each document, despite our custom sort
    .bodyParam( "track_scores", true );
    // Body parameter: filter by minimum relevance score
    .bodyParam( "min_score", 3 )
    // run the search
    .execute();
```

{% hint style="info" %}
For more information on Elasticsearch query DSL, the [Search in Depth Documentation](https://www.elastic.co/guide/en/elasticsearch/guide/current/search-in-depth.html) is an excellent starting point.
{% endhint %}

## Collapsing Results

The `collapseToField` allows you to collapse the results of the search to a specific field. The data return includes the first matched, most relevant, document found with the collapsed field. When field collapsing is specified, an automatic aggregation will be run, which provides a pagination total for the collapsed document counts. When paginating collapsed fields, you will want to use the `SearchResult` method `getCollapsedCount()` as your total record count rather than the usual `getHitCount()` - which returns all documents matched to the query.

Let's say, for example, we want to find the most recent version of a book in our index, for all books matching the phrase "Elasticsearch". In this case, we can group on the `title` field ( or, in this case `title.keyword`, which is a dynamic keyword-typed field in our index ) to retrieve the most recent version of the book.

```js
var searchResults = getInstance( "SearchBuilder@cbelasticsearch" )
                                .new( index="bookshop" )
                                .mustMatch( "description", "Elasticsearch" )
                                .collapseToField( "title.keyword" )
                                .sort( "publishDate DESC" )
                                .execute()
```

There is also an option to include the number of ocurrences of each collapsed field in the results. When the argument `includeOccurrences=true` is passed to `collapseToField`  you can retrieve a map of all collapsed key values and their corresponding document count by calling `searchResult.getCollapsedOccurrences()`. 

{% hint style="info" %}
For more information on field collapsing, see the [Collapse Search Results Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/collapse-search-results.html).

### Get Collapsed Ocurrences

`collapseToField()` also supports an `includeOccurrences` option. By passing `includeOccurrences=true` to `collapseToField`, you can retrieve a map of all collapsed key values and their corresponding document count by calling `searchResult.getCollapsedOccurrences()`:

```js
var elasticsearchBookTitles = getInstance( "SearchBuilder@cbelasticsearch" )
                                .new( index="bookshop" )
                                .mustMatch( "description", "Elasticsearch" )
                                .collapseToField( field = "title.keyword", includeOccurrences = {} )
                                .sort( "publishDate DESC" )
                                .execute()
                                .getCollapsedOccurrences();
```

{% hint style="info" %}
For more information on field collapsing, see the [Collapse Search Results Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/collapse-search-results.html).

## Counting Documents

Sometimes you only need a count of matching documents, rather than the results of the query. When this is the case, you can call the `count()` method from the search builder ( or using the client ) to only return the number of matched documents and omit the result set and metadata:

```js
var docCount = getInstance( "SearchBuilder@cbelasticsearch" )
    .new(
        index = "bookshop",
        type = "books",
        properties = {
            "query" = {
                "term" = {
                    "isActive" = 1
                },
                "match" = {
                    "name" = "Elasticsearch",
                    "description" = "Elasticsearch",
                    "shortDescription" = "Elasticsearch"
                },
                "match_phrase" = {
                    "description" = {
                        "query" = "is awesome",
                        "boost" = 2
                    }
                }
            }
        }
    )
    .count();
```

## Highlights

ElasticSearch has the ability to highlight the portion of a document that matched. This is useful for showing context on why certain search results were returned. You can add an ElasticSearch highlight struct to your `SearchBuilder` using the `highlight` method. The struct should take the shape outlined on the [ElasticSearch website](https://www.elastic.co/guide/en/elasticsearch/reference/7.6/search-request-body.html#request-body-search-highlighting).

```js
SearchBuilder.highlight( {
    "fields" : {
        "body" : {}
    }
})
```

## Terms Enum

On occasion, you may wish to show a set of terms matching a partial string. This is similar to aggregations, only filtered by the provided string and intended for autocompletion.

To retrieve this data, you can use the client's `getTermsEnum()` method:

```js
var terms = getInstance( "HyperClient@cbelasticsearch" )
            .getTermsEnum(
                indexName  = "hotels",
                field = "city",
                match = "alb",
                size = 50,
                caseInsensitive = true
            );
```

For advanced lookups, you can use the second argument to pass a struct of custom options:

```js
var terms = getInstance( "HyperClient@cbelasticsearch" )
            .getTermsEnum( ["cities","towns"], {
                "field" : "name",
                "string" : "west",
                "size" : 50,
                "timeout" : "10s"
            } );
```

## Term Vectors

The ["Term Vectors" Elasticsearch API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-termvectors.html) allows you to retrieve information and statistics for terms in a specific document field. This could be useful for finding the most common term in a book description, or retrieving all terms with a minimum word length from the book title.

### Retrieving Term Vectors By Document ID

To retrieve term vectors for a known document ID, pass the index name, id, and an array or list of fields to pull from:

```js
var result = getInstance( "HyperClient@cbelasticsearch" ).getTermVectors(
    "books",
    "book_12345",
    [ "title" ]
);
```

You can fine-tune the request using the `options` argument:

```js
var result = getInstance( "HyperClient@cbelasticsearch" ).getTermVectors(
    indexName = "books",
    id = "book_12345",
    options = {
        "fields" : "title",
        "min_word_length" : 4
    }
);
```

See the [query parameters](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-termvectors.html#docs-termvectors-api-query-params) documentation for more configuration options.

### Retrieving Term Vectors By Payload

If you wish to analyze a payload (not an existing document) you can pass a `"doc"` payload in the `options` argument:

```js
var result = getInstance( "HyperClient@cbelasticsearch" ).getTermVectors(
    indexName = "books",
    fields = [ "title" ],
    options = {
      "doc" : {
        "title" : "The Lord of the Rings: The Fellowship of the Ring"
      }
    }
);
```

### SearchBuilder Term Vector Fetch

The SearchBuilder object also offers a `getTermVectors()` method for convenience:

```js
var result = getInstance( "SearchBuilder@cbelasticsearch" )
                .new( "books" )
                .getTermVectors(
                    myDocument._id,
                    [ "title,author.name" ]
                );
```

## `SearchBuilder` Function Reference

* `new([string index], [string type], [struct properties])` - Populates a new SearchBuilder object.
* `reset()` - Clears the SearchBuilder and resets the DSL
* `deleteAll()` - Deletes all documents matching the currently built search query.
* `execute()` - Executes the built search
* `getDSL()` - Returns a struct containing the assembled Elasticsearch query DSL
* `match(string name, any value, [numeric boost], [struct options], [string matchType='any'])` - Applies a match requirement to the search builder query.
* `multiMatch( array names, any value, [numeric boost], [type="best_fields"])` - Search an array of fields with a given search value.
* `dateMatch( string name, string start, string end, [numeric boost])` - Adds a date range match.
* `mustMatch(string name, any value, [numeric boost])` - `must` query alias for match().
* `mustNotMatch(string name, any value, [numeric boost])` - `must_not` query alias for match().
* `shouldMatch(string name, any value, [numeric boost])` - `should` query alias for match().
* `sort(any sort, [any sortConfig])` - Applies a custom sort to the search query.
* `term(string name, any value, [numeric boost])` - Adds an exact value restriction ( elasticsearch: term ) to the query.
* `aggregation(string name, struct options)`  - Adds an aggregation directive to the search parameters.
* `collapseToField( string field, struct options, boolean includeOccurrences = false )` - Collapses the results to the single field and returns only the most relevant/ordered document matched on that field.