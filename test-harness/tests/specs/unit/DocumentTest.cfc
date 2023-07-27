component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

		super.beforeAll();

		variables.model = getWirebox().getInstance( "Document@cbElasticSearch" );

		variables.testIndexName = lCase( "cbElasticSearch-DocumentTests" );

		variables.model.getClient().deleteIndex( variables.testIndexName );

		var indexSettings = {
			"mappings" : {
				"testdocs" : {
					"_all"       : { "enabled" : false },
					"properties" : {
						"title"       : { "type" : "text" },
						"createdTime" : { "type" : "date", "format" : "date_time_no_millis" }
					}
				}
			}
		};

		getWirebox()
			.getInstance( "IndexBuilder@cbElasticsearch" )
			.new( name = variables.testIndexName, properties = indexSettings )
			.save();
	}

	function afterAll(){
		variables.model.getClient().deleteIndex( variables.testIndexName );

		super.afterAll();
	}

	function run(){
		describe( "Performs cbElasticsearch Document tests", function(){
			it( "Tests new() with only an index argument", function(){
				expect( variables.model.new( variables.testIndexName ).getIndex() ).toBe( variables.testIndexName );
			} );

			it( "Tests the ability to reset a document", function(){
				variables.model.new(
					variables.testIndexName,
					"testdocs",
					{ "foo" : "bar" }
				);

				expect( variables.model.getMemento() ).toBeStruct();
				expect( variables.model.getMemento() ).toHaveKey( "foo" );

				variables.model.reset();

				expect( structIsEmpty( variables.model.getMemento() ) ).toBeTrue();
			} );


			it( "Tests setters with get()", function(){
				var testDocument = {
					"_id"         : createUUID(),
					"title"       : "My Test Document",
					"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
				};

				var created = variables.model
					.new(
						variables.testIndexName,
						"testdocs",
						testDocument
					)
					.save();

				expect( created ).toBeComponent();
				variables.model.reset();

				var found = variables.model
					.setIndex( variables.testIndexName )
					.setId( testDocument[ "_id" ] )
					.setType( "testdocs" )
					.get();

				expect( isNull( found ) ).toBeFalse();
			} );


			it( "Tests the ability to persist a Document via save()", function(){
				var testDocument = {
					"_id"         : createUUID(),
					"title"       : "My Test Document",
					"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
				};

				var created = variables.model
					.new(
						variables.testIndexName,
						"testdocs",
						testDocument
					)
					.save();

				expect( created ).toBeComponent();
				variables.model.reset();

				var found = variables.model.get(
					testDocument[ "_id" ],
					variables.testIndexName,
					"testdocs"
				);

				expect( isNull( found ) ).toBeFalse();
			} );

			it( "can save a document with a space in the id", function(){
				var testDocument = {
					"_id"         : "id with spaces",
					"title"       : "My Test Document",
					"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
				};

				var created = variables.model
					.new(
						variables.testIndexName,
						"testdocs",
						testDocument
					)
					.save();

				expect( created ).toBeComponent();
				expect( created.getId() ).toBe( testDocument[ "_id" ] );
				variables.model.reset();

				var found = variables.model.get(
					testDocument[ "_id" ],
					variables.testIndexName,
					"testdocs"
				);

				expect( isNull( found ) ).toBeFalse();
			} );
		} );
	}

}
