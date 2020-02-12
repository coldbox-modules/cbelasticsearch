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

#### Advanced Query DSL

The SearchBuilder also allows full use of the [Elasticsearch query language](https://www.elastic.co/guide/en/elasticsearch/reference/current/_introducing_the_query_language.html), allowing detailed configuration of queries, if the basic `match()`, `sort()` and `aggregate()` methods are not enough to meet your needs. There are several methods to provide the raw query language to the Search Builder.  One is during instantiation.

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
