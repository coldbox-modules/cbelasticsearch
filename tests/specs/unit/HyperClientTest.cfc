component extends="coldbox.system.testing.BaseTestCase" {

	this.loadColdbox = true;

	function beforeAll(){
		super.beforeAll();
		if ( !structKeyExists( variables, "model" ) ) {
			variables.model = getWirebox().getInstance( "HyperClient@cbElasticsearch" );
		}

		variables.testIndexName = lCase( "ElasticsearchClientTests" );
		variables.model.deleteIndex( variables.testIndexName );
	}

	function afterAll(){
		variables.model.deleteIndex( variables.testIndexName );
		super.afterAll();
	}

	function run(){
		describe( "Performs cbElasticsearch HyperClient tests", function(){
			afterEach( function(){
				// we give ourselves a few seconds before each next test for updates to persist
				sleep( 500 );
			} );

			it( "Tests the ability to create an index", function(){
				var builderProperties = {
					"mappings" : {
						"testdocs" : {
							"_all"       : { "enabled" : false },
							"properties" : {
								"title" : {
									"type"   : "text",
									"fields" : { "kw" : { "type" : "keyword" } }
								},
								"createdTime" : { "type" : "date", "format" : "date_time_no_millis" }
							}
						}
					}
				};

				var indexBuilder = getWirebox()
					.getInstance( "IndexBuilder@cbElasticsearch" )
					.new( name = variables.testIndexName, properties = builderProperties );
				expect( indexBuilder ).toBeComponent();
				expect( indexBuilder.getMappings() ).toBeStruct();
				expect( indexBuilder.getMappings() ).toHaveKey( "testdocs" );
				expect( indexBuilder.getMappings().testdocs ).toHaveKey( "_all" );
				var indexResult = variables.model.applyIndex( indexBuilder );

				expect( indexResult ).toBeTrue();
			} );

			it( "Tests the ability to verify that an index exists", function(){
				expect( variables.model.indexExists( variables.testIndexName ) ).toBeTrue();
			} );

			it( "tests the getIndices method", function(){
				// test default ( verbose = false )
				var allIndices = variables.model.getIndices();

				expect( allIndices ).toBeStruct();

				allIndices
					.keyArray()
					.each( function( key ){
						expect( allIndices[ key ] )
							.toBeStruct()
							.toHaveKey( "uuid" )
							.toHaveKey( "docs" )
							.toHaveKey( "size_in_bytes" );
					} );

				// test verbose
				var allIndices = variables.model.getIndices( verbose = true );


				expect( allIndices ).toBeStruct();

				allIndices
					.keyArray()
					.each( function( key ){
						expect( allIndices[ key ] )
							.toBeStruct()
							.toHaveKey( "uuid" )
							.toHaveKey( "primaries" )
							.toHaveKey( "total" );
					} );
			} );

			it( "can retrieve a map of all aliases", function(){
				// create an alias so we can test
				var aliasName = lCase( "GetAliasesTestAlias" );

				var addAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.add( indexName = variables.testIndexName, aliasName = aliasName );

				variables.model.applyAliases( aliases = addAliasAction );

				var allAliases = variables.model.getAliases();

				expect( allAliases ).toHaveKey( "aliases" ).toHaveKey( "unassigned" );

				expect( allAliases.unassigned ).toBeArray();

				expect( allAliases.aliases ).toBeStruct().toHaveKey( aliasName );
			} );

			it( "Tests the ability to insert a document in to an index", function(){
				expect( variables ).toHaveKey( "testIndexName" );

				var testDocument = {
					"_id"         : createUUID(),
					"title"       : "My Test Document",
					"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox()
					.getInstance( "Document@cbElasticsearch" )
					.new(
						variables.testIndexName,
						"testdocs",
						testDocument
					);

				var saveResult = variables.model.save( document );

				expect( saveResult ).toBeComponent();
				expect( saveResult.getId() ).toBe( testDocument[ "_id" ] );

				variables.testDocumentId = saveResult.getId();
			} );

			describe( "parseParams method tests", function(){
				it( "can accept an query string", function(){
					var parsed = variables.model.parseParams( "wait_for_completion=true&scroll_size=10" );
					expect( parsed ).toBeArray();
					expect( parsed.len() ).toBe( 2 );
					expect( parsed[ 1 ] )
						.toBeStruct()
						.toHaveKey( "name" )
						.toHaveKey( "value" );
				} );
				it( "can accept a struct", function(){
					var parsed = variables.model.parseParams( { "wait_for_completion" : false, "scroll_size" : 10 } );
					expect( parsed ).toBeArray();
					expect( parsed.len() ).toBe( 2 );
					expect( parsed[ 1 ] )
						.toBeStruct()
						.toHaveKey( "name" )
						.toHaveKey( "value" );
				} );
				it( "can accept a preformatted array", function(){
					var parsed = variables.model.parseParams( [
						{ "name" : "wait_for_completion", "value" : false },
						{ "name" : "scroll_size", "value" : 10 }
					] );
					expect( parsed ).toBeArray();
					expect( parsed.len() ).toBe( 2 );
					expect( parsed[ 1 ] )
						.toBeStruct()
						.toHaveKey( "name" )
						.toHaveKey( "value" );
				} );
			} );

			it( "Tests the ability to perform bulk operations on multiple documents", function(){
				var operations = [];
				var docs       = [];

				for ( var i = 1; i <= 13; i++ ) {
					var bulkDoc = {
						"_id"         : createUUID(),
						"title"       : "Test Bulk Insert Document Number #i#",
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
					};

					docs.append( bulkDoc );

					operations.append( {
						"operation" : {
							"create" : {
								"_index" : variables.testIndexName,
								"_id"    : bulkDoc[ "_id" ]
							}
						},
						"source" : {
							"title"       : bulkDoc.title,
							"createdTime" : bulkDoc.createdTime
						}
					} );
				}

				var savedDocs = variables.model.processBulkOperation( operations, { "refresh" : true } );

				expect( savedDocs )
					.toBeStruct()
					.toHaveKey( "errors" )
					.toHaveKey( "items" );

				expect( savedDocs.items ).toBeArray();

				for ( var i = 1; i <= savedDocs.items.len(); i++ ) {
					expect( savedDocs.items[ i ] ).toHaveKey( "create" );
					expect( savedDocs.items[ i ].create ).toHaveKey( "result" );
					expect( savedDocs.items[ i ].create.result ).toBe( "created" );
				}

				// Update the first doc
				operations[ 1 ].operation[ "update" ] = structCopy( operations[ 1 ].operation.create );
				structDelete( operations[ 1 ].operation, "create" );
				var updateTitle = "My Updated bulk insert Document Title";
				operations[ 1 ].source = { "doc" : { "title" : updateTitle } };

				// delete the remainder
				for ( var i = 2; i <= operations.len(); i++ ) {
					operations[ i ].operation[ "delete" ] = structCopy( operations[ i ].operation.create );
					structDelete( operations[ i ].operation, "create" );
					structDelete( operations[ i ], "source" );
				}

				debug( operations );

				var bulkDocs = variables.model.processBulkOperation( operations, { "refresh" : true } );

				expect( bulkDocs )
					.toBeStruct()
					.toHaveKey( "errors" )
					.toHaveKey( "items" );

				expect( bulkDocs.items ).toBeArray();

				expect( bulkDocs.items[ 1 ] ).toHaveKey( "update" );
				expect( bulkDocs.items[ 1 ].update ).toHaveKey( "result" );
				expect( bulkDocs.items[ 1 ].update.result ).toBe( "updated" );

				for ( var i = 2; i <= bulkDocs.items.len(); i++ ) {
					expect( bulkDocs.items[ i ] ).toHaveKey( "delete" );
					expect( bulkDocs.items[ i ].delete ).toHaveKey( "result" );
					expect( bulkDocs.items[ i ].delete.result ).toBe( "deleted" );
				}
			} );


			it( "Tests the ability to perform bulk document saves with both updates and additions", function(){
				var documents = [];

				for ( var i = 1; i <= 13; i++ ) {
					var bulkDoc = {
						"_id"         : createUUID(),
						"title"       : "Test Document Number #i#",
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
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

				for ( var result in savedDocs ) {
					expect( result ).toHaveKey( "result" );
					expect( result.result ).toBe( "created" );
					break;
				}

				variables.bulkInserts = documents;
			} );

			it( "Tests error handling of updates/additions when one of the documents to be updated contains an invalid value", function(){
				var documents = [];

				for ( var i = 1; i <= 13; i++ ) {
					var bulkDoc = {
						"_id"         : createUUID(),
						"title"       : "Test Document Number #i#",
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
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

				for ( var i = 1; i < savedDocs.len(); i++ ) {
					expect( savedDocs[ i ] ).toHaveKey( "result" );
					expect( savedDocs[ i ].result ).toBe( "created" );
				}


				expect( savedDocs[ savedDocs.len() ] ).toHaveKey( "error" );
				expect( savedDocs[ savedDocs.len() ].error ).toHaveKey( "reason" );

				// test the ability throw an error when the flag is up
				expect( function(){
					variables.model.saveAll( documents, true );
				} ).toThrow( "cbElasticsearch.HyperClient.BulkSaveException" );
			} );

			it( "tests the ability to delete multiple documents", function(){
				var documents = [];

				for ( var i = 1; i <= 13; i++ ) {
					var bulkDoc = {
						"_id"         : createUUID(),
						"title"       : "Test Document Number #i#",
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
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

				for ( var result in savedDocs ) {
					expect( result ).toHaveKey( "result" );
					expect( result.result ).toBe( "created" );
					break;
				}

				var deletedDocs = variables.model.deleteAll( documents, true, { "refresh" : true } );

				expect( deletedDocs )
					.toBeStruct()
					.toHaveKey( "errors" )
					.toHaveKey( "items" );

				expect( deletedDocs.items ).toBeArray();

				for ( var i = 1; i <= deletedDocs.items.len(); i++ ) {
					expect( deletedDocs.items[ i ] ).toHaveKey( "delete" );
					expect( deletedDocs.items[ i ].delete ).toHaveKey( "result" );
					expect( deletedDocs.items[ i ].delete.result ).toBe( "deleted" );
				}
			} );

			it( "Tests the ability to retrieve a document by an _id value", function(){
				expect( variables ).toHaveKey( "testDocumentId" );
				expect( variables ).toHaveKey( "testIndexName" );

				var document = variables.model.get(
					variables.testDocumentId,
					variables.testIndexName,
					"testdocs"
				);

				expect( isNull( document ) ).toBeFalse();
				expect( document ).toBeComponent();
				expect( document.getMemento( true ) ).toBeStruct();
				expect( document.getId() ).toBe( variables.testDocumentId );
			} );

			it( "Tests the ability to retrieve a document with params", function(){
				expect( variables ).toHaveKey( "testDocumentId" );
				expect( variables ).toHaveKey( "testIndexName" );

				var document = variables.model.get(
					variables.testDocumentId,
					variables.testIndexName,
					"testdocs",
					{ "_source_includes" : "_id,title" }
				);

				expect( isNull( document ) ).toBeFalse();
				expect( document ).toBeComponent();
				expect( document.getMemento( true ) ).toBeStruct();
				expect( document.getId() ).toBe( variables.testDocumentId );
				expect( document.getMemento() ).toHaveKey( "title" );
				expect( document.getMemento().keyExists( "createdTime" ) ).toBeFalse();
			} );

			it( "Tests the ability to retrieve multiple documents with an array of identifiers", function(){
				expect( variables ).toHaveKey( "bulkInserts" );
				expect( variables ).toHaveKey( "testIndexName" );
				var identifiers = variables.bulkInserts.map( function( doc ){
					return doc.getId();
				} );
				var returned = variables.model.getMultiple( identifiers, variables.testIndexName );
				expect( returned ).toBeArray();
				expect( arrayLen( returned ) ).toBe( arrayLen( identifiers ) );
			} );

			it( "Tests the ability to update a document in an index", function(){
				expect( variables ).toHaveKey( "testDocumentId" );

				expect( variables ).toHaveKey( "testIndexName" );

				var existing = variables.model.get(
					variables.testDocumentId,
					variables.testIndexName,
					"testdocs"
				);

				expect( existing ).toBeComponent();
				expect( existing.getMemento( true ) ).toBeStruct();

				existing.setValue( "title", "My Updated Test Document" );

				var saveResult = variables.model.save( existing );

				expect( saveResult ).toBeComponent();

				expect( saveResult.getId() ).toBe( variables.testDocumentId );

				var updated = variables.model.get(
					variables.testDocumentId,
					variables.testIndexName,
					"testdocs"
				);

				expect( updated.getId() ).toBe( variables.testDocumentId );

				expect( updated.getMemento( true )[ "title" ] ).toBe( existing.getValue( "title" ) );
			} );

			it( "Tests the ability to process a search on an index", function(){
				expect( variables ).toHaveKey( "testDocumentId" );

				var searchBuilder = getWirebox()
					.getInstance( "SearchBuilder@cbElasticsearch" )
					.new( index = variables.testIndexName, type = "testdocs" );

				searchBuilder.match( "title", "Test" );

				var searchResult = variables.model.executeSearch( searchBuilder );

				expect( searchResult ).toBeComponent();
				expect( searchResult.getHits() ).toBeArray();

				expect( arrayLen( searchResult.getHits() ) ).toBeGT( 0 );
			} );

			it( "Tests error handling on executing search with an invalid index", function(){
				var searchBuilder = getWirebox()
					.getInstance( "SearchBuilder@cbElasticsearch" )
					.new( index = "noSuchIndex", type = "testdocs" );

				// confirm it throws at all
				expect( function(){
					variables.model.executeSearch( searchBuilder );
				} ).toThrow( "cbElasticsearch.native.index_not_found_exception" );

				try {
					variables.model.executeSearch( searchBuilder );
				} catch ( cbElasticsearch.native.index_not_found_exception exception ) {
					// expectations on exception content
					expect( isJSON( exception.extendedInfo ) ).toBeTrue();
					var extendedError = deserializeJSON( exception.extendedInfo );
					expect( extendedError ).toHaveKey( "error" );
					expect( extendedError.error ).toHaveKey( "root_cause" );
					expect( extendedError.error.root_cause ).toBeArray();
					expect( arrayLen( extendedError.error.root_cause ) ).toBeGT( 0 );
				}
			} );

			it( "Tests the ability to handle errors on a search request with an invalid payload", function(){
				var searchBuilder = getWirebox()
					.getInstance( "SearchBuilder@cbElasticsearch" )
					.new( index = variables.testIndexName, type = "testdocs" );
				searchBuilder.setQuery( { "invalid_syntax" : { "foo" : "bar" } } );

				expect( function(){
					variables.model.executeSearch( searchBuilder );
				} ).toThrow( "cbElasticsearch.native.parsing_exception" );
			} );

			it( "Tests the ability to count documents in an index", function(){
				expect( variables ).toHaveKey( "testDocumentId" );

				var searchBuilder = getWirebox()
					.getInstance( "SearchBuilder@cbElasticsearch" )
					.new( index = variables.testIndexName, type = "testdocs" );

				searchBuilder.match( "title", "Test" );

				var searchResult = variables.model.count( searchBuilder );

				expect( searchResult ).toBeNumeric();

				expect( searchResult ).toBeGT( 0 );
			} );

			it( "Tests the ability to boost a specific search match", function(){
				expect( variables ).toHaveKey( "bulkInserts" );

				// sleep for this test

				var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new();
				searchBuilder.setIndex( variables.testIndexName );
				searchBuilder.setType( "testdocs" );

				searchBuilder.match(
					name  = "title",
					value = "Document Number 3",
					boost = .5
				);

				var searchResults = variables.model.executeSearch( searchBuilder );

				expect( searchResults ).toBeComponent();
				expect( searchResults.getHits() ).toBeArray();

				expect( searchResults.getHitCount() ).toBeGT( 1 );

				var firstResult  = searchResults.getHits()[ 1 ];
				var secondResult = searchResults.getHits()[ arrayLen( searchResults.getHits() ) ];

				expect( firstResult.getScore() ).toBeGT( secondResult.getScore() );
			} );

			it( "Tests the ability to patch a document with a single field value", function(){
				expect( variables ).toHaveKey( "testDocumentId" );
				expect( variables ).toHaveKey( "testIndexName" );

				var document = variables.model.get(
					variables.testDocumentId,
					variables.testIndexName,
					"testdocs"
				);

				expect( isNull( document ) ).toBeFalse();

				expect( document.getMemento() ).toHaveKey( "title" );
				var oldValue = document.getMemento().title;
				var newValue = "Patched update to title field";

				expect( oldValue ).notToBe( newValue );

				variables.model.patch(
					variables.testIndexName,
					variables.testDocumentId,
					{ "title" : newValue },
					{ "refresh" : true }
				);

				expect(
					variables.model.get( variables.testDocumentId, variables.testIndexName ).getMemento().title
				).toBe( newValue );
			} );

			it( "Tests the ability to patch a document using a script", function(){
				expect( variables ).toHaveKey( "testDocumentId" );
				expect( variables ).toHaveKey( "testIndexName" );

				var document = variables.model.get(
					variables.testDocumentId,
					variables.testIndexName,
					"testdocs"
				);

				expect( isNull( document ) ).toBeFalse();

				expect( document.getMemento() ).toHaveKey( "title" );
				var oldValue = document.getMemento().title;
				var newValue = "Patched update to title field via script";

				expect( oldValue ).notToBe( newValue );

				var directive = {
					"script" : {
						"source" : "ctx._source.title = '#newValue#'",
						"lang"   : "painless"
					}
				};

				variables.model.patch(
					variables.testIndexName,
					variables.testDocumentId,
					directive,
					{ "refresh" : true }
				);

				expect(
					variables.model.get( variables.testDocumentId, variables.testIndexName ).getMemento().title
				).toBe( newValue );
			} );

			it( "Tests the ability to delete a document using a Document model object", function(){
				expect( variables ).toHaveKey( "testDocumentId" );
				expect( variables ).toHaveKey( "testIndexName" );

				var document = variables.model.get(
					variables.testDocumentId,
					variables.testIndexName,
					"testdocs"
				);

				expect( isNull( document ) ).toBeFalse();

				variables.model.delete( document );

				expect( variables.model.get( variables.testDocumentId ) ).toBeNull();
			} );

			it( "Tests the ability to delete a document by index and identifier", function(){
				expect( variables ).toHaveKey( "testIndexName" );

				var testDocument = {
					"_id"         : createUUID(),
					"title"       : "My Test Document for deletion",
					"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox()
					.getInstance( "Document@cbElasticsearch" )
					.new(
						variables.testIndexName,
						"testdocs",
						testDocument
					);

				var saveResult = variables.model.save( document, true );

				expect( variables.model.get( testDocument[ "_id" ], variables.testIndexName ) ).notToBeNull();

				variables.model.deleteById(
					variables.testIndexName,
					testDocument[ "_id" ],
					true,
					{ "refresh" : true }
				);

				expect( variables.model.get( testDocument[ "_id" ] ) ).toBeNull();
			} );

			it( "Tests the ability to delete documents by query synchronously", function(){
				expect( variables ).toHaveKey( "testIndexName" );

				var testDocument = {
					"_id"         : createUUID(),
					"title"       : "My Test Document",
					"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox()
					.getInstance( "Document@cbElasticsearch" )
					.new(
						variables.testIndexName,
						"testdocs",
						testDocument
					);

				var saveResult = variables.model.save( document );

				expect( variables.model.get( testDocument[ "_id" ], variables.testIndexName ) ).notToBeNull();

				var searchBuilder = getWirebox()
					.getInstance( "SearchBuilder@cbElasticsearch" )
					.new(
						variables.testIndexName,
						"testdocs",
						{ "match_all" : {} }
					);

				var deleteResult = variables.model.deleteByQuery( searchBuilder );

				expect( deleteResult ).toBeStruct();
				expect( deleteResult ).toHaveKey( "deleted" );
				expect( deleteResult.deleted ).toBeGT( 0 );
			} );

			it( "Tests the ability to delete documents by query asynchronously", function(){
				expect( variables ).toHaveKey( "testIndexName" );

				var testDocument = {
					"_id"         : createUUID(),
					"title"       : "My Async Test Document",
					"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox()
					.getInstance( "Document@cbElasticsearch" )
					.new(
						variables.testIndexName,
						"testdocs",
						testDocument
					);

				var saveResult = variables.model.save( document );

				expect( variables.model.get( testDocument[ "_id" ], variables.testIndexName ) ).notToBeNull();

				var searchBuilder = getWirebox()
					.getInstance( "SearchBuilder@cbElasticsearch" )
					.new(
						variables.testIndexName,
						"testdocs",
						{ "match_all" : {} }
					);

				var deleteResult = variables.model.deleteByQuery( searchBuilder, false );

				expect( deleteResult ).toBeInstanceOf( "cbElasticsearch.models.Task" );
			} );

			it( "Tests the ability to update documents by query synchronously", function(){
				expect( variables ).toHaveKey( "testIndexName" );

				// create document and save
				var testDocument = {
					"_id"         : createUUID(),
					"title"       : "My Test Document",
					"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox()
					.getInstance( "Document@cbElasticsearch" )
					.new(
						variables.testIndexName,
						"testdocs",
						testDocument
					);

				var saveResult = variables.model.save( document, true );

				var searchBuilder = getWireBox()
					.getInstance( "SearchBuilder@cbElasticSearch" )
					.new( variables.testIndexName, "testdocs" );

				searchBuilder.match( "title", "My Test Document" );

				var updateResult = variables.model.updateByQuery(
					searchBuilder,
					{
						"source" : "ctx._source['title'] = params.newInstanceValue",
						"lang"   : "painless",
						"params" : { "newInstanceValue" : "My Updated Test Document" }
					}
				);

				expect( updateResult ).toBeStruct();
				expect( updateResult ).toHaveKey( "updated" );
				expect( updateResult.updated ).toBeGT( 0 );

				var updatedDocument = getWirebox()
					.getInstance( "Document@cbElasticsearch" )
					.get(
						testDocument._id,
						variables.testIndexName,
						"testdocs"
					);

				expect( updatedDocument.getMemento().title ).toBe( "My Updated Test Document" );
			} );

			it( "Tests the ability to update documents by query asynchronously", function(){
				expect( variables ).toHaveKey( "testIndexName" );

				// create document and save
				var testDocument = {
					"_id"         : createUUID(),
					"title"       : "My Test Document",
					"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				};

				var document = getWirebox()
					.getInstance( "Document@cbElasticsearch" )
					.new(
						variables.testIndexName,
						"testdocs",
						testDocument
					);

				var saveResult = variables.model.save( document, true );

				var searchBuilder = getWireBox()
					.getInstance( "SearchBuilder@cbElasticSearch" )
					.new( variables.testIndexName, "testdocs" );

				searchBuilder.match( "title", "My Test Document" );

				var updateResult = variables.model.updateByQuery(
					searchBuilder,
					{
						"source" : "ctx._source['title'] = params.newInstanceValue",
						"lang"   : "painless",
						"params" : { "newInstanceValue" : "My Updated Test Document" }
					},
					false
				);

				expect( updateResult ).toBeInstanceOf( "cbElasticsearch.models.Task" );
			} );


			it( "Tests the ability to delete an index", function(){
				expect( variables ).toHaveKey( "testIndexName" );
				var deletion = variables.model.deleteIndex( variables.testIndexName );

				expect( deletion ).toBeStruct();
				expect( deletion ).toHaveKey( "acknowledged" );
				expect( deletion[ "acknowledged" ] ).toBeTrue();
			} );

			describe( "reindex", function(){
				beforeEach( function(){
					variables.testIndexNameOne = lCase( "ElasticsearchClientTestsOne" );
					variables.testIndexNameTwo = lCase( "ElasticsearchClientTestsTwo" );

					variables.model.deleteIndex( variables.testIndexNameOne );
					variables.model.deleteIndex( variables.testIndexNameTwo );
				} );

				it( "can reindex from one index to another", function(){
					var indexOne = getWireBox()
						.getInstance( "IndexBuilder@cbElasticSearch" )
						.new( variables.testIndexNameOne );

					variables.model.applyIndex( indexOne );

					var indexTwo = getWireBox()
						.getInstance( "IndexBuilder@cbElasticSearch" )
						.new( variables.testIndexNameTwo );

					variables.model.applyIndex( indexTwo );

					// insert some documents to reindex
					var documents = [];
					for ( var i = 1; i <= 13; i++ ) {
						arrayAppend(
							documents,
							getInstance( "Document@cbElasticsearch" ).new(
								variables.testIndexNameOne,
								"testdocs",
								{
									"_id"         : createUUID(),
									"title"       : "Test Document Number #i#",
									"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
								}
							)
						);
					}

					var savedDocs = variables.model.saveAll( documents=documents, params={ "refresh" : "wait_for" } );

					var searchOne = getWireBox()
						.getInstance( "SearchBuilder@cbElasticSearch" )
						.new(
							variables.testIndexNameOne,
							"testdocs",
							{ "query" : { "match_all" : {} } }
						);

					var searchTwo = getWireBox()
						.getInstance( "SearchBuilder@cbElasticSearch" )
						.new(
							variables.testIndexNameTwo,
							"testdocs",
							{ "query" : { "match_all" : {} } }
						);

					expect( variables.model.count( searchOne ) ).toBe( 13 );
					expect( variables.model.count( searchTwo ) ).toBe(
						0,
						"No documents should exists in the second index"
					);

					variables.model.reindex(
						source      = variables.testIndexNameOne,
						destination = variables.testIndexNameTwo,
						waitForCompletion = true
					);

					// We still have to wait for background indexing to update
					sleep( 1500 );

					expect( variables.model.count( searchTwo ) ).toBe(
						variables.model.count( searchOne ),
						"All the documents from the first index should exist in the second index"
					);
				} );

				it( "can pass structs for the source and destination when reindexing", function(){
					variables.model.deleteIndex( variables.testIndexNameOne );
					variables.model.deleteIndex( variables.testIndexNameTwo );

					var indexOne = getWireBox()
						.getInstance( "IndexBuilder@cbElasticSearch" )
						.new( variables.testIndexNameOne );

					variables.model.applyIndex( indexOne );

					var indexTwo = getWireBox()
						.getInstance( "IndexBuilder@cbElasticSearch" )
						.new( variables.testIndexNameTwo );

					variables.model.applyIndex( indexTwo );

					// //insert some documents to reindex
					var documents = [];
					for ( var i = 1; i <= 10; i++ ) {
						arrayAppend(
							documents,
							getInstance( "Document@cbElasticsearch" ).new(
								variables.testIndexNameOne,
								"testdocs",
								{
									"_id"         : createUUID(),
									"title"       : "Test Document Number #i#",
									"flag"        : i % 2 == 0 ? "flag" : "noflag",
									"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
								}
							)
						);
					}

					var savedDocs = variables.model.saveAll( documents=documents, params={ "refresh" : "wait_for" } );

					var searchOne = getWireBox()
						.getInstance( "SearchBuilder@cbElasticSearch" )
						.new(
							variables.testIndexNameOne,
							"testdocs",
							{ "query" : { "match_all" : {} } }
						);

					var searchTwo = getWireBox()
						.getInstance( "SearchBuilder@cbElasticSearch" )
						.new(
							variables.testIndexNameTwo,
							"testdocs",
							{ "query" : { "match_all" : {} } }
						);

					expect( variables.model.count( searchOne ) ).toBe( 10 );
					expect( variables.model.count( searchTwo ) ).toBe( 0 );

					variables.model.reindex(
						source = {
							"index" : variables.testIndexNameOne,
							"query" : { "term" : { "flag.keyword" : "flag" } }
						},
						destination       = variables.testIndexNameTwo,
						waitForCompletion = true
					);

					// We still have to wait for background indexing to update
					sleep( 1500 );

					expect( variables.model.count( searchTwo ) ).toBe( 5 );
				} );

				it( "throws an exception when a reindex error occurs by default", function(){
					expect( function(){
						variables.model.reindex(
							source            = { "index" : "no_such_index", "type" : "testdocs" },
							destination       = "another_nonexistent_index",
							waitForCompletion = true
						);
					} ).toThrow( type = "cbElasticsearch.HyperClient.ReindexFailedException" );
				} );
			} );

			describe( "tasks", function(){
				it( "can retrieve all tasks on the cluster", function(){
					var activeTasks = variables.model.getTasks();
					expect( activeTasks ).toBeArray();
					activeTasks.each( function( task ){
						expect( task ).toBeInstanceOf( "cbelasticsearch.models.Task" );
					} );
				} );

				it( "can retrieve the status of a single task", function(){
					// create some documents so we can fire an upate by query
					var documents = [];
					for ( var i = 1; i <= 10000; i++ ) {
						var bulkDoc = {
							"_id"         : createUUID(),
							"title"       : "Test Document Number #i#",
							"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" ),
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

					var searchBuilder = getInstance( "SearchBuilder@cbelasticsearch" ).new(
						variables.testIndexName,
						"testdocs"
					);
					searchBuilder.match( "title", "Test" );

					searchBuilder.param( "wait_for_completion", false );

					var taskId = variables.model.updateByQuery(
						searchBuilder,
						{
							"source" : "ctx._source.longDescription = ctx._source.description;",
							"lang"   : "painless"
						}
					).task;

					var taskObj = variables.model.getTask( taskId );
					expect( taskObj ).toBeInstanceOf( "cbelasticsearch.models.Task" );
					expect( taskObj.getCompleted() ).toBeBoolean();
					expect( taskObj.getIdentifier() ).toBe( taskId );
					expect( taskObj.isComplete() ).toBeBoolean();

					// expect a while loop to complete
					while ( !taskObj.isComplete() ) {
						expect( taskObj.getCompleted() ).toBeFalse();
					}
				} );
			} );

			describe( "pipelines", function(){
				beforeEach( function(){
					variables.testPipeline = getWirebox()
						.getInstance( "Pipeline@cbelasticsearch" )
						.new( {
							"id"          : "pipeline-test",
							"description" : "A test pipeline",
							"version"     : 1,
							"processors"  : [
								{
									"set" : {
										"if"    : "ctx.foo == null",
										"field" : "foo",
										"value" : "bar"
									}
								}
							]
						} );
				} );

				it( "Tests the ability to create pipeline", function(){
					var created = variables.model.applyPipeline( variables.testPipeline );
					expect( created ).toBeBoolean().toBeTrue();
				} );

				it( "Tests the ability to get the definition of a pipeline", function(){
					var pipeline = variables.model.getPipeline( variables.testPipeline.getId() );
					expect( pipeline )
						.toBeStruct()
						.toHaveKey( "version" )
						.toHaveKey( "processors" )
						.toHaveKey( "description" );
				} );

				it( "Tests the ability to update an existing pipeline", function(){
					variables.testPipeline.setVersion( 2 );
					variables.testPipeline.addProcessor( {
						"set" : {
							"if"    : "ctx.foo == 'bar'",
							"field" : "foo",
							"value" : "baz"
						}
					} );
					var updated = variables.model.applyPipeline( variables.testPipeline );
					expect( updated ).toBeBoolean().toBeTrue();

					var pipeline = variables.model.getPipeline( variables.testPipeline.getId() );

					expect( pipeline.processors ).toBeArray().toHaveLength( 2 );
				} );

				it( "Tests the ability to delete a pipeline", function(){
					expect( variables.model.deletePipeline( variables.testPipeline.getId() ) )
						.toBeBoolean()
						.toBeTrue();
				} );

				it( "Tests that deleting a pipeline will return false if the pipline does not exist", function(){
					expect( variables.model.deletePipeline( "my-non-existent-pipeline" ) )
						.toBeBoolean()
						.toBeFalse();
				} );

				it( "Can save documents with an applied pipeline", function(){
					variables.model.applyPipeline( variables.testPipeline );

					expect( isNull( variables.model.getPipeline( "pipeline-test" ) ) ).toBeFalse();

					var document = getWirebox()
						.getInstance( "Document@cbElasticsearch" )
						.new(
							index      = variables.testIndexName,
							properties = { "id" : createUUID(), "name" : "My test document" }
						);
					document.setPipeline( "pipeline-test" );

					// refresh immediately so we can grab our changed document
					document.addParam( "refresh", true );

					document = variables.model.save( document, true );

					expect( document.getMemento() ).toHaveKey( "foo" );

					expect( document.getMemento()[ "foo" ] ).toBe( "bar" );
				} );
			} );
		} );
	}

}
