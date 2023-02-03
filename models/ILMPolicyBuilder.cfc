component accessors="true"{

    property name="policyName";

    property name="phases";

    property name="meta";

    
    /**
	 * Client provider
	 **/
	Client function getClient() provider="Client@cbElasticsearch"{}

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
    ){

        structAppend( variables, arguments, true );
        param variables.phases = {};
        param variables.meta = {};

        return this;
    }

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
    ){
        arguments.phaseName = "hot";
        return setPhase( argumentCollection = arguments );
    }

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
    ){

        verifyAgePolicy( argumentCollection = arguments );
        arguments.phaseName = "warm";
        return setPhase( argumentCollection = arguments );
    }

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
    ){
        verifyAgePolicy( argumentCollection = arguments );

        arguments.phaseName = "cold";
        return setPhase( argumentCollection = arguments );
    }
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
    ){
        verifyAgePolicy( argumentCollection = arguments );

        arguments.phaseName = "freeze";
        return setPhase( argumentCollection = arguments );
        
    }

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
    ){
        verifyAgePolicy( argumentCollection = arguments );

        var maxAge = arguments.age ?: config.max_age;
        if( isNumeric( maxAge ) ) maxAge = javacast( "string", maxAge & "d" );
        
        var phase = {
            "min_age": maxAge,
            "actions": {
              "delete": {}
            }
        };

        if( !isNull( arguments.waitForSnapshot ) ){
            phase.actions[ "wait_for_snapshot" ] = {
                "policy" : arguments.waitForSnapshot
            };
        }
        
        if( !isNull( arguments.deleteSnapshot ) ){
            phase.actions.delete[ "delete_searchable_snapshot" ] = javacast( "boolean", arguments.deleteSnapshot );
        }

        variables.phases[ "delete" ] = phase;

        return this;

    }

    /**
     * Sets the configuration for an ILM phase
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
    ILMPolicyBuilder function setPhase(
        required string phaseName,
        struct config,
        numeric priority,
        any age,
        any rollover,
        numeric shards,
        string searchableSnapshot,
        any downsample,
        numeric forceMerge,
        boolean readOnly = false,
        boolean unfollow = false
    ){

        var phase = arguments.config ?: { "actions" : {} };

        if( !isNull( arguments.priority ) ){
            phase.actions[ "set_priority" ] = { "priority" : arguments.priority };
        }

        if( !isNull( arguments.age ) ){
            phase[ "min_age" ] = arguments.age;
            if( isNumeric( phase.min_age ) ) phase.min_age = javacast( "string", phase.min_age & "d" );
        }
        
        if( !isNull( arguments.rollover ) ){
            var rolloverSize = arguments.rollover;
            if( isNumeric( rolloverSize ) ) rolloverSize = javacast( "string", rolloverSize & "gb" );
            phase.actions[ "rollover" ] = { "max_primary_shard_size" : rolloverSize };
        }

        if( !isNull( arguments.shards ) ){
            phase.actions[ "shrink" ] = {
                "number_of_shards" : arguments.shards
            };
        }
        
        if( !isNull( arguments.searchableSnapshot ) ){
            phase.actions[ "searchable_snapshot" ] = {
                "shapshot_repository" : arguments.searchableSnapshot
            };
        }
        
        if( !isNull( arguments.downsample ) ){
            if( getClient().isMajorVersion( 7 ) ){
                getClient().getLog().warn( "Elasticsearch versions below version 8 do not support lifecycle phase downsampling. The argument with a value of #arguments.downsample# in phase #arguments.phaseName# for policy #variables.policyName# is being ignored." );
            } else {
                var interval = arguments.downsample;
                if( isNumeric( interval ) ) interval = javacast( "string", interval & "h" );
                phase.actions[ "downsample" ] = { "fixed_interval" : interval };
            }
        }
        
        if( !isNull( arguments.forceMerge ) ){
            phase.actions[ "forcemerge" ] = { "max_num_segments": arguments.forceMerge };
        }
        
        if( arguments.readOnly  ){
            phase.actions[ "readonly" ] = {};
        }
        
        if( arguments.unfollow ){
            phase.actions[ "unfollow" ] = {};
        }

        variables.phases[ arguments.phaseName ] = phase;

        return this;

    }

    /**
     * Returns the configured policy DSL
     */
    struct function getDSL(){
        var policy = {
            "phases" : variables.phases
        };

        if( !variables.meta.isEmpty() ){
            policy[ "_meta" ] = variables.meta
        }

        return policy;
    }

    /**
     * Creates or Updates the Policy
     */
    ILMPolicyBuilder function save(){
        getClient().applyILMPolicy( variables.policyName, getDSL() );
        return this;
    }

    /**
     * Returns the existing ILM policy
     */
    struct function get(){
        return getClient().getILMPolicy( variables.policyName );
    }

    /**
     * Verifies the age is set for a policy
     * 
     * @config struct
     * @age string
     */
    private void function verifyAgePolicy( struct config, string age ){
        if( ( isNull( arguments.age ) && isNull( arguments.config ) ) || ( !isNull( arguments.config ) && !arguments.config.keyExists( "max_age" ) )  ){
            throw(
                type = "cbElasticsearch.ILMPolicy.InvalidPolicyException",
                message = "This ILM Phase requires an age parameter at which to transition documents"
            );
        }
    }
}