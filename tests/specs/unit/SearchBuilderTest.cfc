component extends="coldbox.system.testing.BaseTestCase"{
	
	function beforeAll(){
		this.loadColdbox=true;

		setup();
		
		variables.model = getWirebox().getInstance( "SearchBuilder@cbElasticSearch" );
	}

	function afterAll(){
		
	}

	describe( "Performs cbElasticsearch SearchBuilder tests", function(){

		it( "Tests new() with no arguments", function(){
			expect( variables.model.new() ).toBeInstanceOf( "SearchBuilder" );
		});

		it( "Tests new() with only index and type arguments", function(){

		});

		it( "Tests new() with a properties struct", function(){

		});

		it( "Tests the match() method", function(){

		});

		it( "Tests the aggregation() method", function(){

		});

		it( "Tests the sort() method by providing an array", function(){

		});

		it( "Tests the sort() method by providing a simple SQL-type string", function(){

		});

		it( "Tests the sort() method by providing a single field", function(){

		});

		it( "Tests the sort() method by providing a struct", function(){

		});

		it( "Tests the default sort() method case of throwing an error", function(){

		});

	});

}