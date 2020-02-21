component extends="coldbox.system.testing.BaseTestCase"{

    this.loadColdbox=true;

	function beforeAll() {
		super.afterAll();

		setup();

        variables.model = getWirebox().getInstance( "SearchBuilder@cbElasticSearch" );

		variables.testIndexName = lcase("searchBuilderTests");
		variables.model.getClient().deleteIndex( variables.testIndexName );

		// create our new index
		getWirebox()
			.getInstance( "IndexBuilder@cbElasticsearch" )
			.new(
				name = variables.testIndexName,
				properties = {
					"mappings": {
						"testdocs": {
							"_all": { "enabled": false },
							"properties": {
								"title": { "type" : "text" },
								"createdTime": {
									"type": "date",
									"format": "date_time_no_millis"
								}
							}
						}
					}
				}
            )
            .save();
	}

	function afterAll() {
		variables.model.getClient().deleteIndex( variables.testIndexName );
		super.afterAll();
	}

	function run() {
		describe( "Performs cbElasticsearch searchBuilder tests", function() {
			it( "Tests new() with no arguments", function(){

				var searchBuilder = variables.model.new();

				expect( searchBuilder ).toBeComponent();

				expect( searchBuilder.getId() ).toBeNull();

				expect( searchBuilder.getQuery() ).toBeStruct();

				expect( structIsEmpty( searchBuilder.getQuery() ) ).toBeTrue();

            });

            it( "Tests the getDSL() method is an empty struct from new", function() {
                var searchBuilder = variables.model.new();
                // waiting for this to get merged: https://github.com/Ortus-Solutions/TestBox/pull/106
                expect( searchBuilder.getDSL() ).toBeStruct();
                expect( searchBuilder.getDSL() ).toBeEmpty();
            } );

            it( "Tests the getDSL() method does not include query if it is empty", function() {
                var searchBuilder = variables.model.new();
                // waiting for this to get merged: https://github.com/Ortus-Solutions/TestBox/pull/106
                expect( structKeyExists( searchBuilder.getDSL(), "query" ) )
                    .toBeFalse( "The `query` key should not be defined in the dsl" );
            } );

            it( "Tests the getDSL() method does not include from or size if query is empty", function() {
                var searchBuilder = variables.model.new();
                // waiting for this to get merged: https://github.com/Ortus-Solutions/TestBox/pull/106
                expect( structKeyExists( searchBuilder.getDSL(), "from" ) )
                    .toBeFalse( "The `from` key should not be defined in the dsl" );
                expect( structKeyExists( searchBuilder.getDSL(), "size" ) )
                    .toBeFalse( "The `size` key should not be defined in the dsl" );
            } );

            it( "Tests the getDSL() method does not include highlight if it is empty", function() {
                var searchBuilder = variables.model.new();
                // waiting for this to get merged: https://github.com/Ortus-Solutions/TestBox/pull/106
                expect( structKeyExists( searchBuilder.getDSL(), "highlight" ) )
                    .toBeFalse( "The `highlight` key should not be defined in the dsl" );
            } );

            it( "Tests the getDSL() method does not include source if it is empty", function() {
                var searchBuilder = variables.model.new();
                // waiting for this to get merged: https://github.com/Ortus-Solutions/TestBox/pull/106
                expect( structKeyExists( searchBuilder.getDSL(), "_source" ) )
                    .toBeFalse( "The `_source` key should not be defined in the dsl" );
            } );

            it( "Tests the getDSL() method does not include suggest if it is empty", function() {
                var searchBuilder = variables.model.new();
                // waiting for this to get merged: https://github.com/Ortus-Solutions/TestBox/pull/106
                expect( structKeyExists( searchBuilder.getDSL(), "suggest" ) )
                    .toBeFalse( "The `suggest` key should not be defined in the dsl" );
            } );

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

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );

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

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );

            });

            it( "Tests the multiMatch() method", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                var fields = [];
                var value = "Foo";

                searchBuilder.multiMatch(
                    names = fields,
                    value = value
                );

                expect( searchBuilder.getQuery() ).toBeStruct();
                expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
                expect( searchBuilder.getQuery().bool ).toHaveKey( "must" );
                expect( searchBuilder.getQuery().bool.must ).toBeArray();
                expect( searchBuilder.getQuery().bool.must ).toHaveLength( 1 );
                expect( searchBuilder.getQuery().bool.must[ 1 ] ).toHaveKey( "multi_match" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match ).toHaveKey( "query" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match.query ).toBe( "Foo" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match ).toHaveKey( "fields" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match.fields ).toBe( fields );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match ).toHaveKey( "type" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match.type ).toBe( "best_fields" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match ).notToHaveKey( "boost" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match ).notToHaveKey( "minimum_should_match" );

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );
            } );

            it( "Tests the multiMatch() method with extra arguments", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                var fields = [];
                var value = "Foo";
                var boost = 2;
                var type = "cross_fields";
                var minimumShouldMatch = "80%";

                searchBuilder.multiMatch(
                    names = fields,
                    value = value,
                    boost = boost,
                    type = type,
                    minimumShouldMatch = minimumShouldMatch
                );

                expect( searchBuilder.getQuery() ).toBeStruct();
                expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
                expect( searchBuilder.getQuery().bool ).toHaveKey( "must" );
                expect( searchBuilder.getQuery().bool.must ).toBeArray();
                expect( searchBuilder.getQuery().bool.must ).toHaveLength( 1 );
                expect( searchBuilder.getQuery().bool.must[ 1 ] ).toHaveKey( "multi_match" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match ).toHaveKey( "query" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match.query ).toBe( "Foo" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match ).toHaveKey( "fields" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match.fields ).toBe( fields );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match ).toHaveKey( "type" );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match.type ).toBe( type );
                expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match ).toHaveKey( "minimum_should_match" );
				expect( searchBuilder.getQuery().bool.must[ 1 ].multi_match.minimum_should_match ).toBe( minimumShouldMatch );

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );

            } );


			it( "Tests shouldMatch()", function(){
				var searchBuilder = variables.model.new(
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.shouldMatch( "title", "Foo" );

			 	expect( searchBuilder.getQuery() ).toBeStruct();
				expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
				expect( searchBuilder.getQuery().bool ).toHaveKey( "should" );
				expect( searchBuilder.getQuery().bool.should ).toBeArray();
				expect( searchBuilder.getQuery().bool.should[ 1 ] ).toHaveKey("match");
				expect( searchBuilder.getQuery().bool.should[ 1 ].match ).toHaveKey("title");

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );
			});

			it( "Tests mustMatch()", function(){

				var searchBuilder = variables.model.new(
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.mustMatch( "title", "Foo" );

			 	expect( searchBuilder.getQuery() ).toBeStruct();
				expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
				expect( searchBuilder.getQuery().bool ).toHaveKey( "must" );
				expect( searchBuilder.getQuery().bool.must ).toBeArray();
				expect( arrayLen( searchBuilder.getQuery().bool.must ) ).toBe( 1 );
				expect( searchBuilder.getQuery().bool.must[ 1 ] ).toHaveKey( "match" );
				expect( searchBuilder.getQuery().bool.must[ 1 ][ "match" ] ).toBeStruct();
				expect( searchBuilder.getQuery().bool.must[ 1 ][ "match" ] ).toHaveKey("title");

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );

			});

			it( "Tests mustNotMatch()", function(){
				var searchBuilder = variables.model.new(
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.mustNotMatch( "title", "Foo" );

			 	expect( searchBuilder.getQuery() ).toBeStruct();
				expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
				expect( searchBuilder.getQuery().bool ).toHaveKey( "must_not" );
				expect( searchBuilder.getQuery().bool.must_not ).toBeArray();
				expect( arrayLen( searchBuilder.getQuery().bool.must_not ) ).toBe( 1 );
				expect( searchBuilder.getQuery().bool.must_not[ 1 ] ).toHaveKey("match");
				expect( searchBuilder.getQuery().bool.must_not[ 1 ].match ).toHaveKey("title");
				expect( searchBuilder.getQuery().bool.must_not[ 1 ].match.title ).toBe( "Foo" );

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );

			});

            it( "Tests the mustExist() method", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.mustExist( "testkey" );

                expect( searchBuilder.getQuery() ).toBeStruct();
                expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
                expect( searchBuilder.getQuery().bool ).toHaveKey( "must" );
                expect( searchBuilder.getQuery().bool.must ).toBeArray();
                expect( searchBuilder.getQuery().bool.must ).toHaveLength( 1 );
                expect( searchBuilder.getQuery().bool.must[ 1 ] ).toHaveKey( "exists" );
				expect( searchBuilder.getQuery().bool.must[ 1 ].exists ).toBeStruct();
				expect( searchBuilder.getQuery().bool.must[ 1 ].exists ).toHaveKey( "field" );
				expect( searchBuilder.getQuery().bool.must[ 1 ].exists.field ).toBe( "testkey" );

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );

			} );



            it( "Tests the mustNotExist() method", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.mustNotExist( "testkey" );

                expect( searchBuilder.getQuery() ).toBeStruct();
                expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
                expect( searchBuilder.getQuery().bool ).toHaveKey( "must_not" );
                expect( searchBuilder.getQuery().bool.must_not ).toBeArray();
                expect( searchBuilder.getQuery().bool.must_not ).toHaveLength( 1 );
                expect( searchBuilder.getQuery().bool.must_not[ 1 ] ).toHaveKey( "exists" );
				expect( searchBuilder.getQuery().bool.must_not[ 1 ].exists ).toBeStruct();
				expect( searchBuilder.getQuery().bool.must_not[ 1 ].exists ).toHaveKey( "field" );
				expect( searchBuilder.getQuery().bool.must_not[ 1 ].exists.field ).toBe( "testkey" );

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );
            } );

			it( "Tests disjunction()", function(){

			});

			it( "Tests the aggregation() method", function(){

				var searchBuilder = variables.model.new(
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.match( "title", "Foo" );
			 	searchBuilder.aggregation( "titles", {
			 		"terms":{
						"field" = "title.keyword",
						"size" = 20000,
						"order" : { "_key" : "asc" }
			 		}
			 	} );

			 	expect( searchBuilder.getAggregations() ).toBeStruct();
			 	expect( searchBuilder.getAggregations() ).toHaveKey( "titles" );
			 	expect( searchBuilder.getAggregations().titles ).toHaveKey( "terms" );
			 	expect( searchBuilder.getAggregations().titles.terms ).toBeStruct();

				 expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );


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

			it( "Tests the the count() method", function(){

				var searchBuilder = variables.model.new(
					variables.testIndexName,
					"testdocs",
					{
						"match":{
							"title":"Foo"
						}
					}
			 	);

			 	var docCount = searchBuilder.count();

			 	expect( docCount ).toBeNumeric();

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

				 expect( searchResult ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );

            });

            it( "Tests the terms() method", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.terms( "title", "Foo,Bar" );

                expect( searchBuilder.getQuery() ).toBeStruct();
                expect( searchBuilder.getQuery() ).toHaveKey( "terms" );
                expect( searchBuilder.getQuery().terms ).toBe( { "title" : [ "Foo", "Bar" ] } );

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );
            } );

            it( "Tests the filterTerm() method", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.filterTerm( "title", "Foo" );

                expect( searchBuilder.getQuery() ).toBeStruct();
                expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
                expect( searchBuilder.getQuery().bool ).toHaveKey( "filter" );
                expect( searchBuilder.getQuery().bool.filter ).toHaveKey( "bool" );
                expect( searchBuilder.getQuery().bool.filter.bool ).toHaveKey( "must" );
                expect( searchBuilder.getQuery().bool.filter.bool.must ).toBeArray();
                expect( searchBuilder.getQuery().bool.filter.bool.must ).toHaveLength( 1 );
                expect( searchBuilder.getQuery().bool.filter.bool.must[ 1 ] ).toBeStruct();
                expect( searchBuilder.getQuery().bool.filter.bool.must[ 1 ] ).toHaveKey( "term" );
                expect( searchBuilder.getQuery().bool.filter.bool.must[ 1 ].term ).toBe( { "title" : "Foo" } );

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );
            } );

            it( "Tests the filterTerms() method with a single argument", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.filterTerms( "title", "Foo" );

                expect( searchBuilder.getQuery() ).toBeStruct();
                expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
                expect( searchBuilder.getQuery().bool ).toHaveKey( "filter" );
                expect( searchBuilder.getQuery().bool.filter ).toHaveKey( "bool" );
                expect( searchBuilder.getQuery().bool.filter.bool ).toHaveKey( "must" );
                expect( searchBuilder.getQuery().bool.filter.bool.must ).toBeArray();
                expect( searchBuilder.getQuery().bool.filter.bool.must ).toHaveLength( 1 );
                expect( searchBuilder.getQuery().bool.filter.bool.must[ 1 ] ).toBeStruct();
                expect( searchBuilder.getQuery().bool.filter.bool.must[ 1 ] ).toHaveKey( "term" );
                expect( searchBuilder.getQuery().bool.filter.bool.must[ 1 ].term ).toBe( { "title" : "Foo" } );

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );
            } );


			it( "Tests the filterTerms() method with a list", function(){
				var searchBuilder = variables.model.new(
					variables.testIndexName,
					"testdocs"
			 	);

			 	searchBuilder.filterTerms( "title", "Foo,Bar" );

			 	expect( searchBuilder.getQuery() ).toBeStruct();
				expect( searchBuilder.getQuery() ).toHaveKey( "bool" );
				expect( searchBuilder.getQuery().bool ).toHaveKey( "filter" );
				expect( searchBuilder.getQuery().bool.filter ).toHaveKey( "bool" );
				expect( searchBuilder.getQuery().bool.filter.bool ).toHaveKey( "must" );
				expect( searchBuilder.getQuery().bool.filter.bool.must ).toBeArray();
				expect( searchBuilder.getQuery().bool.filter.bool.must ).toHaveLength( 1 );
				expect( searchBuilder.getQuery().bool.filter.bool.must[ 1 ] ).toBeStruct();
				expect( searchBuilder.getQuery().bool.filter.bool.must[ 1 ] ).toHaveKey( "terms" );
				expect( searchBuilder.getQuery().bool.filter.bool.must[ 1 ].terms ).toBe( { "title" : [ "Foo", "Bar" ] } );

				expect( searchBuilder.execute() ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );
			});

			it( "Tests the deleteAll() method", function(){

				//sleep for 1.5 seconds to ensure our index is ready for a deleteAll
				sleep( 1500 );

				//insert some test documents
				var searchBuilder = variables.model.new(
					variables.testIndexName,
					"testdocs",
					{
						"match_all":{}
					}
			 	);

				expect( searchBuilder.deleteAll() ).toBeStruct()
				 						 .toHaveKey( "deleted" );

            });

            it( "Tests the setSource() method", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.setSource( {
                    "includes" = [ "obj1.*", "obj2.*" ],
                    "excludes" = [ "*.description" ]
                } );

                expect( searchBuilder.getDSL() ).toBeStruct();
                expect( searchBuilder.getDSL() ).toHaveKey( "_source" );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "includes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "includes" ] ).toBe( [ "obj1.*", "obj2.*" ] );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "excludes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "excludes" ] ).toBe( [ "*.description" ] );
            } );

            it( "Tests the setSource() method with a boolean value", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.setSource( false );

                expect( searchBuilder.getDSL() ).toBeStruct();
                expect( searchBuilder.getDSL() ).toHaveKey( "_source" );
                expect( searchBuilder.getDSL()[ "_source" ] ).toBe( false );
            } );

            it( "Tests the setSource() method with a null value", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.setSource( javacast( "null", 0 ) );

                // waiting for this to get merged: https://github.com/Ortus-Solutions/TestBox/pull/106
                expect( structKeyExists( searchBuilder.getDSL(), "_source" ) )
                    .toBeFalse( "The `_source` key should not exist in the dsl." );
            } );

            it( "Tests the setSource() method fills in excludes if left out", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.setSource( {
                    "includes" = [ "obj1.*", "obj2.*" ]
                } );

                expect( searchBuilder.getDSL() ).toBeStruct();
                expect( searchBuilder.getDSL() ).toHaveKey( "_source" );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "includes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "includes" ] ).toBe( [ "obj1.*", "obj2.*" ] );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "excludes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "excludes" ] ).toBe( [] );
            } );

            it( "Tests the setSource() method fills in includes if left out", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.setSource( {
                    "excludes" = [ "*.description" ]
                } );

                expect( searchBuilder.getDSL() ).toBeStruct();
                expect( searchBuilder.getDSL() ).toHaveKey( "_source" );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "includes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "includes" ] ).toBe( [] );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "excludes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "excludes" ] ).toBe( [ "*.description" ] );
            } );

            it( "Tests the setSourceIncludes() method", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.setSourceIncludes( [ "obj1.*", "obj2.*" ] );

                expect( searchBuilder.getDSL() ).toBeStruct();
                expect( searchBuilder.getDSL() ).toHaveKey( "_source" );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "includes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "includes" ] ).toBe( [ "obj1.*", "obj2.*" ] );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "excludes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "excludes" ] ).toBe( [] );
            } );

            it( "Tests the setSourceExcludes() method", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.setSourceExcludes( [ "*.description" ] );

                expect( searchBuilder.getDSL() ).toBeStruct();
                expect( searchBuilder.getDSL() ).toHaveKey( "_source" );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "includes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "includes" ] ).toBe( [] );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "excludes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "excludes" ] ).toBe( [ "*.description" ] );
            } );

            it( "Tests the both the setSourceIncludes() and setSourceExcludes() methods", function() {
                var searchBuilder = variables.model.new(
                    variables.testIndexName,
                    "testdocs"
                );

                searchBuilder.setSourceIncludes( [ "obj1.*", "obj2.*" ] );
                searchBuilder.setSourceExcludes( [ "*.description" ] );

                expect( searchBuilder.getDSL() ).toBeStruct();
                expect( searchBuilder.getDSL() ).toHaveKey( "_source" );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "includes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "includes" ] ).toBe( [ "obj1.*", "obj2.*" ] );
                expect( searchBuilder.getDSL()[ "_source" ] ).toHaveKey( "excludes" );
                expect( searchBuilder.getDSL()[ "_source" ][ "excludes" ] ).toBe( [ "*.description" ] );
            } );

            describe( "suggestions", function() {
                describe( "suggestTerm", function() {
                    it( "can add a term suggestion for a field", function() {
                        var searchBuilder = variables.model.new(
                            variables.testIndexName,
                            "testdocs"
                        );

                        var text = "misspellde";
                        var suggestionName = "suggestionName";
                        var fieldName = "fieldName";

                        searchBuilder.suggestTerm(
                            text = text,
                            name = suggestionName,
                            field = fieldName,
                            options = {}
                        );

                        var dsl = searchBuilder.getDSL();
                        expect( dsl ).toBeStruct();
                        expect( dsl ).toHaveKey( "suggest" );
                        expect( dsl.suggest ).toBeStruct();
                        expect( dsl.suggest ).toHaveLength( 1 );
                        expect( dsl.suggest ).toHaveKey( suggestionName );
                        expect( dsl.suggest[ suggestionName ] ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ] ).toHaveLength( 2 );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "text" );
                        expect( dsl.suggest[ suggestionName ].text ).toBe( text );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "term" );
                        expect( dsl.suggest[ suggestionName ].term ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ].term ).toHaveLength( 1 );
                        expect( dsl.suggest[ suggestionName ].term ).toHaveKey( "field" );
                        expect( dsl.suggest[ suggestionName ].term.field ).toBe( fieldName );
                    } );

                    it( "uses the suggestionName as the fieldName if not provided", function() {
                        var searchBuilder = variables.model.new(
                            variables.testIndexName,
                            "testdocs"
                        );

                        var text = "misspellde";
                        var suggestionName = "suggestionName";

                        searchBuilder.suggestTerm(
                            text = text,
                            name = suggestionName,
                            options = {}
                        );

                        var dsl = searchBuilder.getDSL();
                        expect( dsl ).toBeStruct();
                        expect( dsl ).toHaveKey( "suggest" );
                        expect( dsl.suggest ).toBeStruct();
                        expect( dsl.suggest ).toHaveLength( 1 );
                        expect( dsl.suggest ).toHaveKey( suggestionName );
                        expect( dsl.suggest[ suggestionName ] ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ] ).toHaveLength( 2 );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "text" );
                        expect( dsl.suggest[ suggestionName ].text ).toBe( text );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "term" );
                        expect( dsl.suggest[ suggestionName ].term ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ].term ).toHaveLength( 1 );
                        expect( dsl.suggest[ suggestionName ].term ).toHaveKey( "field" );
                        expect( dsl.suggest[ suggestionName ].term.field ).toBe( suggestionName );
                    } );

                    it( "mixes in the options to the definition", function() {
                        var searchBuilder = variables.model.new(
                            variables.testIndexName,
                            "testdocs"
                        );

                        var text = "misspellde";
                        var suggestionName = "suggestionName";
                        var size = 5;

                        searchBuilder.suggestTerm(
                            text = text,
                            name = suggestionName,
                            options = {
                                "size": size
                            }
                        );

                        var dsl = searchBuilder.getDSL();
                        expect( dsl ).toBeStruct();
                        expect( dsl ).toHaveKey( "suggest" );
                        expect( dsl.suggest ).toBeStruct();
                        expect( dsl.suggest ).toHaveLength( 1 );
                        expect( dsl.suggest ).toHaveKey( suggestionName );
                        expect( dsl.suggest[ suggestionName ] ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ] ).toHaveLength( 2 );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "text" );
                        expect( dsl.suggest[ suggestionName ].text ).toBe( text );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "term" );
                        expect( dsl.suggest[ suggestionName ].term ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ].term ).toHaveLength( 2 );
                        expect( dsl.suggest[ suggestionName ].term ).toHaveKey( "field" );
                        expect( dsl.suggest[ suggestionName ].term.field ).toBe( suggestionName );
                        expect( dsl.suggest[ suggestionName ].term ).toHaveKey( "size" );
                        expect( dsl.suggest[ suggestionName ].term.size ).toBe( size );
                    } );
                } );

                describe( "suggestPhrase", function() {
                    it( "can add a phrase suggestion for a field", function() {
                        var searchBuilder = variables.model.new(
                            variables.testIndexName,
                            "testdocs"
                        );

                        var text = "misspellde phrase";
                        var suggestionName = "suggestionName";
                        var fieldName = "fieldName";

                        searchBuilder.suggestPhrase(
                            text = text,
                            name = suggestionName,
                            field = fieldName,
                            options = {}
                        );

                        var dsl = searchBuilder.getDSL();
                        expect( dsl ).toBeStruct();
                        expect( dsl ).toHaveKey( "suggest" );
                        expect( dsl.suggest ).toBeStruct();
                        expect( dsl.suggest ).toHaveLength( 1 );
                        expect( dsl.suggest ).toHaveKey( suggestionName );
                        expect( dsl.suggest[ suggestionName ] ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ] ).toHaveLength( 2 );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "text" );
                        expect( dsl.suggest[ suggestionName ].text ).toBe( text );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "phrase" );
                        expect( dsl.suggest[ suggestionName ].phrase ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ].phrase ).toHaveLength( 1 );
                        expect( dsl.suggest[ suggestionName ].phrase ).toHaveKey( "field" );
                        expect( dsl.suggest[ suggestionName ].phrase.field ).toBe( fieldName );
                    } );

                    it( "uses the suggestionName as the fieldName if not provided", function() {
                        var searchBuilder = variables.model.new(
                            variables.testIndexName,
                            "testdocs"
                        );

                        var text = "misspellde phrase";
                        var suggestionName = "suggestionName";

                        searchBuilder.suggestPhrase(
                            text = text,
                            name = suggestionName,
                            options = {}
                        );

                        var dsl = searchBuilder.getDSL();
                        expect( dsl ).toBeStruct();
                        expect( dsl ).toHaveKey( "suggest" );
                        expect( dsl.suggest ).toBeStruct();
                        expect( dsl.suggest ).toHaveLength( 1 );
                        expect( dsl.suggest ).toHaveKey( suggestionName );
                        expect( dsl.suggest[ suggestionName ] ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ] ).toHaveLength( 2 );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "text" );
                        expect( dsl.suggest[ suggestionName ].text ).toBe( text );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "phrase" );
                        expect( dsl.suggest[ suggestionName ].phrase ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ].phrase ).toHaveLength( 1 );
                        expect( dsl.suggest[ suggestionName ].phrase ).toHaveKey( "field" );
                        expect( dsl.suggest[ suggestionName ].phrase.field ).toBe( suggestionName );
                    } );

                    it( "mixes in the options to the definition", function() {
                        var searchBuilder = variables.model.new(
                            variables.testIndexName,
                            "testdocs"
                        );

                        var text = "misspellde phrase";
                        var suggestionName = "suggestionName";
                        var size = 5;

                        searchBuilder.suggestPhrase(
                            text = text,
                            name = suggestionName,
                            options = {
                                "size": size
                            }
                        );

                        var dsl = searchBuilder.getDSL();
                        expect( dsl ).toBeStruct();
                        expect( dsl ).toHaveKey( "suggest" );
                        expect( dsl.suggest ).toBeStruct();
                        expect( dsl.suggest ).toHaveLength( 1 );
                        expect( dsl.suggest ).toHaveKey( suggestionName );
                        expect( dsl.suggest[ suggestionName ] ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ] ).toHaveLength( 2 );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "text" );
                        expect( dsl.suggest[ suggestionName ].text ).toBe( text );
                        expect( dsl.suggest[ suggestionName ] ).toHaveKey( "phrase" );
                        expect( dsl.suggest[ suggestionName ].phrase ).toBeStruct();
                        expect( dsl.suggest[ suggestionName ].phrase ).toHaveLength( 2 );
                        expect( dsl.suggest[ suggestionName ].phrase ).toHaveKey( "field" );
                        expect( dsl.suggest[ suggestionName ].phrase.field ).toBe( suggestionName );
                        expect( dsl.suggest[ suggestionName ].phrase ).toHaveKey( "size" );
                        expect( dsl.suggest[ suggestionName ].phrase.size ).toBe( size );
                    } );
                } );

                describe( "suggestCompletion", function() {
                    it( "can add a completion for a field", function() {
                        var searchBuilder = variables.model.new(
                            variables.testIndexName,
                            "testdocs"
                        );

                        var prefix = "search term";
                        var completionName = "completionName";
                        var fieldName = "fieldName";

                        searchBuilder.suggestCompletion(
                            text = prefix,
                            name = completionName,
                            field = fieldName,
                            options = {}
                        );

                        var dsl = searchBuilder.getDSL();
                        expect( dsl ).toBeStruct();
                        expect( dsl ).toHaveKey( "suggest" );
                        expect( dsl.suggest ).toBeStruct();
                        expect( dsl.suggest ).toHaveLength( 1 );
                        expect( dsl.suggest ).toHaveKey( completionName );
                        expect( dsl.suggest[ completionName ] ).toBeStruct();
                        expect( dsl.suggest[ completionName ] ).toHaveLength( 2 );
                        expect( dsl.suggest[ completionName ] ).toHaveKey( "prefix" );
                        expect( dsl.suggest[ completionName ].prefix ).toBe( prefix );
                        expect( dsl.suggest[ completionName ] ).toHaveKey( "completion" );
                        expect( dsl.suggest[ completionName ].completion ).toBeStruct();
                        expect( dsl.suggest[ completionName ].completion ).toHaveLength( 1 );
                        expect( dsl.suggest[ completionName ].completion ).toHaveKey( "field" );
                        expect( dsl.suggest[ completionName ].completion.field ).toBe( fieldName );
                    } );

                    it( "uses the completion name as the field name if not provided", function() {
                        var searchBuilder = variables.model.new(
                            variables.testIndexName,
                            "testdocs"
                        );

                        var prefix = "search term";
                        var completionName = "completionName";

                        searchBuilder.suggestCompletion(
                            text = prefix,
                            name = completionName,
                            options = {}
                        );

                        var dsl = searchBuilder.getDSL();
                        expect( dsl ).toBeStruct();
                        expect( dsl ).toHaveKey( "suggest" );
                        expect( dsl.suggest ).toBeStruct();
                        expect( dsl.suggest ).toHaveLength( 1 );
                        expect( dsl.suggest ).toHaveKey( completionName );
                        expect( dsl.suggest[ completionName ] ).toBeStruct();
                        expect( dsl.suggest[ completionName ] ).toHaveLength( 2 );
                        expect( dsl.suggest[ completionName ] ).toHaveKey( "prefix" );
                        expect( dsl.suggest[ completionName ].prefix ).toBe( prefix );
                        expect( dsl.suggest[ completionName ] ).toHaveKey( "completion" );
                        expect( dsl.suggest[ completionName ].completion ).toBeStruct();
                        expect( dsl.suggest[ completionName ].completion ).toHaveLength( 1 );
                        expect( dsl.suggest[ completionName ].completion ).toHaveKey( "field" );
                        expect( dsl.suggest[ completionName ].completion.field ).toBe( completionName );
                    } );

                    it( "mixes in options to the completion struct", function() {
                        var searchBuilder = variables.model.new(
                            variables.testIndexName,
                            "testdocs"
                        );

                        var prefix = "search term";
                        var completionName = "completionName";

                        searchBuilder.suggestCompletion(
                            text = prefix,
                            name = completionName,
                            options = {
                                "fuzzy": true
                            }
                        );

                        var dsl = searchBuilder.getDSL();
                        expect( dsl ).toBeStruct();
                        expect( dsl ).toHaveKey( "suggest" );
                        expect( dsl.suggest ).toBeStruct();
                        expect( dsl.suggest ).toHaveLength( 1 );
                        expect( dsl.suggest ).toHaveKey( completionName );
                        expect( dsl.suggest[ completionName ] ).toBeStruct();
                        expect( dsl.suggest[ completionName ] ).toHaveLength( 2 );
                        expect( dsl.suggest[ completionName ] ).toHaveKey( "prefix" );
                        expect( dsl.suggest[ completionName ].prefix ).toBe( prefix );
                        expect( dsl.suggest[ completionName ] ).toHaveKey( "completion" );
                        expect( dsl.suggest[ completionName ].completion ).toBeStruct();
                        expect( dsl.suggest[ completionName ].completion ).toHaveLength( 2 );
                        expect( dsl.suggest[ completionName ].completion ).toHaveKey( "field" );
                        expect( dsl.suggest[ completionName ].completion.field ).toBe( completionName );
                        expect( dsl.suggest[ completionName ].completion ).toHaveKey( "fuzzy" );
                        expect( dsl.suggest[ completionName ].completion.fuzzy ).toBe( true );
                    } );
                } );

                it( "can mix in many different suggestions", function() {
                    var searchBuilder = variables.model.new(
                        variables.testIndexName,
                        "testdocs"
                    );

                    var termText = "misspellde";
                    var termSuggestionName = "termSuggestionName";
                    searchBuilder.suggestTerm( termText, termSuggestionName );

                    var phraseText = "misspellde phrase";
                    var phraseSuggestionName = "phraseSuggestionName";
                    searchBuilder.suggestPhrase( phraseText, phraseSuggestionName );

                    var completionText = "search term";
                    var completionNameOne = "completionNameOne";
                    searchBuilder.suggestCompletion( completionText, completionNameOne );
                    var completionNameTwo = "completionNameTwo";
                    searchBuilder.suggestCompletion( completionText, completionNameTwo );

                    var dsl = searchBuilder.getDSL();
                    expect( dsl ).toBeStruct();
                    expect( dsl ).toHaveKey( "suggest" );
                    expect( dsl.suggest ).toBeStruct();
                    expect( dsl.suggest ).toHaveLength( 4 );

                    expect( dsl.suggest ).toHaveKey( termSuggestionName );
                    expect( dsl.suggest[ termSuggestionName ] ).toBeStruct();
                    expect( dsl.suggest[ termSuggestionName ] ).toHaveLength( 2 );
                    expect( dsl.suggest[ termSuggestionName ] ).toHaveKey( "text" );
                    expect( dsl.suggest[ termSuggestionName ].text ).toBe( termText );
                    expect( dsl.suggest[ termSuggestionName ] ).toHaveKey( "term" );
                    expect( dsl.suggest[ termSuggestionName ].term ).toBeStruct();
                    expect( dsl.suggest[ termSuggestionName ].term ).toHaveLength( 1 );
                    expect( dsl.suggest[ termSuggestionName ].term ).toHaveKey( "field" );
                    expect( dsl.suggest[ termSuggestionName ].term.field ).toBe( termSuggestionName );

                    expect( dsl.suggest ).toHaveKey( phraseSuggestionName );
                    expect( dsl.suggest[ phraseSuggestionName ] ).toBeStruct();
                    expect( dsl.suggest[ phraseSuggestionName ] ).toHaveLength( 2 );
                    expect( dsl.suggest[ phraseSuggestionName ] ).toHaveKey( "text" );
                    expect( dsl.suggest[ phraseSuggestionName ].text ).toBe( phraseText );
                    expect( dsl.suggest[ phraseSuggestionName ] ).toHaveKey( "phrase" );
                    expect( dsl.suggest[ phraseSuggestionName ].phrase ).toBeStruct();
                    expect( dsl.suggest[ phraseSuggestionName ].phrase ).toHaveLength( 1 );
                    expect( dsl.suggest[ phraseSuggestionName ].phrase ).toHaveKey( "field" );
                    expect( dsl.suggest[ phraseSuggestionName ].phrase.field ).toBe( phraseSuggestionName );

                    expect( dsl.suggest ).toHaveKey( completionNameOne );
                    expect( dsl.suggest[ completionNameOne ] ).toBeStruct();
                    expect( dsl.suggest[ completionNameOne ] ).toHaveLength( 2 );
                    expect( dsl.suggest[ completionNameOne ] ).toHaveKey( "prefix" );
                    expect( dsl.suggest[ completionNameOne ].prefix ).toBe( completionText );
                    expect( dsl.suggest[ completionNameOne ] ).toHaveKey( "completion" );
                    expect( dsl.suggest[ completionNameOne ].completion ).toBeStruct();
                    expect( dsl.suggest[ completionNameOne ].completion ).toHaveLength( 1 );
                    expect( dsl.suggest[ completionNameOne ].completion ).toHaveKey( "field" );
                    expect( dsl.suggest[ completionNameOne ].completion.field ).toBe( completionNameOne );

                    expect( dsl.suggest ).toHaveKey( completionNameTwo );
                    expect( dsl.suggest[ completionNameTwo ] ).toBeStruct();
                    expect( dsl.suggest[ completionNameTwo ] ).toHaveLength( 2 );
                    expect( dsl.suggest[ completionNameTwo ] ).toHaveKey( "prefix" );
                    expect( dsl.suggest[ completionNameTwo ].prefix ).toBe( completionText );
                    expect( dsl.suggest[ completionNameTwo ] ).toHaveKey( "completion" );
                    expect( dsl.suggest[ completionNameTwo ].completion ).toBeStruct();
                    expect( dsl.suggest[ completionNameTwo ].completion ).toHaveLength( 1 );
                    expect( dsl.suggest[ completionNameTwo ].completion ).toHaveKey( "field" );
                    expect( dsl.suggest[ completionNameTwo ].completion.field ).toBe( completionNameTwo );
                } );
            } );
		} );
	}

}
