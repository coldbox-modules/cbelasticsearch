component extends="coldbox.system.testing.BaseTestCase"{

    this.loadColdbox = true;

	function beforeAll() {
		if ( !structKeyExists( variables, "model" ) ) {
			setup();
			variables.model = getWirebox().getInstance( "JestClient@cbElasticsearch" );
		}

		variables.testIndexName = lcase( "ElasticsearchClientTests" );
		variables.model.deleteIndex( variables.testIndexName );
	}

	function afterAll() {
		variables.model.deleteIndex( variables.testIndexName );
		super.afterAll();
	}

	function run(){

		describe( "Performs cbElasticsearch JestClient tests", function(){

			afterEach( function(){
				// we give ourselves a few seconds before each next test for updates to persist
				sleep( 500 );
			});

			// This test is no longer applicable on ES v7.x
			xit( "Tests the ability to delete a type", function(){

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

			it( "Tests the ability to create an index", function(){

				var builderProperties = {
											"mappings":{
												"testdocs":{
													"_all"       : { "enabled"	: false },
													"properties" : {
														"title"      : {
															"type" : "text",
															"fields": {
																"kw":{
																	"type":"keyword"
																}
															}
														},
														"createdTime": {
															"type"  : "date",
															"format": "date_time_no_millis"
														}
													}
												}
											}
										};

				var indexBuilder = getWirebox()
									.getInstance( "IndexBuilder@cbElasticsearch" )
												.new(
														name=variables.testIndexName,
														properties=builderProperties
													);
				expect( indexBuilder ).toBeComponent();
				expect( indexBuilder.getMappings() ).toBeStruct();
				expect( indexBuilder.getMappings() ).toHaveKey( "testdocs" );
				expect( indexBuilder.getMappings().testdocs ).toHaveKey( "_all" );
				var indexResult = variables.model.applyIndex( indexBuilder );

				expect( indexResult ).toBeTrue();

			});

			it( "Tests the ability to verify that an index exists", function(){
				expect( variables.model.indexExists( variables.testIndexName ) ).toBeTrue();
			});

			it( "tests the getIndices method", function(){

				// test default ( verbose = false )
				var allIndices = variables.model.getIndices();

				expect( allIndices ).toBeStruct();

				allIndices.keyArray().each( function( key ){
					expect( allIndices[ key ] )
							.toBeStruct()
							.toHaveKey( "uuid" )
							.toHaveKey( "docs" )
							.toHaveKey( "size_in_bytes" );

				} );

				// test verbose
				var allIndices = variables.model.getIndices( verbose =true );


				expect( allIndices ).toBeStruct();

				allIndices.keyArray().each( function( key ){
					expect( allIndices[ key ] )
							.toBeStruct()
							.toHaveKey( "uuid" )
							.toHaveKey( "primaries" )
							.toHaveKey( "total" );

				} );

			});

			it( "can retreive a map of all aliases", function(){
				// create an alias so we can test
                var aliasName = lcase( "GetAliasesTestAlias" );

                var addAliasAction = getWireBox().getInstance( "AliasBuilder@cbElasticSearch" )
                    .add( indexName = variables.testIndexName, aliasName = aliasName );

                variables.model.applyAliases( aliases = addAliasAction );

				var allAliases = variables.model.getAliases();

				expect( allAliases ).toHaveKey( "aliases")
									.toHaveKey( "unassigned" );

				expect( allAliases.unassigned ).toBeArray();

				expect( allAliases.aliases )
									.toBeStruct()
									.toHaveKey( aliasName );

			});

			it( "Tests the ability to verify that a mapping exists", function(){
				expect( variables.model.indexMappingExists( variables.testIndexName, "testdocs" ) ).toBeTrue();
			});

			// this test is no longer applicable on ES v7.x
			xit( "Tests the ability to verify that a mapping does not exist", function(){
				expect( variables.model.indexMappingExists( variables.testIndexName, "idonotexist" ) ).toBeFalse();
			});

			it( "Tests the ability to insert a document in to an index", function(){

				expect( variables ).toHaveKey( "testIndexName" );

				var testDocument = {
					"_id"        : createUUID(),
					"title"      : "My Test Document",
					"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox().getInstance( "Document@cbElasticsearch" ).new( variables.testIndexName, "testdocs", testDocument );

				var saveResult = variables.model.save( document );

				expect( saveResult ).toBeComponent();
				expect( saveResult.getId() ).toBe( testDocument[ "_id" ] );

				variables.testDocumentId = saveResult.getId();

			});

			describe( "parseParams method tests", function(){
				it( "can accept an query string", function(){
					var parsed = variables.model.parseParams( "wait_for_completion=true&scroll_size=10" );
					expect( parsed ).toBeArray();
					expect( parsed.len() ).toBe( 2 );
					expect( parsed[ 1 ] ).toBeStruct().toHaveKey( "name" ).toHaveKey( "value" );
				} );
				it( "can accept a struct", function(){
					var parsed = variables.model.parseParams( { "wait_for_completion" : false, "scroll_size" : 10 } );
					expect( parsed ).toBeArray();
					expect( parsed.len() ).toBe( 2 );
					expect( parsed[ 1 ] ).toBeStruct().toHaveKey( "name" ).toHaveKey( "value" );
				} );
				it( "can accept a preformatted array", function(){
					var parsed = variables.model.parseParams( [{ "name" : "wait_for_completion", "value" : false }, { "name" : "scroll_size", "value" : 10 } ] );
					expect( parsed ).toBeArray();
					expect( parsed.len() ).toBe( 2 );
					expect( parsed[ 1 ] ).toBeStruct().toHaveKey( "name" ).toHaveKey( "value" );
				} );
            });

            describe( "reindex", function() {
                beforeEach( function() {
                    variables.testIndexNameOne = lcase( "ElasticsearchClientTestsOne" );
                    variables.testIndexNameTwo = lcase( "ElasticsearchClientTestsTwo" );

                    variables.model.deleteIndex( variables.testIndexNameOne );
                    variables.model.deleteIndex( variables.testIndexNameTwo );
                } );

                it( "can reindex from one index to another", function() {
                    getWireBox().getInstance( "IndexBuilder@cbElasticSearch" )
                        .new( variables.testIndexNameOne )
                        .save();

                    getWireBox().getInstance( "IndexBuilder@cbElasticSearch" )
                        .new( variables.testIndexNameTwo )
                        .save();

                    // insert some documents to reindex
                    var documents = [];
                    for ( var i = 1; i <= 13; i++ ) {
                        arrayAppend(
                            documents,
                            getInstance( "Document@cbElasticsearch" ).new(
                                variables.testIndexNameOne,
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

                    var searchOne = getWireBox().getInstance( "SearchBuilder@cbElasticSearch" )
                        .new( variables.testIndexNameOne, "testdocs", {
                            "query": {
                                "match_all": {}
                            }
                        } );

                    var searchTwo = getWireBox().getInstance( "SearchBuilder@cbElasticSearch" )
                        .new( variables.testIndexNameTwo, "testdocs", {
                            "query": {
                                "match_all": {}
                            }
                        } );

                    expect( variables.model.count( searchOne ) ).toBe( 13 );
                    expect( variables.model.count( searchTwo ) )
                        .toBe( 0, "No documents should exists in the second index" );

                    variables.model.reindex(
                        source = variables.testIndexNameOne,
                        destination = variables.testIndexNameTwo
                    );

                    sleep( 1500 );

                    expect( variables.model.count( searchTwo ) )
                        .toBe(
                            variables.model.count( searchOne ),
                            "All the documents from the first index should exist in the second index"
                        );
                } );

                it( "can pass structs for the source and destination when reindexing", function() {
                    variables.model.deleteIndex( variables.testIndexNameOne );
                    variables.model.deleteIndex( variables.testIndexNameTwo );

                    getWireBox().getInstance( "IndexBuilder@cbElasticSearch" )
                        .new( variables.testIndexNameOne )
                        .save();

                    getWireBox().getInstance( "IndexBuilder@cbElasticSearch" )
                        .new( variables.testIndexNameTwo )
                        .save();

                    // //insert some documents to reindex
                    var documents = [];
                    for ( var i = 1; i <= 10; i++ ) {
                        arrayAppend(
                            documents,
                            getInstance( "Document@cbElasticsearch" ).new(
                                variables.testIndexNameOne,
                                "testdocs",
                                {
                                    "_id": createUUID(),
                                    "title": "Test Document Number #i#",
                                    "flag": i % 2 == 0 ? "flag" : "noflag",
                                    "createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
                                }
                            )
                        );
                    }

                    var savedDocs = variables.model.saveAll( documents );

                    //sleep for 1.5 seconds to ensure full persistence
                    sleep( 1500 );

                    var searchOne = getWireBox().getInstance( "SearchBuilder@cbElasticSearch" )
                        .new( variables.testIndexNameOne, "testdocs", {
                            "query": {
                                "match_all": {}
                            }
                        } );

                    var searchTwo = getWireBox().getInstance( "SearchBuilder@cbElasticSearch" )
                        .new( variables.testIndexNameTwo, "testdocs", {
                            "query": {
                                "match_all": {}
                            }
                        } );

                    expect( variables.model.count( searchOne ) ).toBe( 10 );
                    expect( variables.model.count( searchTwo ) ).toBe( 0 );

                    variables.model.reindex(
                        source = {
                            "index": variables.testIndexNameOne,
                            "type": "testdocs",
                            "query": {
                                "term": {
                                    "flag.keyword": "flag"
                                }
                            }
                        },
                        destination = variables.testIndexNameTwo,
                        waitForCompletion = true
                    );

                    // We still have to wait for background indexing to update
                    sleep( 1500 );

                    expect( variables.model.count( searchTwo ) ).toBe( 5 );
                } );

                it( "throws an exception when a reindex error occurs by default", function() {
                    expect( function() {
                        variables.model.reindex(
                            source = {
                                "index": "no_such_index",
                                "type": "testdocs"
                            },
                            destination = "another_nonexistent_index",
                            waitForCompletion = true
                        );
                    } ).toThrow( type = "cbElasticsearch.JestClient.ReindexFailedException" );
                } );
            } );

			describe( "tasks", function(){
				it( "can retreive all tasks on the cluster", function(){
					var activeTasks = variables.model.getTasks();
					expect( activeTasks ).toBeArray();
					activeTasks.each( function( task ){
						expect( task ).toBeInstanceOf( "cbelasticsearch.models.Task" );
					} );
				} );

				it( "can retreive the status of a single task", function(){
					// create some documents so we can fire an upate by query
					var documents = [];
					for( var i = 1; i <= 10000; i++ ){
						var bulkDoc  = {
							"_id": createUUID(),
							"title": "Test Document Number #i#",
							"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" ),
							"description" : "Document Number #i# of 10,000"
						};

						arrayAppend(
							documents,
							getInstance( "Document@cbElasticsearch" ).new(
								variables.testIndexName,
								"testdocs",
								bulkDoc
							)
						);
					}

					variables.model.saveAll( documents );

					var searchBuilder = getInstance( "SearchBuilder@cbelasticsearch" ).new( variables.testIndexName, "testdocs" );
					searchBuilder.match( "title", "Test" );

					searchBuilder.param( "wait_for_completion", false );

					var taskId = variables.model.updateByQuery(
						searchBuilder,
						{
							"source" : "ctx._source.longDescription = ctx._source.description;",
							"lang" : "painless"
						}
					).task;

					var taskObj = variables.model.getTask( taskId );
					expect( taskObj ).toBeInstanceOf( "cbelasticsearch.models.Task" );
					expect( taskObj.getCompleted() ).toBeBoolean();
					expect( taskObj.getIdentifier() ).toBe( taskId );
					expect( taskObj.isComplete() ).toBeBoolean();

					// expect a while loop to complete
					while( !taskObj.isComplete() ){
						expect( taskObj.getCompleted() ).toBeFalse();
					}

				} );
			} );

			it( "Tests the ability to perform bulk document updates/additions", function(){

				var documents = [];

				for( var i=1; i <= 13; i++ ){

					var bulkDoc  = {
						"_id": createUUID(),
						"title": "Test Document Number #i#",
						"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
					};

					arrayAppend(
						documents,
						getInstance( "Document@cbElasticsearch" ).new(
							variables.testIndexName,
							"testdocs",
							bulkDoc
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

				variables.bulkInserts = documents;

			} );

			it( "Tests error handling of updates/additions when one of the documents to be updated contains an invalid value", function(){

				var documents = [];

				for( var i=1; i <= 13; i++ ){

					var bulkDoc  = {
						"_id": createUUID(),
						"title": "Test Document Number #i#",
						"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
					};

					arrayAppend(
						documents,
						getInstance( "Document@cbElasticsearch" ).new(
							variables.testIndexName,
							"testdocs",
							bulkDoc
						)

					);
				}

				documents[ documents.len() ].getMemento()[ "createdTime" ] = "not a date";

				var savedDocs = variables.model.saveAll( documents );

				expect( savedDocs ).toBeArray();

				for( var i = 1; i  < savedDocs.len(); i++ ){
					expect( savedDocs[ i ] ).toHaveKey( "result" );
					expect( savedDocs[ i ].result ).toBe( "created" );
				}


				expect( savedDocs[ savedDocs.len() ] ).toHaveKey( "error" );
				expect( savedDocs[ savedDocs.len() ].error ).toHaveKey( "reason" );

				// test the ability throw an error when the flag is up
				expect( function(){
					variables.model.saveAll( documents, true );
				}).toThrow( "cbElasticsearch.JestClient.PersistenceException" );

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

			it( "Tests the ability to retreive multiple documents with an array of identifiers", function(){
				expect( variables ).toHaveKey( "bulkInserts" );
				expect( variables ).toHaveKey( "testIndexName" );
				var identifiers = variables.bulkInserts.map( function( doc ){ return doc.getId(); } );
				var returned = variables.model.getMultiple( identifiers, variables.testIndexName );
				expect( returned ).toBeArray();
				expect( arrayLen( returned ) ).toBe( arrayLen( identifiers ) );
			});

			it( "Tests the ability to update a document in an index", function(){

				expect( variables ).toHaveKey( "testDocumentId" );

				expect( variables ).toHaveKey( "testIndexName" );

				var existing = variables.model.get( variables.testDocumentId, variables.testIndexName, "testdocs" );

				expect( existing ).toBeComponent();
				expect( existing.getMemento( true ) ).toBeStruct();

				existing.setValue( 'title', "My Updated Test Document" );

				var saveResult = variables.model.save( existing );

				expect( saveResult ).toBeComponent();

				expect( saveResult.getId() ).toBe( variables.testDocumentId );

				var updated = variables.model.get( variables.testDocumentId, variables.testIndexName, "testdocs" );

				expect( updated.getId() ).toBe( variables.testDocumentId );

				expect( updated.getMemento( true )[ "title" ] ).toBe( existing.getValue( 'title' ) );

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

			it( "Tests the ability to count documents in an index", function(){

				expect( variables ).toHaveKey( "testDocumentId" );

				var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new( index=variables.testIndexName, type="testdocs" );

				searchBuilder.match( "title", "Test" );

				var searchResult = variables.model.count( searchBuilder );

				expect( searchResult ).toBeNumeric();

				expect( searchResult ).toBeGT( 0 );

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

			it( "Tests the ability to delete a document by id", function(){
				expect( variables ).toHaveKey( "testDocumentId" );
				expect( variables ).toHaveKey( "testIndexName" );

				var document = variables.model.get( variables.testDocumentId, variables.testIndexName, "testdocs" );

				expect( isNull( document ) ).toBeFalse();

				variables.model.delete( document );

				expect( variables.model.get( variables.testDocumentId ) ).toBeNull();

			});


			it( "Tests the ability to delete documents by query synchronously", function(){

				expect( variables ).toHaveKey( "testIndexName" );

				var testDocument = {
					"_id"        : createUUID(),
					"title"      : "My Test Document",
					"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox().getInstance( "Document@cbElasticsearch" ).new( variables.testIndexName, "testdocs", testDocument );

				var saveResult = variables.model.save( document );

				expect( variables.model.get( testDocument[ "_id"], variables.testIndexName ) ).notToBeNull();

				var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new(
					variables.testIndexName,
					"testdocs",
					{
						"match_all":{}
					}
				);

				var deleteResult = variables.model.deleteByQuery( searchBuilder );

				expect( deleteResult ).toBeStruct();
				expect( deleteResult ).toHaveKey( "deleted" );
				expect( deleteResult.deleted ).toBeGT( 0 );

			});

			it( "Tests the ability to delete documents by query asynchronously", function(){

				expect( variables ).toHaveKey( "testIndexName" );

				var testDocument = {
					"_id"        : createUUID(),
					"title"      : "My Async Test Document",
					"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox().getInstance( "Document@cbElasticsearch" ).new( variables.testIndexName, "testdocs", testDocument );

				var saveResult = variables.model.save( document );

				expect( variables.model.get( testDocument[ "_id"], variables.testIndexName ) ).notToBeNull();

				var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new(
					variables.testIndexName,
					"testdocs",
					{
						"match_all":{}
					}
				);

				var deleteResult = variables.model.deleteByQuery( searchBuilder, false );

				expect( deleteResult ).toBeInstanceOf( "cbElasticsearch.models.Task" );

			});

			it( "Tests the ability to update documents by query synchronously", function(){

				expect( variables ).toHaveKey( "testIndexName" );

				//create document and save
				var testDocument = {
					"_id"        : createUUID(),
					"title"      : "My Test Document",
					"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox().getInstance( "Document@cbElasticsearch" ).new( variables.testIndexName, "testdocs", testDocument );

				var saveResult = variables.model.save( document );

				sleep(2000);

				var searchBuilder = getWireBox().getInstance( "SearchBuilder@cbElasticSearch" ).new( variables.testIndexName, "testdocs" );

				searchBuilder.match( "title", "My Test Document" );

				var updateResult = variables.model.updateByQuery( searchBuilder, {
					"source": "ctx._source['title'] = params.newInstanceValue",
					"lang": "painless",
					"params": {
						"newInstanceValue": "My Updated Test Document"
						}
				} );

				expect( updateResult ).toBeStruct();
				expect( updateResult ).toHaveKey( "updated" );
				expect( updateResult.updated ).toBeGT( 0 );

				var updatedDocument = getWirebox().getInstance( "Document@cbElasticsearch" ).get( testDocument._id, variables.testIndexName, "testdocs" );

				expect( updatedDocument.getMemento().title ).toBe( "My Updated Test Document" );


			});

			it( "Tests the ability to update documents by query asynchronously", function(){

				expect( variables ).toHaveKey( "testIndexName" );

				//create document and save
				var testDocument = {
					"_id"        : createUUID(),
					"title"      : "My Test Document",
					"createdTime": dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox().getInstance( "Document@cbElasticsearch" ).new( variables.testIndexName, "testdocs", testDocument );

				var saveResult = variables.model.save( document );

				sleep(2000);

				var searchBuilder = getWireBox().getInstance( "SearchBuilder@cbElasticSearch" ).new( variables.testIndexName, "testdocs" );

				searchBuilder.match( "title", "My Test Document" );

				var updateResult = variables.model.updateByQuery(
					searchBuilder,
					{
						"source": "ctx._source['title'] = params.newInstanceValue",
						"lang": "painless",
						"params": {
							"newInstanceValue": "My Updated Test Document"
							}
					},
					false
				);

				expect( updateResult ).toBeInstanceOf( "cbElasticsearch.models.Task" );


			});


			it( "Tests the ability to delete an index", function(){

				expect( variables ).toHaveKey( "testIndexName" );
				var deletion = variables.model.deleteIndex( variables.testIndexName );

				expect( deletion ).toBeStruct();
				expect( deletion ).toHaveKey( "acknowledged" );
				expect( deletion[ "acknowledged" ] ).toBeTrue();

			});

		});
	}

}
