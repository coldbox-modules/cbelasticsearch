component extends="HyperClientTest" {

	function beforeAll(){
		super.beforeAll();

		variables.model = getWirebox().getInstance( "Client@cbelasticsearch" );

		super.beforeAll();
	}

	function run(){
		describe( "Ensures the mapping for the client is present", function(){
			it( "Checks the instance", function(){
				expect( variables.model ).toBeInstanceOf( "cbelasticsearch.models.io.HyperClient" );
			});
		} );
	}

}
