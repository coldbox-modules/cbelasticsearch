CHANGELOG
=========
# 1.3.3
* ( add updates here )

# 1.3.2
* Modifies search builder methods of `filterTerm` and `filterTerms` to return the builder instance ( Issue #43 )
* Adds a Util component for common inbound and outbound conversions and casting
* Modifies Document `setValue` method to return instance, for method chaining ( Issue #40 )
* Fixes an error when individual documents in a bulk save contained errors ( Issue #44 )

# 1.3.1
* Adds responses to task model
* Adds the ability to provide a transformation script to the client `reindex` method

# 1.3.0
* Adds the ability to pass URL parameters to SearchBuilder-aware client methods.  Adds a `param( name, value )` supporting method to the SearchBuilder
* Adds a new Task object which can be refreshed and used in a loop as long-running tasks complete in the background ( e.g.  `while( !task.isComplete() )` )
* ( Breaking ) Changes the return type of the `deleteByQuery` and `updateByQuery` to return the full API response which may be inspected or used to follow-up on tasks
* implements a `getAllTasks()` method in the client, which will return an array of Task objects
* implements a `getTask` method in the client to retreive tasks by identifier ( e.g. - `[node]:[id]` ). 
* implements a `getIndices` method in the client to retreive a map of indices with stats
* implements a `getAliases` method in the client to retreive a map of aliases
* Resolves Issue #12 - slf4j missing on non-Runwar installations
* Resolves Issue #17 - implements workarounds and adds documentation on how to configure and use a connection to a secondary elasticsearch cluster

# 1.2.2
* Adds fallback attempt when connection pool is unexpectedly closed upstream

# 1.2.1
* Adds a soft fail to the version target check when a connection to the ES start page cannot be established

# 1.2.0
* Implements compatibility for Elasticsearch v7
* Adds environment variable detection for default configuration
* Implements a new AliasBuilder object, which can be used to alias indexes
* Implements a new `reindex()` method in the client which allows the ability to reindex
* Implements new `mustExist` and `mustNotExist` methods to the SearchBuilder

# 1.1.6
* Reverts to previous versions of HTTP client due to instability and connection expiration issues
* Adds connection cleanup prior to execution

# 1.1.5
* Updates Apache HTTP Client to v4.5.9
* Adds count() methods to the SearchBuilder and Client

# 1.1.4
* Implements url encoding for identifiers, to allow for spaces and special characters in identifiers

# 1.1.3
* Implements update by query API and interface

# 1.1.2
* Adds compatibility when Secure JSON prefix setting is enabled

# 1.1.1
* Updates Java Dependencies, including JEST client, to latest versions
* Implements search term highlighting capabilities

# 1.1.0
* Updates to `term` and `filterTerms` SearchBuilder methods to allow for more precise filtering
* Adds  `filterTerm` method which allows restriction of the search context
* Adds `type` and `minimum_should_match` parameters to `multiMatch` method in SearchBuilder

# 1.0.0
* Adds support for Elasticsearch v6.0+
* Adds a new MappingBuilder
* Updates to SearchBuilder to alow for more complex queries with fewer syntax errors
* Refactor filterTerms to allow other `should` or `filter` clauses
* Add ability to specify `_source` excludes and includes in a query
* ACF Compatibility Updates

# 0.3.0
* Adds `readTimeout` and `connectionTimeout` settings
* Adds `defaultCredentials` setting
* Adds default preflight of query to fix common assembly syntax issues

# 0.2.1
* Adds `filterTerms()` method to allow an array of term restrictions to the result set

# 0.2.0
* Fixes pagination and offset handling
* Adds support for terms filters in match()

# 0.1.0 
* Initial Release

