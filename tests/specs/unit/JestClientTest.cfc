component extends="coldbox.system.testing.BaseTestCase"{
	
	function beforeAll(){
		this.loadColdbox=true;

		setup();

		variables.model = getWirebox().getInstance( "JestClient@cbElasticsearch" );
		variables.testIndexName = "JestClientTests-" & createUUID();

	}

	function afterAll(){
		
	}

	function run(){
		describe( "Performs cbElasticsearch SearchBuilder tests", function(){

			it( "Tests the instantiation of the JEST client", function(){

				expect( getMetadata( variables.model.getHTTPClient() ).name ).toBe( "io.searchbox.client.http.JestHttpClient" );

			});

			it( "Tests the ability to create an index", function(){

				

			});

			it( "Tests the ability to delete an index", function(){

			});

			it( "Tests the ability to delete an index", function(){

			});

			it( "Tests the ability to process a search on an index", function(){



				var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new( index=variables.testIndexName );

				searchBuilder.match( "foo", "bar" );
				
				var searchResult = variables.model.executeSearch( searchBuilder );

				expect( searchResult ).toBeStruct();
				expect( searchResult ).toHaveKey( "_shards" );
				expect( searchResult ).toHaveKey( "took" );
				expect( searchResult ).toHaveKey( "timed_out" );
				expect( searchresult.timed_out ).toBeFalse();
				expect( searchResult ).toHaveKey( "hits" );
				expect( searchResult.hits ).toBeStruct();
				expect( searchResult.hits ).toHaveKey( "hits" );
				expect( searchResult.hits.hits ).toBeArray();

			});

		});	
	}

}