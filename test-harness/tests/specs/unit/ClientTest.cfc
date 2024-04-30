component extends="HyperClientTest" {

	function beforeAll(){
		super.beforeAll();

		variables.model = getWirebox().getInstance( "HyperClient@cbelasticsearch" );

		super.beforeAll();
	}

	function run(){
		// all of our native client methods are interface and pass through to the native client. Those tests after the core tests are completed
		super.run();
	}

}
