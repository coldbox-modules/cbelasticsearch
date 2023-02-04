---
description: Learn How to to use Index Lifecycle Policies to transition time series data
---

# ILM Policies

For time-series data, such as logs or metrics, you may wish to transition or even delete older data after a period of time.  Since Elasticsearch v7, ILM policies allow you to configure the transition and retention of your data.  The `ILMPolicyBuilder` object helps facilitate the configuration of of ILM for your data streams or time-series indices.  For an ILM policy to work, your documents must have a field of `@timestamp`. If your existing indices do not have this field, you can add it [via an `updateByQuery` script](/documents#update-by-query) using an existing timestamp field.

{% hint style="info" %}
For more information, head to the [ILM Overview in the Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/overview-index-lifecycle-management.html).
{% endhint %}


## Policy Creation
Let's create a simple policy to delete our data after 30 days:

```js
getInstance( "ILMPolicyBuilder@cbelasticsearch" )
        .new( 
            "my-ilm-policy"
        ).withDeletion(
            age = 30
        ).save();
```

In order to attach the policy to an existing index you can specify the `index.lifecycle.name` in the index settings or in your [Component or Index Templates](Templates.md);

```js
getInstance( "IndexBuilder@cbelasticsearch" )
                .new( 
                    name="my-index-name", 
                    settings={ 
                        "index.lifecycle.name" : "my-ilm-policy" 
                    } 
                )
                .save();
```


## Phased Rollover and Archival

You may also wish to transition data between phases, and consolidate or shrink your datasets as they age.  This can be done by using [lifeycle phases](https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-index-lifecycle.html). 

Let's create a more complex index lifecycle:

```js
getInstance( "ILMPolicyBuilder@cbelasticsearch" )
        .new( "my-advanced-ilm-policy" )
        .hotPhase(
            // the number of shards to use in the initial phase ( overrides any index template settings )
            shards = 3
            // Forces a rollover of the oldest data, regardless of age, if the size of any shard is greater than 10GB
            rollover = 10
        ).warmPhase(
            // transition to this phase at 30 days old
            age = "30d",
            // shrink to 2 shards from 3 in the hot phase
            shards = 2,
            // Set to no replicas in this phase
            allocate = 0,
            // downsample our time series data to 1 hour intervals
            downsample = "1h"
        ).coldPhase(
            // transition to this phase at 30 days old
            age = "60d",
            // shrink to 2 shards from 3 in the hot phase
            shards = 1,
            // Set to no replicas in this phase
            allocate = 0,
            // downsample our time series data to 2 hour intervals
            downsample = "2h"
            // Make our index read only in this phase
            readOnly = true
        ).withDeletion(
            age = "120d"
        ).save();
```

## ILMPolicyBuilder Method Signatures

### `new`
```js
/**
     * Creates a new policy builder instance
     *
     * @policyName string
     * @phases a struct of phases ( optional )
     * @meta optional struct of meta
     */
    ILMPolicyBuilder function new(
        required string policyName,
        struct phases,
        struct meta
    )
```

### `hotPhase`
```js
    /**
     * Sets the configuration for the ILM Hot Phase
     * https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-index-lifecycle.html
     *
     * @config a raw struct containing the phase configuration
     * @priority numeric a priority to set for this index during the phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-set-priority.html
     * @rollover any either a raw rollover struct or a numeric (GB)/ string representing the size at which the index should rollover documents to the next phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-rollover.html 
     * @shards numeric the number of shards to shrink to in the phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-shrink.html
     * @searchableSnapshot string the name of a snapshot respository to create during this phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-searchable-snapshot.html
     * @downsample any whether to downsample the repository. Either a numeric or string may be passed ( e.g. 1(days) or `1d` ) which denotes the fixed interval of the @timestamp to downsample to https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-downsample.html 
     * @forceMerge numeric The number of segments to force merge to during this phase.  This action makes the index read-only https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-forcemerge.html
     * @readOnly boolean  Whether to make the index read-only during the phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-readonly.html
     * @unfollow boolean Whether to convert from a follower index ot a regular index at this phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-unfollow.html
     */
    ILMPolicyBuilder function hotPhase(
        struct config,
        numeric priority,
        any rollover,
        numeric shards,
        string searchableSnapshot,
        any downsample,
        numeric forceMerge,
        boolean readOnly,
        boolean unfollow
    )
```

### `warmPhase`
```js
    /**
     * Sets the configuration for the ILM Warm Phase
     * https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-index-lifecycle.html
     *
     * @config a raw struct containing the phase configuration
     * @age any Either a numeric of the number of days or a string interval to use as the threshold at which data is transitioned to this tier 
     * @priority numeric a priority to set for this index during the phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-set-priority.html
     * @shards numeric the number of shards to shrink to in the phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-shrink.html
     * @downsample any whether to downsample the repository. Either a numeric or string may be passed ( e.g. 1(days) or `1d` ) which denotes the fixed interval of the @timestamp to downsample to https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-downsample.html
     * @allocate any if a numeric is provided it is applied as the number of replicas.  Otherwise a struct config may be provided https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-allocate.html 
     * @migrate boolean moves the data to the phase-configured tier. Defaults to true so only use this argument if disabling migration https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-migrate.html
     * @forceMerge numeric The number of segments to force merge to during this phase.  This action makes the index read-only https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-forcemerge.html
     * @readOnly boolean  Whether to make the index read-only during the phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-readonly.html
     * @unfollow boolean Whether to convert from a follower index ot a regular index at this phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-unfollow.html
     */
    ILMPolicyBuilder function warmPhase(
        struct config,
        any age,
        numeric priority,
        numeric shards,
        any downsample,
        any allocate,
        boolean migrate,
        numeric forceMerge,
        boolean readOnly,
        boolean unfollow
    )
```

### `coldPhase`
```js
    /**
     * Sets the configuration for the ILM Cold Phase
     * https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-index-lifecycle.html
     *
     * @config a raw struct containing the phase configuration
     * @age any Either a numeric of the number of days or a string interval to use as the threshold at which data is transitioned to this tier 
     * @priority numeric a priority to set for this index during the phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-set-priority.html
     * @searchableSnapshot string the name of a snapshot respository to create during this phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-searchable-snapshot.html
     * @downsample any whether to downsample the repository. Either a numeric or string may be passed ( e.g. 1(days) or `1d` ) which denotes the fixed interval of the @timestamp to downsample to https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-downsample.html
     * @allocate any if a numeric is provided it is applied as the number of replicas.  Otherwise a struct config may be provided https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-allocate.html 
     * @migrate boolean moves the data to the phase-configured tier. Defaults to true so only use this argument if disabling migration https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-migrate.html
     * @readOnly boolean  Whether to make the index read-only during the phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-readonly.html
     * @unfollow boolean Whether to convert from a follower index ot a regular index at this phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-unfollow.html
     */
    ILMPolicyBuilder function coldPhase(
        struct config,
        any age,
        numeric priority,
        string searchableSnapshot,
        any downsample,
        any allocate,
        boolean migrate,
        boolean readOnly,
        boolean unfollow
    )

```

### `frozenPhase`
Note that this phase may not be used without either the `searchableSnapshot` or `unfollow` arguments passed
```js
    /**
     * Sets the configuration for the ILM Freeze Phase
     * https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-index-lifecycle.html
     *
     * @config a raw struct containing the phase configuration
     * @age any Either a numeric of the number of days or a string interval to use as the threshold at which data is transitioned to this tier 
     * @searchableSnapshot string the name of a snapshot respository to create during this phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-searchable-snapshot.html
     * @unfollow boolean Whether to convert from a follower index ot a regular index at this phase https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-unfollow.html
     */
    ILMPolicyBuilder function frozenPhase(
        struct config,
        any age,
        string searchableSnapshot,
        boolean unfollow
    )
```

### `withDeletion`

```js
    /**
     * Sets the configuration for the deletion phase
     * 
     * @config a raw struct containing the phase configuration
     * @age any Either a numeric of the number of days or a string interval to use as the threshold at which data is transitioned to this tier 
     * @waitForSnapshot string the name of the SLM policy to execute that the delete action should wait for https://www.elastic.co/guide/en/elasticsearch/reference/current/ilm-wait-for-snapshot.html
     * @deleteSnapshot boolean Whether to delete the snapshot created in the previous phase
     * 
     */
    ILMPolicyBuilder function withDeletion(
        struct config,
        any age,
        string waitForSnapshot,
        boolean deleteSnapshot
    )
```
