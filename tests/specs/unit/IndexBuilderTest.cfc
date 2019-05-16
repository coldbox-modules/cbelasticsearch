component extends="coldbox.system.testing.BaseTestCase"{

	function beforeAll(){

		this.loadColdbox=true;

		setup();

		variables.model = getWirebox().getInstance( "IndexBuilder@cbElasticSearch" );

		variables.testIndexName = lcase("IndexBuilderTests");

		variables.model.getClient().deleteIndex( variables.testIndexName );

	}

	function afterAll(){

		//variables.model.getClient().deleteIndex( variables.testIndexName );

		super.afterAll();
	}

	function run(){
		describe( "Performs cbElasticsearch IndexBuilder tests", function(){

			it( "Tests new() with no arguments", function(){

				var newIndex = variables.model.new();

				expect( newIndex.getMappings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getMappings() ) ).toBeTrue();
				expect( isNull( newIndex.getSettings() ) ).toBeTrue();


			});

			it( "Tests new() with a full properties struct", function(){

				var indexSettings = {
										"mappings":{
											"testdocs":{
												"_all"       : { "enabled": false },
												"properties" : {
													"title"      : {"type" : "text"},
													"createdTime": {
														"type"  : "date",
														"format": "date_time_no_millis"
													}
												}
											},
											"aliases" = { "testalias" : {} }
										},
										"settings":{
											"number_of_shards":5,
											"number_of_replicas":2
										}
									};

				var newIndex = variables.model.new( name=variables.testIndexName, properties=indexSettings );

				expect( newIndex.getSettings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getSettings() ) ).toBeFalse();
				expect( newIndex.getMappings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getAliases() ) ).toBeFalse();
				expect( newIndex.getAliases() ).toBeStruct();
				expect( structIsEmpty( newIndex.getMappings() ) ).toBeFalse();
				expect( newIndex.getIndexName() ).toBe( variables.testIndexName );

            });

            it( "Tests new() with a callback for the builder syntax", function() {
				var newIndex = variables.model.new( name=variables.testIndexName, properties=function( builder ) {
                    return {
                        "testdocs" = builder.create( function( mapping ) {
                            mapping.text( "title" );
                            mapping.date( "createdTime" ).format( "date_time_no_millis" );
                        } )
                    };
                }, settings = { "number_of_shards" = 5, "number_of_replicas" = 2 } );

				expect( newIndex.getSettings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getSettings() ) ).toBeFalse();
				expect( newIndex.getMappings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getMappings() ) ).toBeFalse();
                expect( newIndex.getIndexName() ).toBe( variables.testIndexName );
                expect( newIndex.getMappings() ).notToBeEmpty();
                expect( newIndex.getMappings() ).toHaveKey( "testdocs" );
			} );

			it( "Tests the save() method ability to create an index", function(){
				//create our new index
				var indexSettings = {
										"mappings":{
											"testdocs":{
												"_all"       : { "enabled": false },
												"properties" : {
													"title"      : {"type" : "text"},
													"createdTime": {
														"type"  : "date",
														"format": "date_time_no_millis"
													}
												}
											}
										}
									};


				var newIndex = variables.model.new(
											name=variables.testIndexName,
											properties=indexSettings
										);

				expect( newIndex.save() ).toBeTrue();

				expect( variables.model.getClient().indexExists( variables.testIndexName ) ).toBeTrue();

			});

			it( "Tests the ability to reset the index builder", function(){

				variables.model.reset();

				expect( variables.model.getMappings() ).toBeStruct();
				expect( structIsEmpty( variables.model.getMappings() ) ).toBeTrue();
				expect( isNull( variables.model.getSettings() ) ).toBeTrue();

			} );

			it( "Tests the delete() methods ability to remove an index", function(){

				variables.model.new( variables.testIndexName ).delete();

				expect( variables.model.getClient().indexExists( variables.testIndexName ) ).toBeFalse();
			});

		});

	}

}
