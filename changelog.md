CHANGELOG
=========

# 1.1.4
# Implements url encoding for identifiers, to allow for spaces and special characters in identifiers

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

