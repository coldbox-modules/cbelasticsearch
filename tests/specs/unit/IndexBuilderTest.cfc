component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

		setup();

		variables.model = getWirebox().getInstance( "IndexBuilder@cbElasticSearch" );

		variables.testIndexName = lCase( "IndexBuilderTests" );

		variables.model.getClient().deleteIndex( variables.testIndexName );
	}

	function afterAll(){
		// variables.model.getClient().deleteIndex( variables.testIndexName );

		super.afterAll();
	}

	function run(){
		describe( "Performs cbElasticsearch IndexBuilder tests", function(){
			it( "Tests new() with no arguments", function(){
				var newIndex = variables.model.new();

				expect( newIndex.getMappings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getMappings() ) ).toBeTrue();

				expect( newIndex.getAliases() ).toBeStruct();
				expect( structIsEmpty( newIndex.getAliases() ) ).toBeTrue();

				expect( newIndex.getSettings() )
					.toBeStruct()
					.toHaveKey( "number_of_shards" )
					.toHaveKey( "number_of_replicas" );

				expect( newIndex.getSettings().number_of_shards ).toBe(
					newIndex.getConfig().get( "defaultIndexShards" )
				);
				expect( newIndex.getSettings().number_of_replicas ).toBe(
					newIndex.getConfig().get( "defaultIndexReplicas" )
				);
			} );

			it( "Tests new() with a full properties struct", function(){
				var indexSettings = {
					"mappings" : {
						"testdocs" : {
							"_all"       : { "enabled" : false },
							"properties" : {
								"title"       : { "type" : "text" },
								"createdTime" : { "type" : "date", "format" : "date_time_no_millis" }
							}
						}
					},
					"aliases"  : { "testalias" : {} },
					"settings" : { "number_of_shards" : 5, "number_of_replicas" : 2 }
				};

				var newIndex = variables.model.new( name = variables.testIndexName, properties = indexSettings );

				expect( newIndex.getSettings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getSettings() ) ).toBeFalse();
				expect( newIndex.getMappings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getAliases() ) ).toBeFalse();
				expect( newIndex.getAliases() ).toBeStruct();
				expect( structIsEmpty( newIndex.getMappings() ) ).toBeFalse();
				expect( newIndex.getIndexName() ).toBe( variables.testIndexName );
			} );

			it( "Tests that a partial settings struct passed to new() will not override the defaults", function(){
				var indexSettings = {
					"mappings" : {
						"testdocs" : {
							"_all"       : { "enabled" : false },
							"properties" : {
								"title"       : { "type" : "text" },
								"createdTime" : { "type" : "date", "format" : "date_time_no_millis" }
							}
						}
					},
					"aliases"  : { "testalias" : {} },
					"settings" : { "index.mapping.total_fields.limit" : 500000 }
				};

				var newIndex = variables.model.new( name = variables.testIndexName, properties = indexSettings );

				expect( newIndex.getSettings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getSettings() ) ).toBeFalse();
				expect( newIndex.getMappings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getAliases() ) ).toBeFalse();
				expect( newIndex.getAliases() ).toBeStruct();
				expect( structIsEmpty( newIndex.getMappings() ) ).toBeFalse();
				expect( newIndex.getIndexName() ).toBe( variables.testIndexName );

				expect( newIndex.getSettings() ).toHaveKey( "number_of_shards" ).toHaveKey( "number_of_replicas" );
			} );

			it( "Tests new() with a callback for the builder syntax", function(){
				var newIndex = variables.model.new(
					name       = variables.testIndexName,
					properties = function( builder ){
						return {
							"testdocs" : builder.create( function( mapping ){
								mapping.text( "title" );
								mapping.date( "createdTime" ).format( "date_time_no_millis" );
							} )
						};
					},
					settings = { "number_of_shards" : 5, "number_of_replicas" : 2 }
				);

				expect( newIndex.getSettings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getSettings() ) ).toBeFalse();
				expect( newIndex.getMappings() ).toBeStruct();
				expect( structIsEmpty( newIndex.getMappings() ) ).toBeFalse();
				expect( newIndex.getIndexName() ).toBe( variables.testIndexName );
				expect( newIndex.getMappings() ).notToBeEmpty();
				expect( newIndex.getMappings() ).toHaveKey( "testdocs" );
			} );

			it( "Tests the save() method ability to create an index", function(){
				// create our new index
				var indexSettings = {
					"mappings" : {
						"testdocs" : {
							"_all"       : { "enabled" : false },
							"properties" : {
								"title"       : { "type" : "text" },
								"createdTime" : { "type" : "date", "format" : "date_time_no_millis" }
							}
						}
					},
					"aliases" : { "testalias" : {} }
				};

				var newIndex = variables.model.new( name = variables.testIndexName, properties = indexSettings );

				expect( newIndex.save() ).toBeTrue();

				expect( variables.model.getClient().indexExists( variables.testIndexName ) ).toBeTrue();
			} );

			it( "Tests the patch() method ability to update an index mapping", function(){
				// updated mapping for the index
				var indexSettings = {
					"mappings" : {
						"testdocs" : {
							"_all"       : { "enabled" : false },
							"properties" : {
								"title"       : { "type" : "text" },
								"authorName"  : { "type" : "text" },
								"createdTime" : { "type" : "date", "format" : "date_time_no_millis" }
							}
						}
					},
					"aliases" : { "testalias" : {} }
				};

				var newIndex = variables.model.patch( name = variables.testIndexName, properties = indexSettings );

				// expect( newIndex.getMappings().testdocs.properties ).toHaveKey( "authorName" );
			} );

			it( "Tests the patch() method ability to update index settings", function(){
				var newIndex = variables.model.patch(
					name     = variables.testIndexName,
					settings = { "refresh_interval" : "20s" }
				);

				expect( variables.model.getClient().indexExists( variables.testIndexName ) ).toBeTrue();


				var newIndex = variables.model.patch(
					name       = variables.testIndexName,
					properties = { "settings" : { "refresh_interval" : "1s" } }
				);
			} );

			it( "Tests the ability to reset the index builder", function(){
				variables.model.reset();

				expect( variables.model.getMappings() ).toBeStruct();
				expect( structIsEmpty( variables.model.getMappings() ) ).toBeTrue();

				expect( variables.model.getSettings() )
					.toBeStruct()
					.toHaveKey( "number_of_shards" )
					.toHaveKey( "number_of_replicas" );

				expect( variables.model.getSettings().number_of_shards ).toBe(
					variables.model.getConfig().get( "defaultIndexShards" )
				);
				expect( variables.model.getSettings().number_of_replicas ).toBe(
					variables.model.getConfig().get( "defaultIndexReplicas" )
				);
			} );

			it( "Tests the delete() methods ability to remove an index", function(){
				variables.model.new( variables.testIndexName ).delete();

				expect( variables.model.getClient().indexExists( variables.testIndexName ) ).toBeFalse();
			} );
			it( "Tests the delete() method with an index name argument", function(){
				var shortLivedIndex = getWirebox().getInstance( "IndexBuilder@cbElasticSearch" ).new( variables.testIndexName );
				shortLivedIndex.save();
				expect( shortLivedIndex.getClient().indexExists( shortLivedIndex.getIndexName() ) ).toBeTrue();
				
				getWirebox().getInstance( "IndexBuilder@cbElasticSearch" ).delete( shortLivedIndex.getIndexName() );

				expect( shortLivedIndex.getClient().indexExists( shortLivedIndex.getIndexName() ) ).toBeFalse();
			} );
		} );
	}

}
