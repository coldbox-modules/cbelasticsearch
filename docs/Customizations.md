---
description: Learn how to optimize and extend CBElasticsearch to better fit your app's needs.
---

# Customizations

Elasticsearch offers a TON of functionality, and while CBElasticsearch is able to cover the majority of the main features, some of the lesser-known API calls may not be currently supported. If you need to implement an Elasticsearch feature which is not included in CBElasticsearch, you can implement this yourself using the `getNodePool()` method to obtain a [HyperRequest object](https://hyper.ortusbooks.com/making-requests/hyperrequest) with an Elasticsearch connection:

```js
var myCustomESRequest = getInstance( "Client@cbElasticsearch" ).getNodePool();
```

From here, you can use Hyper methods to build and send the request:

```js
var response = getInstance( "Client@cbElasticsearch" ).getNodePool()
			.newRequest( "myIndex/_close", "POST" )
			.asJSON()
			.send();
```

The response back will be a typical [HyperResponse object](https://hyper.ortusbooks.com/making-requests/hyperresponse), so you can use [`.isError()` to check for an error response](https://hyper.ortusbooks.com/making-requests/hyperresponse#iserror), [`.json()` to retrieve the JSON response](https://hyper.ortusbooks.com/making-requests/hyperresponse#json), etc.

As a simplistic example of handling a custom ES request and response:

```js
var response = getInstance( "Client@cbElasticsearch" ).getNodePool()
	.newRequest( "#arguments.indexName#/_close", "POST" )
	.asJSON()
	.send();

if ( response.isError() ) {
	throw( message = "Received failure from ES", extendedInfo = response.getData() );
} else {
	return response.json();
}
```

The Elasticsearch client also offers many utility methods for either building the request or processing the result - see, for example, `parseParams()` and `onResponseFailure()`.

Putting this all together, here's a full example of a custom method which implements a nontypical Elasticsearch API call, supporting all query parameters and using CBElasticsearch's standard error handling:

```js
function closeIndex( required string indexName, any params ){
	var elasticSearchClient = getInstance( "Client@cbElasticsearch" );
	var requestBuilder = elasticSearchClient.getNodePool()
		.newRequest( "#arguments.indexName#/_close", "POST" )
		.asJSON();

	if ( structKeyExists( arguments, "params" ) ) {
		elasticSearchClient.parseParams( arguments.params ).each( function( param ){
			requestBuilder.setQueryParam( param.name, param.value );
		} );
	}

	var response = requestBuilder.send();

	if ( response.isError() ) {
		elasticSearchClient.onResponseFailure( response );
	} else {
		return response.json();
	}
}
```