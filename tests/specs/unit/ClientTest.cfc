component extends="coldbox.system.testing.BaseTestCase"{
	
	function beforeAll(){
		this.loadColdbox=true;

		setup();
		
		//variables.model = getWirebox().getInstance( "Client@cbElasticSearch" );
	}

	function afterAll(){
		
	}

	describe( "Performs cbElasticsearch SearchBuilder tests", function(){

		it( "Tests the ability of the client to connect using the Jest Native Client (default)", function(){
			
		});

	});

}