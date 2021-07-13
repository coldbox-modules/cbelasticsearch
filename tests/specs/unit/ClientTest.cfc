component extends="HyperClientTest" {

	function beforeAll(){
		setup();

		variables.model = getWirebox().getInstance( "Client@cbElasticsearch" );

		super.beforeAll();
	}

	function run(){
		// all of our native client methods are interface and pass through to the native client. Those tests after the core tests are completed
		super.run();
	}

}
