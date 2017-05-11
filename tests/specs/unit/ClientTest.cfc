component extends="coldbox.system.testing.BaseTestCase"{
	
	function beforeAll(){
		this.loadColdbox=true;

		setup();

		variables.model = getWirebox().getInstance( "Client@cbElasticsearch" );
		variables.testIndexName = lcase( "ElasticsearchClientTests" );

		variables.model.deleteIndex( variables.testIndexName );

	}

	function afterAll(){		
		variables.model.deleteIndex( variables.testIndexName );
	}

	function run(){
		describe( "Performs cbElasticsearch Client tests", function(){

			it( "Tests the instantiation of the Elasticsearch Client", function(){

				expect( variables.model.getNativeClient() ).toBeComponent();

			});

			it( "Tests the ability to create an index", function(){

				var indexBuilder = getWirebox().getInstance( "IndexBuilder@cbElasticsearch" )
													.new( 
														name=variables.testIndexName,
														properties={
															"mappings":{
																"testdocs":{
																	"_all"       : { "enabled": false },
																	"properties" : {
																		"title"      : {"type" : "string"},
																		"createdTime": {
																			"type"  : "date",
																			"format": "date_time_no_millis"
																		},
																	}
																}
															}
														} 
													);
				expect( indexBuilder ).toBeComponent();
				expect( indexBuilder.getMappings() ).toBeStruct();
				expect( indexBuilder.getMappings() ).toHaveKey( "testdocs" );
				expect( indexBuilder.getMappings().testdocs ).toHaveKey( "_all" );

				var indexResult = variables.model.applyIndex( indexBuilder );

				expect( indexResult ).toBeTrue();

			});

			it( "Tests the ability to insert a document in to an index", function(){

				expect( variables ).toHaveKey( "testIndexName" );

				var testDocument = {
					"_id"        : createUUID(),
					"title"      : "My Test Document",
					"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox().getInstance( "Document@cbElasticsearch" ).new( variables.testIndexName, "testdocs", testDocument )

				var saveResult = variables.model.save( document );

				expect( saveResult ).toBeComponent();
				expect( saveResult.getId() ).toBe( testDocument[ "_id" ] );

				variables.testDocumentId = saveResult.getId();

			});

			it( "Tests the ability to perform bulk document updates/additions", function(){
				
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

				expect( savedDocs ).toBeArray();
				expect( arrayLen( savedDocs ) ).toBe( 13 );

				for( var result in savedDocs ){
					expect( result ).toHaveKey( "result" );
					expect( result.result ).toBe( "created" );
					break;
				}

				//sleep for 1 second to ensure bulk insertions are persisted indexed
				sleep( 1000 );

				variables.bulkInserts = documents;

			} );

			it( "Tests the ability to retrieve a document by an _id value", function(){

				expect( variables ).toHaveKey( "testDocumentId" );
				expect( variables ).toHaveKey( "testIndexName" );

				var document = variables.model.get( variables.testDocumentId, variables.testIndexName, "testdocs" );

				expect( isNull( document ) ).toBeFalse();
				expect( document ).toBeComponent();
				expect( document.getMemento( true ) ).toBeStruct();
				expect( document.getId() ).toBe( variables.testDocumentId );

			});

			it( "Tests the ability to update a document in an index", function(){
				
				expect( variables ).toHaveKey( "testDocumentId" );
				expect( variables ).toHaveKey( "testIndexName" );

				var existing = variables.model.get( variables.testDocumentId, variables.testIndexName, "testdocs" );

				expect( existing ).toBeComponent();
				expect( existing.getMemento( true ) ).toBeStruct();

				existing.set( 'title', "My Updated Test Document" );

				var saveResult = variables.model.save( existing );

				expect( saveResult ).toBeComponent();

				expect( saveResult.getId() ).toBe( variables.testDocumentId );

				var updated = variables.model.get( variables.testDocumentId, variables.testIndexName, "testdocs" );

				expect( updated.getId() ).toBe( variables.testDocumentId );

				expect( updated.getMemento( true )[ "title" ] ).toBe( existing.getValue('title') );

			});

			it( "Tests the ability to process a search on an index", function(){

				expect( variables ).toHaveKey( "testDocumentId" );

				var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new( index=variables.testIndexName, type="testdocs" );

				searchBuilder.match( "title", "Test" );
				
				var searchResult = variables.model.executeSearch( searchBuilder );

				expect( searchResult ).toBeComponent();
				expect( searchResult.getHits() ).toBeArray();

				expect( arrayLen( searchResult.getHits() ) ).toBeGT( 0 );

			});

			it( "Tests the ability to boost a specific search match", function(){

				expect( variables ).toHaveKey( "bulkInserts" );

				//sleep for this test

				var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new();
				searchBuilder.setIndex( variables.testIndexName );
				searchBuilder.setType( "testdocs" );

				searchBuilder.match( name="title", value="Document Number 3", boost=.5 );

				var searchResults = variables.model.executeSearch( searchBuilder );

				expect( searchResults ).toBeComponent();
				expect( searchResults.getHits() ).toBeArray();

				expect( searchResults.getHitCount() ).toBeGT( 1 );

				var firstResult = searchResults.getHits()[ 1 ];
				var secondResult = searchResults.getHits()[ arrayLen( searchResults.getHits() ) ];

				expect( firstResult.getScore() ).toBeGT( secondResult.getScore() );

			});


			xit( "Tests the ability to delete an index", function(){
				
				expect( variables ).toHaveKey( "testIndexName" );
				var deletion = variables.model.deleteIndex( variables.testIndexName );	

				expect( deletion ).toBeStruct();
				expect( deletion ).toHaveKey( "acknowledged" );
				expect( deletion.acknowledged ).toBeTrue();

			});

		});	
	}

}