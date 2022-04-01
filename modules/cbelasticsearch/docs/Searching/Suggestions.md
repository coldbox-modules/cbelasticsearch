---
description: Provide "Did you mean __?" or autocomplete functionality to your app's search form with CBElasticsearch
---

# Suggestors

Suggestors are ElasticSearch's way of providing similar looking terms. They fall into two different use cases:  "Did you mean...?" or spell check functionality and autocomplete functionality.

You can access the suggestions on the `SearchResult` component using the `getSuggestions` method.

## Did you mean...?

cbElasticSearch can provide a spell-checked or "Did you mean...?" suggestions using either the `suggestTerm` or `suggestPhrase` methods.

* `suggestTerm(string text, string name, string field = arguments.name, struct options = {})`  - Adds a term suggestion to the query.
* `suggestPhrase(string text, string name, string field = arguments.name, struct options = {})`  - Adds a phrase suggestion to the query.

Term suggestions suggestors on a single word at a time, while phrase suggestors operate on an entire phrase. Any additional options shown on the website can be passed in as the `options` struct.

Term and phrase suggestors are usually added to an existing query. The results will appear in a `suggest` property on the `SearchResult`.

{% hint style="info" %}
More information on how to optimize term and phrase suggestors can be found in the [ElasticSearch documentation.](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-suggesters.html)
{% endhint %}

## Autocomplete

cbElasticSearch can also provide autocomplete behavior using the `suggestCompletion` method.  This adds a `completion` block to the `suggest` query.

* `suggestCompletion(string text, string name, string field = arguments.name, struct options = {})`  - Adds a completion suggestion to the query.

Completion suggestors can only operate against a mapping of type `completion`. This can be built either using the struct notation or the `MappingBuilder#completion` method.

Completion suggestors usually operate without a query.  It is recommended you also only bring back the `_source` fields that you need.  If you do not need any of the `_source` fields, you can `setSource( false )` to not bring back `_source` at all.