component extends="JestClientTest"{
	
	function beforeAll(){
		this.loadColdbox=true;

		setup();

		variables.model = getWirebox().getInstance( "Client@cbElasticsearch" );
		variables.testIndexName = lcase( "ElasticsearchClientTests" );

		variables.model.deleteIndex( variables.testIndexName );

	}

	function run(){
		//all of our native client methods are interface and pass through to the native client. Run those tests first
		super.run();

		describe( "It performs specific Client Tests", function(){

			it( "Tests the ability to delete a type", function(){

				//insert some documents to delete
				var documents = [];

				for( var i=1; i <= 13; i++ ){
					arrayAppend( 
						documents, getInstance( "Document@cbElasticsearch" ).new(  
							variables.testIndexName,
							"testdocs",
							{
								"_id": createUUID(),
								"title": "Test Document Number #i#",
								"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
							}
						)
						
					);
				}

				var savedDocs = variables.model.saveAll( documents );
				
				//sleep for 1.5 seconds to ensure full persistence
				sleep( 1500 );

				var deleted = variables.model.deleteType( variables.testIndexName, "testdocs" );

				expect( deleted ).toBeTrue();

			});

		});
	}

}