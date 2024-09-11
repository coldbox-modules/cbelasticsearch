---
description: Learn how to create and manage index aliases with CBElasticsearch
---

# Managing Index Aliases

cbElasticSearch offers the `AliasBuilder` for assistance in adding and removing index aliases.

For creating an alias:

```js
getWireBox().getInstance( "AliasBuilder@cbElasticSearch" )
    .add( indexName = "myIndex", aliasName = "newAlias" )
    .save();
```

For removing an alias:

```js
getWireBox().getInstance( "AliasBuilder@cbElasticSearch" )
    .remove( indexName = "otherIndex", aliasName = "randomAlias" )
    .save();
```

For bulk operations, use the cbElasticSearch client's `applyAliases` method. These operations are performed in the same transaction (i.e. atomic), so it's safe to use for switching the alias from one index to another.

```js
var removeAliasAction = getWireBox().getInstance( "AliasBuilder@cbElasticSearch" )
    .remove( indexName = "testIndexName", aliasName = "aliasNameOne" );
var addNewAliasAction = getWireBox().getInstance( "AliasBuilder@cbElasticSearch" )
    .add( indexName = "testIndexName", aliasName = "aliasNameTwo" );

variables.client.applyAliases(
    // a single alias action can also be provided
    aliases = [ removeAliasAction, addNewAliasAction ]
);
```

## Retrieving Aliases

The client's `getAliases` method allows you to retrieve a map containing information on aliases in use in the connected cluster.

```js
var aliasMap = getInstance( "Client@cbelasticsearch" ).getAliases();
```

The corresponding object will have two keys: `aliases` and `unassigned`. The former is a map of aliases with their corresponding index, the latter is an array of indexes which are unassigned to any alias.