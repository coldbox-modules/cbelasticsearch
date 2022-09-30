component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

		super.beforeAll();

		variables.model = getWirebox().getInstance( "SearchResult@cbElasticSearch" );
	}

	function afterAll(){
		super.afterAll();
	}

	function run(){
		describe( "Performs cbElasticsearch SearchResult tests", function(){
			it( "Tests instantiation", function(){
			} );
		} );
	}

}
