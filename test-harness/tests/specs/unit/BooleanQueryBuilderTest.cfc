component extends="coldbox.system.testing.BaseTestCase" {

	this.loadColdbox = true;

	function beforeAll(){
		super.beforeAll();

		variables.model = getWirebox().getInstance( "BooleanQueryBuilder@cbElasticSearch" );
		variables.searchBuilder = getWirebox().getInstance( "SearchBuilder@cbElasticSearch" );

		variables.testIndexName = lCase( "booleanQueryBuilderTests" );
		variables.searchBuilder.getClient().deleteIndex( variables.testIndexName );

		// create our new index
		getWirebox()
			.getInstance( "IndexBuilder@cbelasticsearch" )
			.new(
				name       = variables.testIndexName,
				properties = {
					"mappings" : {
						"testdocs" : {
							"_all"       : { "enabled" : false },
							"properties" : {
								"title"       : { "type" : "text" },
								"createdTime" : { "type" : "date", "format" : "date_time_no_millis" },
								"price"       : { "type" : "float" },
								"status"      : { "type" : "keyword" }
							}
						}
					}
				}
			)
			.save();
	}

	function afterAll(){
		variables.searchBuilder.getClient().deleteIndex( variables.testIndexName );
		super.afterAll();
	}

	function run(){
		describe( "Performs cbElasticsearch BooleanQueryBuilder fluent API tests", function(){
			
			it( "Tests fluent bool().must().term() placement", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder.bool().must().term( "status", "active" );

				var query = searchBuilder.getQuery();
				expect( query ).toBeStruct().toHaveKey( "bool" );
				expect( query.bool ).toHaveKey( "must" );
				expect( query.bool.must ).toBeArray().toHaveLength( 1 );
				expect( query.bool.must[ 1 ] ).toHaveKey( "term" );
				expect( query.bool.must[ 1 ].term ).toHaveKey( "status" );
				expect( query.bool.must[ 1 ].term.status ).toBe( "active" );
			} );

			it( "Tests fluent bool().should().match() placement", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder.bool().should().match( "title", "elasticsearch" );

				var query = searchBuilder.getQuery();
				expect( query ).toBeStruct().toHaveKey( "bool" );
				expect( query.bool ).toHaveKey( "should" );
				expect( query.bool.should ).toBeArray().toHaveLength( 1 );
				expect( query.bool.should[ 1 ] ).toHaveKey( "match" );
				expect( query.bool.should[ 1 ].match ).toHaveKey( "title" );
				expect( query.bool.should[ 1 ].match.title ).toBe( "elasticsearch" );
			} );

			it( "Tests fluent bool().filter().bool().must().wildcard() nested placement", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder.bool().filter().bool().must().wildcard( "title", "*test*" );

				var query = searchBuilder.getQuery();
				expect( query ).toBeStruct().toHaveKey( "bool" );
				expect( query.bool ).toHaveKey( "filter" );
				expect( query.bool.filter ).toHaveKey( "bool" );
				expect( query.bool.filter.bool ).toHaveKey( "must" );
				expect( query.bool.filter.bool.must ).toBeArray().toHaveLength( 1 );
				expect( query.bool.filter.bool.must[ 1 ] ).toHaveKey( "wildcard" );
				expect( query.bool.filter.bool.must[ 1 ].wildcard ).toHaveKey( "title" );
				expect( query.bool.filter.bool.must[ 1 ].wildcard.title ).toHaveKey( "value" );
				expect( query.bool.filter.bool.must[ 1 ].wildcard.title.value ).toBe( "*test*" );
			} );

			it( "Tests fluent must().term() direct placement", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder.must().term( "status", "published" );

				var query = searchBuilder.getQuery();
				expect( query ).toBeStruct().toHaveKey( "bool" );
				expect( query.bool ).toHaveKey( "must" );
				expect( query.bool.must ).toBeArray().toHaveLength( 1 );
				expect( query.bool.must[ 1 ] ).toHaveKey( "term" );
				expect( query.bool.must[ 1 ].term ).toHaveKey( "status" );
				expect( query.bool.must[ 1 ].term.status ).toBe( "published" );
			} );

			it( "Tests fluent should().terms() with array values", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder.should().terms( "status", [ "active", "published" ] );

				var query = searchBuilder.getQuery();
				expect( query ).toBeStruct().toHaveKey( "bool" );
				expect( query.bool ).toHaveKey( "should" );
				expect( query.bool.should ).toBeArray().toHaveLength( 1 );
				expect( query.bool.should[ 1 ] ).toHaveKey( "terms" );
				expect( query.bool.should[ 1 ].terms ).toHaveKey( "status" );
				expect( query.bool.should[ 1 ].terms.status ).toBeArray();
				expect( arrayLen( query.bool.should[ 1 ].terms.status ) ).toBe( 2 );
			} );

			it( "Tests fluent mustNot().exists() placement", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder.mustNot().exists( "deletedAt" );

				var query = searchBuilder.getQuery();
				expect( query ).toBeStruct().toHaveKey( "bool" );
				expect( query.bool ).toHaveKey( "must_not" );
				expect( query.bool.must_not ).toBeArray().toHaveLength( 1 );
				expect( query.bool.must_not[ 1 ] ).toHaveKey( "exists" );
				expect( query.bool.must_not[ 1 ].exists ).toHaveKey( "field" );
				expect( query.bool.must_not[ 1 ].exists.field ).toBe( "deletedAt" );
			} );

			it( "Tests fluent filter().range() placement", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder.filter().range( "price", gte = 10, lte = 100 );

				var query = searchBuilder.getQuery();
				expect( query ).toBeStruct().toHaveKey( "bool" );
				expect( query.bool ).toHaveKey( "filter" );
				expect( query.bool.filter ).toHaveKey( "range" );
				expect( query.bool.filter.range ).toHaveKey( "price" );
				expect( query.bool.filter.range.price ).toHaveKey( "gte" );
				expect( query.bool.filter.range.price ).toHaveKey( "lte" );
				expect( query.bool.filter.range.price.gte ).toBe( 10 );
				expect( query.bool.filter.range.price.lte ).toBe( 100 );
			} );

			it( "Tests chaining multiple fluent operations", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder
					.must().term( "status", "active" )
					.should().match( "title", "test" )
					.filter().range( "price", gte = 0 );

				var query = searchBuilder.getQuery();
				
				// Verify must clause
				expect( query ).toBeStruct().toHaveKey( "bool" );
				expect( query.bool ).toHaveKey( "must" );
				expect( query.bool.must ).toBeArray().toHaveLength( 1 );
				expect( query.bool.must[ 1 ] ).toHaveKey( "term" );
				
				// Verify should clause
				expect( query.bool ).toHaveKey( "should" );
				expect( query.bool.should ).toBeArray().toHaveLength( 1 );
				expect( query.bool.should[ 1 ] ).toHaveKey( "match" );
				
				// Verify filter clause
				expect( query.bool ).toHaveKey( "filter" );
				expect( query.bool.filter ).toHaveKey( "range" );
			} );

			it( "Tests fluent API preserves existing SearchBuilder functionality", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				// Mix old and new API
				searchBuilder.mustMatch( "title", "elasticsearch" );
				searchBuilder.must().term( "status", "active" );

				var query = searchBuilder.getQuery();
				expect( query ).toBeStruct().toHaveKey( "bool" );
				expect( query.bool ).toHaveKey( "must" );
				expect( query.bool.must ).toBeArray().toHaveLength( 2 );
				
				// First should be from mustMatch
				expect( query.bool.must[ 1 ] ).toHaveKey( "match" );
				expect( query.bool.must[ 1 ].match ).toHaveKey( "title" );
				
				// Second should be from fluent API
				expect( query.bool.must[ 2 ] ).toHaveKey( "term" );
				expect( query.bool.must[ 2 ].term ).toHaveKey( "status" );
			} );

			it( "Tests term query with boost parameter", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder.must().term( "status", "active", 2.0 );

				var query = searchBuilder.getQuery();
				expect( query.bool.must[ 1 ].term.status ).toBeStruct();
				expect( query.bool.must[ 1 ].term.status ).toHaveKey( "value" );
				expect( query.bool.must[ 1 ].term.status ).toHaveKey( "boost" );
				expect( query.bool.must[ 1 ].term.status.value ).toBe( "active" );
				expect( query.bool.must[ 1 ].term.status.boost ).toBe( 2.0 );
			} );

			it( "Tests match query with boost parameter", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );

				searchBuilder.should().match( "title", "elasticsearch", 1.5 );

				var query = searchBuilder.getQuery();
				expect( query.bool.should[ 1 ].match.title ).toBeStruct();
				expect( query.bool.should[ 1 ].match.title ).toHaveKey( "query" );
				expect( query.bool.should[ 1 ].match.title ).toHaveKey( "boost" );
				expect( query.bool.should[ 1 ].match.title.query ).toBe( "elasticsearch" );
				expect( query.bool.should[ 1 ].match.title.boost ).toBe( 1.5 );
			} );

			it( "Tests that fluent methods can be executed and return valid results", function(){
				var searchBuilder = variables.searchBuilder.new( variables.testIndexName, "testdocs" );
				
				searchBuilder.must().term( "status", "nonexistent" );
				
				var result = searchBuilder.execute();
				expect( result ).toBeInstanceOf( "cbElasticsearch.models.SearchResult" );
			} );

		} );
	}

}