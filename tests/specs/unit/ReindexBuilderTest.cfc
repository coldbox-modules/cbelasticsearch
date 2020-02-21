component extends="coldbox.system.testing.BaseTestCase"{

    this.loadColdbox = true;

	function beforeAll() {
		if ( !structKeyExists( variables, "model" ) ) {
			setup();
			variables.model = getWirebox().getInstance( "JestClient@cbElasticsearch" );
		}

		variables.testIndexNameOne = lcase( "ElasticsearchClientTestsOne" );
		variables.testIndexNameTwo = lcase( "ElasticsearchClientTestsTwo" );

		variables.model.deleteIndex( variables.testIndexNameOne );
		variables.model.deleteIndex( variables.testIndexNameTwo );
	}

	function afterAll() {
		variables.model.deleteIndex( variables.testIndexNameOne );
		variables.model.deleteIndex( variables.testIndexNameTwo );

		super.afterAll();
	}

    function run() {
        describe( "reindex", function() {
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
                    .toBe( variables.model.count( searchOne ), "All the documents from the first index should exist in the second index" );
            } );

            it( "can pass structs for the source and destination", function() {
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
        } );
    }
}
