Searching Documents
===================

The `SearchBuilder` object offers an expressive syntax for crafting detailed searches with ranked results.  To perform a simple search for matching documents documents, using Elasticsearch's automatic scoring, we would use the `SearchBuilder` like so:

```
var searchResults = getInstance( "SearchBuilder@cbElasticsearch" )
    .new( index="bookshop", type="books" )
    .match( "name", "Elasticsearch" )
    .execute();
```

By default this search will return an array of `Document` objects ( or an empty array if no results are found ), with a descending match score as the sort.

To output the results of our search, we would use a loop, accessing the `Document` methods:

```
for( var resultDocument in searchResults.getHits() ){
	var resultScore     = resultDocument.getScore();
	var documentMemento = resultDocument.getMemento();
	var bookName        = documentMemento.name;
	var bookDescription = documentMemento.description;
}
```

The "memento" is our structural representation of the document. We can also use the built-in method of the Document object:

```
for( var resultDocument in searchResults.getHits() ){
	var resultScore     = resultDocument.getScore();
	var bookName        = resultDocument.getValue( "name" );
	var bookDescription = resultDoument.getValue( "description" );
}
```

### Search matching


#### Exact matching

The `term()` method allows a means of specifying an exact match of all documents in the search results.  An example use case might be only to search for active documents:

```
searchBuilder.term( "isActive", 1 );
```

Or a date:

```
searchBuilder.term( "publishDate", "2017-05-13" );
```

#### Boosting individual matches

The `match()` method of the `SearchBuilder` also allows for a `boost` argument.  When provided, results which match the term will be ranked higher in the results:

```
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


### Wildcards

There are times when you want to be able to match a portion of a `keyword`-mapped field in elasticsearch.  The `wildcard` method allows you to do this.  Let's say I wanted to match any documents with a `name` key containing `Elastic`.  I could use the following method to match those documents:

```
searchBuilder.keyword( "name", "Elastic" );
```

This would match any documents with a `name` keyword field containing `Elasticsearch` or `Elasticache`.  It is important to note that wildcard queries are exceptionally slow, compared to `term`/`must`/`should` queries, as they require recursion through the entire index of document values to obtain their matches.

We can also boost matches and make this a conditional to an existing query:

```
searchBuilder.shouldMatch( "shortDescription", "Elastic", 1 )
             .wildcard( "name", "Elastic", 5, "should" );
```

In the above query we change the `operator` argument for the wildcard query to "should" to ensure that the match becomes an "or" for the short description or the wildcard.  In addition, we boost the wildcard results 5 times above the short description matched results.


#### Advanced Query DSL

The SearchBuilder also allows full use of the [Elasticsearch query language](https://www.elastic.co/guide/en/elasticsearch/reference/current/_introducing_the_query_language.html), allowing detailed configuration of queries, if the basic `match()`, `sort()` and `aggregation()` methods are not enough to meet your needs. There are several methods to provide the raw query language to the Search Builder.  One is during instantiation.

In the following we are looking for matches of active records with "Elasticsearch" in the `name`, `description`, or `shortDescription` fields. We are also looking for a phrase match of "is awesome" and are boosting the score of the applicable document, if found.

```
var search = getInstance( "SearchBuilder@cbElasticsearch" )
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

For more information on Elasticsearch query DSL, the [Search in Depth Documentation](https://www.elastic.co/guide/en/elasticsearch/guide/current/search-in-depth.html) is an excellent starting point.

### Collapsing Results

The `collapseToField` allows you to collapse the results of the search to a specific field.  The data return includes the first matched, most relevant, document found with the collapsed field.  When field collapsing is specified, an automatic aggregation will be run, which provides a pagination total for the collapsed document counts. When paginating collapsed fields, you will want to use the `SearchResult` method `getCollapsedCount()` as your total record count rather than the usual `getHitCount()` - which returns all documents matched to the query.

Let's say, for example, we want to find the most recent version of a book in our index, for all books matching the phrase "Elasticsearch".  In this case, we can group on the `title` field ( or, in this case `title.keyword`, which is a dyamic keyword-typed field in our index ) to retreive the most recent version of the book.

```
var searchResults = getInstance( "SearchBuilder@cbElasticsearch" )
                                .new( index="bookshop" )
                                .mustMatch( "description", "Elasticsearch" )
                                .collapseToField( "title.keyword" )
                                .sort( "publishDate DESC" )
                                .execute()
```

There is also an option to include the number of ocurrences of each collapsed field in the results.  When the argument `includeOccurrences=true` is passed to `collapseToField`  you can retreieve a map of all collapsed key values and their corresponding document count by calling `searchResult.getCollapsedOccurrences()`.  

For more information on field collapsing, see the [Collapse Search Results Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/collapse-search-results.html).

#### Sorting Results

The `sort()` method also allows you to specify custom sort options.  To sort by author last name, instead of score, we would simply use:

```
searchBuilder.sort( "author.lastName", "asc" );
```

While our documents would still be scored, the results order would be changed to that specified.

#### Search Builder Function Reference:

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

Counting Documents
===================

Sometimes you only need a count of matching documents, rather than the results of the query.  When this is the case, you can call the `count()` method from the search builder ( or using the client ) to only return the number of matched documents and omit the result set and metadata:

```
var docCount = getInstance( "SearchBuilder@cbElasticsearch" )
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

Highlight
=========

ElasticSearch has the ability to highlight the portion of a document that matched.
This is useful for showing context on why certain search results were returned.
You can add an ElasticSearch highlight struct to your `SearchBuilder` using the
`highlight` method.  The struct should take the shape outlined on the
[ElasticSearch website](https://www.elastic.co/guide/en/elasticsearch/reference/7.6/search-request-body.html#request-body-search-highlighting).

* `highlight(struct highlight)`  - Adds a highlight directive to the search parameters.


[Suggestors](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-suggesters.html)
===========

Suggestors are ElasticSearch's way of providing similar looking terms.
They fall into two different use cases:  "Did you mean...?" or spell check
functionality and autocomplete functionality.

You can access the suggestions on the `SearchResult` component using the
`getSuggestions` method.

### Did you mean...?

cbElasticSearch can provide a spell-checked or "Did you mean...?" suggestions
using either the `suggestTerm` or `suggestPhrase` methods.

* `suggestTerm(string text, string name, string field = arguments.name, struct options = {})`  - Adds a term suggestion to the query.
* `suggestPhrase(string text, string name, string field = arguments.name, struct options = {})`  - Adds a phrase suggestion to the query.

Term suggestions suggestors on a single word at a time, while phrase suggestors
operate on an entire phrase.  More information on how to optimize term and phrase
suggestors can be found in the [ElasticSearch documentation.](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-suggesters.html)
Any additional options shown on the website can be passed in as the `options` struct.

Term and phrase suggestors are usually added to an existing query.
The results will appear in a `suggest` property on the `SearchResult`.

### Autocomplete

cbElasticSearch can also provide autocomplete behavior using the `suggestCompletion`
method.  This adds a `completion` block to the `suggest` query.

* `suggestCompletion(string text, string name, string field = arguments.name, struct options = {})`  - Adds a completion suggestion to the query.

Completion suggestors can only operate against a mapping of type `completion`.
This can be built either using the struct notation or the `MappingBuilder#completion` method.

Completion suggestors usually operate without a query.  It is recommended you
also only bring back the `_source` fields that you need.  If you do not need
any of the `_source` fields, you can `setSource( false )` to not bring back
`_source` at all.
