component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

		super.beforeAll();

		variables.model = getWirebox().getInstance( "Task@cbElasticSearch" );
	}

	function afterAll(){
		super.afterAll();
	}

	function run(){
		describe( "Performs cbElasticsearch Task tests", function(){
			it( "tests basic functionality", function(){
				expect( variables.model ).toBeInstanceOf( "cbElasticsearch.models.Task" );
				var testTask = {
					"completed" : false,
					"task"      : {
						"node"                  : "oTUltX4IQMOUUVeiohTt8A",
						"id"                    : 464,
						"type"                  : "transport",
						"action"                : "indices:data/read/search",
						"description"           : "indices[test], types[test], search_type[QUERY_THEN_FETCH], source[{""query"":...}]",
						"start_time_in_millis"  : 1483478610008,
						"running_time_in_nanos" : 13991383,
						"cancellable"           : true
					}
				};
				variables.model.populate( testTask );

				expect( variables.model.getCompleted() ).toBe( testTask.completed );


				// we should throw an invalid task exception if we attempt to refresh, since we don't have a cluster
				expect( function(){
					variables.model.isComplete();
				} ).toThrow( "cbElasticsearch.native.resource_not_found_exception" );

				// it should not throw an error if we tell it not to refresh
				expect( variables.model.isComplete( false ) ).toBeFalse();

				// it should not attempt a refresh if it is already marked complete
				variables.model.setCompleted( true );

				expect( variables.model.isComplete() ).toBeTrue();
			} );
			it( "can get error details", function(){
				expect( variables.model ).toBeInstanceOf( "cbElasticsearch.models.Task" );
				var testTask = {
					"completed" : false,
					"task"      : {
						"node"                  : "oTUltX4IQMOUUVeiohTt8A",
						"id"                    : 464,
						"type"                  : "transport",
						"action"                : "indices:data/read/search",
						"description"           : "indices[test], types[test], search_type[QUERY_THEN_FETCH], source[{""query"":...}]",
						"start_time_in_millis"  : 1483478610008,
						"running_time_in_nanos" : 13991383,
						"cancellable"           : true
					},
					"error" : {
						"position"  : { "offset" : 33, "start" : 16, "end" : 64 },
						"script"    : " for ( test in ctx._source ){ ...",
						"reason"    : "runtime error",
						"type"      : "script_exception",
						"lang"      : "painless",
						"caused_by" : {
							"reason" : "Cannot iterate over [java.util.HashMap]",
							"type"   : "illegal_argument_exception"
						},
						"script_stack" : [ "for ( case in ctx._source ){ ", " ^---- HERE" ]
					}
				};
				variables.model.populate( testTask );

				expect( variables.model.getCompleted() ).toBe( testTask.completed );
				expect( variables.model.getError() ).toBeTypeOf( "struct" ).toHaveKey( "reason" );
			} );
		} );
	}

}
