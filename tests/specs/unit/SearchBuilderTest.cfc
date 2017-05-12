component extends="coldbox.system.testing.BaseTestCase"{
	
	function beforeAll(){

		this.loadColdbox=true;

		setup();
		
		variables.model = getWirebox().getInstance( "SearchBuilder@cbElasticSearch" );

		variables.testIndexName = lcase("searchBuilderTests");

		variables.model.getClient().deleteIndex( variables.testIndexName );

		//create our new index
		getWirebox()
			.getInstance( "IndexBuilder@cbElasticsearch" )
			.new( 
				name=variables.testIndexName,
				properties={
					"mappings":{
						"testdocs":{
							"_all"       : { "enabled": false },
							"properties" : {
								"title"      : {"type" : "string"},
								"createdTime": {
									"type"  : "date",
									"format": "date_time_no_millis"
								},
							}
						}
					}
				} 
			).save();

	}

	function afterAll(){
		
		variables.model.getClient().deleteIndex( variables.testIndexName );	

		super.afterAll();
	}

	function run(){
		describe( "Performs cbElasticsearch searchBuilder tests", function(){

			it( "Tests new() with no arguments", function(){

				var searchBuilder = variables.model.new();

				expect( searchBuilder ).toBeComponent();

				expect( searchBuilder.getId() ).toBeNull();

				expect( searchBuilder.getQuery() ).toBeStruct();

				expect( structIsEmpty( searchBuilder.getQuery() ) ).toBeTrue();
		
			});

			it( "Tests new() with only index and type arguments", function(){

				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs"
			 	);

				expect( searchBuilder ).toBeComponent();

				expect( searchBuilder.getIndex() ).toBe( variables.testIndexName );
				expect( searchBuilder.getType() ).toBe( "testdocs" );

			});

			it( "Tests new() with a properties struct", function(){

				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs",
					{
						"match":{
							"title":"Foo"
						}
					}
			 	);

				expect( searchBuilder ).toBeComponent();

				expect( searchBuilder.getIndex() ).toBe( variables.testIndexName );
				expect( searchBuilder.getType() ).toBe( "testdocs" );
				expect( searchBuilder.getQuery() ).toBeStruct();
				expect( searchBuilder.getQuery() ).toHaveKey( "match" );

			});

			it( "Tests the match() method", function(){
				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.match( "title", "Foo" );
			 	expect( searchBuilder.getQuery() ).toBeStruct();
				expect( searchBuilder.getQuery() ).toHaveKey( "match" );
				expect( searchBuilder.getQuery().match ).toHaveKey( "title" );
				expect( searchBuilder.getQuery().match.title ).toBe( "Foo" );

			});

			it( "Tests the aggregation() method", function(){

				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.match( "title", "Foo" );
			 	searchBuilder.aggregation( "fullName", {
			 		"terms":{
			 			"script":"firstName + ' ' + lastName"
			 		}
			 	} );

			 	expect( searchBuilder.getAggregations() ).toBeStruct();
			 	expect( searchBuilder.getAggregations() ).toHaveKey( "fullName" );
			 	expect( searchBuilder.getAggregations().fullName ).toHaveKey( "terms" );
			 	expect( searchBuilder.getAggregations().fullName.terms ).toBeStruct();


			});

			it( "Tests the sort() method by providing an array", function(){
				
				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs"
			 	);

			 	var sort = [ 
				 	{
				 		"lastName" : {"order":"asc"}
				 	}
			 	];

			 	searchBuilder.sort( sort );

			 	expect( searchBuilder.getSorting() ).toBeArray();
			 	expect( searchBuilder.getSorting() ).toBe( sort );

			 	//test our dsl conversion to a linked struct
			 	var dsl = searchBuilder.getDSL();
			 	expect( dsl ).toHaveKey( "sort" );
			 	expect( dsl.sort ).toBeStruct();
			 	expect( dsl.sort ).toHaveKey( "lastName" );

			 	expect( getMetaData( dsl.sort ).name ).toBe( "java.util.LinkedHashMap" );

			});

			it( "Tests the sort() method by providing a simple SQL-type string", function(){

				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.sort( "lastName ASC" );

			 	expect( searchBuilder.getSorting() ).toBeArray();
			 	expect( searchBuilder.getSorting()[ 1 ] ).toBeStruct();
			 	expect( searchbuilder.getSorting()[ 1 ] ).toHaveKey( "lastName" );

			 	expect( searchbuilder.getSorting()[ 1 ].lastName ).toBeStruct();
			 	expect( searchbuilder.getSorting()[ 1 ].lastName ).toHaveKey( "order" );
			 	expect( searchbuilder.getSorting()[ 1 ].lastName.order ).toBe( "asc" );


			});

			it( "Tests the sort() method by providing a single field", function(){
				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.sort( "lastName" );

			 	expect( searchBuilder.getSorting() ).toBeArray();
			 	expect( searchBuilder.getSorting()[ 1 ] ).toBeStruct();
			 	expect( searchbuilder.getSorting()[ 1 ] ).toHaveKey( "lastName" );

			 	expect( searchbuilder.getSorting()[ 1 ].lastName ).toBeStruct();
			 	expect( searchbuilder.getSorting()[ 1 ].lastName ).toHaveKey( "order" );
			 	expect( searchbuilder.getSorting()[ 1 ].lastName.order ).toBe( "asc" );
			});

			it( "Tests the sort() method by providing a struct", function(){
				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.sort( {
			 		"lastname" : "asc"
			 	} );

			 	expect( searchBuilder.getSorting() ).toBeArray();
			 	expect( searchBuilder.getSorting()[ 1 ] ).toBeStruct();
			 	expect( searchbuilder.getSorting()[ 1 ] ).toHaveKey( "lastName" );

			 	expect( searchbuilder.getSorting()[ 1 ].lastName ).toBeStruct();
			 	expect( searchbuilder.getSorting()[ 1 ].lastName ).toHaveKey( "order" );
			 	expect( searchbuilder.getSorting()[ 1 ].lastName.order ).toBe( "asc" );
			});

			it( "Tests the default sort() method case of throwing an error", function(){
				
				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs"
			 	);

			 	expect( searchBuilder.sort( variables.model.new() ) ).toThrow();

			});

			it( "Tests the the execute() method", function(){
				
				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs",
					{
						"match":{
							"title":"Foo"
						}
					}
			 	);

			 	var searchResult = searchBuilder.execute();

			 	expect( searchResult ).toBeComponent();



			});

			it( "Tests the deleteAll() method", function(){

				//insert some test documents
				var searchBuilder = variables.model.new( 
					variables.testIndexName,
					"testdocs",
					{
						"match_all":{}
					}
			 	);

			 	expect( searchBuilder.deleteAll() ).toBeTrue()

			});

		});	
	}

}