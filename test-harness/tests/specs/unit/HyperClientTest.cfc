component extends="coldbox.system.testing.BaseTestCase" {

	this.loadColdbox = true;

	function beforeAll(){
		super.beforeAll();
		if ( !structKeyExists( variables, "model" ) ) {
			variables.model = new cbelasticsearch.models.io.HyperClient();
			getWirebox().autoWire( variables.model );
			prepareMock( variables.model );
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

			it( "Tests the ability to create an index", function(){
				var builderProperties = {
					"mappings" : {
						"properties" : {
							"title" : {
								"type"   : "text",
								"fields" : { "kw" : { "type" : "keyword" } }
							},
							"createdTime" : { "type" : "date", "format" : "date_time_no_millis" },
							"price" : { "type" : "float" }
						}
					}
				};

				var indexBuilder = getWirebox()
					.getInstance( "IndexBuilder@cbelasticsearch" )
					.new( name = variables.testIndexName, properties = builderProperties );
				expect( indexBuilder ).toBeComponent();
				expect( indexBuilder.getMappings() ).toBeStruct();
				expect( indexBuilder.getMappings() ).toHaveKey( "properties" );
				expect( indexBuilder.getMappings().properties ).toHaveKey( "title" );
				var indexResult = variables.model.applyIndex( indexBuilder );

				expect( indexResult ).toBeTrue();
			} );

			describe( "Index mappings and settings and utility methods", function(){

				it( "Tests the ability to update mappings in an index", function(){

					expect( variables.model.indexExists( variables.testIndexName ) ).toBeTrue();
					var mappingUpdates = {
						"mappings" : {
							"properties" : {
								"modifiedTime" : { "type" : "date", "format" : "date_time_no_millis" }
							}
						}
					};

					var indexBuilder = getWirebox()
						.getInstance( "IndexBuilder@cbelasticsearch" )
						.new( name = variables.testIndexName, properties = mappingUpdates );
						
					var indexResult = variables.model.applyIndex( indexBuilder );

					expect( indexResult ).toBeTrue();

					var mappings = variables.model.getMappings( variables.testIndexName );
					
					expect( mappings ).toHaveKey( "properties" );

					expect( mappings.properties ).toHaveKey( "modifiedTime" );
					expect( mappings.properties.modifiedTime ).toHaveKey( "format" );

					var fieldMappings = variables.model.getMappings( variables.testIndexName, "*modifiedTime*" );

					debug( fieldMappings );

					expect( fieldMappings )
						.toBeStruct()
						.toHaveKey( "modifiedTime" );

					expect( fieldMappings.modifiedTime ).toBeStruct()
						.toHaveKey( "full_name" )
						.toHaveKey( "mapping" )
						.toHaveKey( "indices" );
					
				} );

				it( "Tests the ability to update settings in an index", function(){

					expect( variables.model.indexExists( variables.testIndexName ) ).toBeTrue();
					var settingsUpdates = {
						"settings" : {
							"index" : {
								"refresh_interval" : "1s"
							}
						}
					};

					var indexBuilder = getWirebox()
						.getInstance( "IndexBuilder@cbelasticsearch" )
						.new( name = variables.testIndexName, properties = settingsUpdates );

					var indexResult = variables.model.applyIndex( indexBuilder );

					expect( indexResult ).toBeTrue();

					var settings = variables.model.getSettings( variables.testIndexName );

					expect( settings ).toBeStruct().toHaveKey( "index" );
					expect( settings.index ).toHaveKey( "refresh_interval" );
					expect( settings.index.refresh_interval ).toBe( settingsUpdates.settings.index.refresh_interval );
					
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
					
					expect( allAliases.aliases[ aliasName ] ).toBeArray();
				} );
			} );

			describe( "Document tests", function(){


				it( "Tests the ability to insert a document in to an index", function(){
					expect( variables ).toHaveKey( "testIndexName" );

					var testDocument = {
						"_id"         : createUUID(),
						"title"       : "My Test Document",
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
					};

					var document = getWirebox()
						.getInstance( "Document@cbelasticsearch" )
						.new(
							variables.testIndexName,
							"_doc",
							testDocument
						);

					var saveResult = variables.model.save( document );

					expect( saveResult ).toBeComponent();
					expect( saveResult.getId() ).toBe( testDocument[ "_id" ] );

					variables.testDocumentId = saveResult.getId();
				} );
				it( "Tests document save with refresh=wait_for", function(){
					expect( variables ).toHaveKey( "testIndexName" );

					var testDocument = {
						"_id"         : createUUID(),
						"title"       : "My Test Document",
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
					};

					var document = getWirebox()
						.getInstance( "Document@cbelasticsearch" )
						.new(
							variables.testIndexName,
							"_doc",
							testDocument
						);

					var saveResult = variables.model.save( document, "wait_for" );

					expect( saveResult ).toBeComponent();
					expect( saveResult.getId() ).toBe( testDocument[ "_id" ] );

					var existingDocument = getWirebox()
						.getInstance( "Document@cbelasticsearch" )
						.get( saveResult.getId(), variables.testIndexName );
					expect( existingDocument ).notToBeNull();
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
							"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
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
							"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
						};

						arrayAppend(
							documents,
							getInstance( "Document@cbelasticsearch" ).new(
								variables.testIndexName,
								"_doc",
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
							"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
						};

						arrayAppend(
							documents,
							getInstance( "Document@cbelasticsearch" ).new(
								variables.testIndexName,
								"_doc",
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
							"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
						};

						arrayAppend(
							documents,
							getInstance( "Document@cbelasticsearch" ).new(
								variables.testIndexName,
								"_doc",
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
						"_doc"
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
						"_doc",
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
						"_doc"
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
						"_doc"
					);

					expect( updated.getId() ).toBe( variables.testDocumentId );

					expect( updated.getMemento( true )[ "title" ] ).toBe( existing.getValue( "title" ) );
				} );

			} );

			describe( "Search tests", function(){

				it( "Tests the ability to process a search on an index", function(){
					expect( variables ).toHaveKey( "testDocumentId" );

					var searchBuilder = getWirebox()
						.getInstance( "SearchBuilder@cbelasticsearch" )
						.new( index = variables.testIndexName, type = "_doc" );

					searchBuilder.match( "title", "Test" );

					var searchResult = variables.model.executeSearch( searchBuilder );

					expect( searchResult ).toBeComponent();
					expect( searchResult.getHits() ).toBeArray();

					expect( arrayLen( searchResult.getHits() ) ).toBeGT( 0 );
				} );

				it( "Tests error handling on executing search with an invalid index", function(){
					var searchBuilder = getWirebox()
						.getInstance( "SearchBuilder@cbelasticsearch" )
						.new( index = "noSuchIndex", type = "_doc" );

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
						.getInstance( "SearchBuilder@cbelasticsearch" )
						.new( index = variables.testIndexName, type = "_doc" );
					searchBuilder.setQuery( { "invalid_syntax" : { "foo" : "bar" } } );

					expect( function(){
						variables.model.executeSearch( searchBuilder );
					} ).toThrow( "cbElasticsearch.native.parsing_exception" );
				} );

				it( "Tests the ability to count documents in an index", function(){
					expect( variables ).toHaveKey( "testDocumentId" );

					var searchBuilder = getWirebox()
						.getInstance( "SearchBuilder@cbelasticsearch" )
						.new( index = variables.testIndexName, type = "_doc" );

					searchBuilder.match( "title", "Test" );

					var searchResult = variables.model.count( searchBuilder );

					expect( searchResult ).toBeNumeric();

					expect( searchResult ).toBeGT( 0 );
				} );

				it( "Tests the ability to boost a specific search match", function(){
					expect( variables ).toHaveKey( "bulkInserts" );

					// sleep for this test

					var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbelasticsearch" ).new();
					searchBuilder.setIndex( variables.testIndexName );
					searchBuilder.setType( "_doc" );

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

				it( "Tests custom script fields", function(){
					getWirebox().getInstance( "Document@cbelasticsearch" ).new(
						variables.testIndexName,
						"testdocs", {
							"_id"         : createUUID(),
							"title"       : "My Test Document",
							"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" ),
							"price"       : 9.99
						} )
						.save( refresh = true );
					var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbelasticsearch" ).new(
						variables.testIndexName,
						"testdocs",
						{ "match_all" : {} }
					);
	
					searchBuilder.addScriptField( "interestCost", {
						"script": {
							"lang": "painless",
							"source": "return doc['price'].size() != 0 ? doc['price'].value * (params.interestRate/100) : null;",
							"params": { "interestRate": 5.5 }
						}
					} );
	
					var hits = variables.model.executeSearch( searchBuilder ).getHits();
					expect( hits.len() ).toBeGT( 0 );
					for( hit in hits ){
						expect( hit.getFields() ).toHaveKey( "interestCost" );
						expect( hit.getDocument( includeFields = true ) ).toHaveKey( "interestCost" );
						expect( hit.getDocument() ).notToHaveKey( "interestCost" );
					}
				} );

				it( "Tests runtime fields", function(){
					getWirebox().getInstance( "IndexBuilder@cbelasticsearch" )
						.patch( name = variables.testIndexName, properties = {
							"mappings" : {
								"runtime" : {
									"price_in_cents" : {
										"type" : "long",
										"script" : {
											"source" : "if( doc['price'].size() != 0) { emit(Math.round(doc['price'].value * 100 )); }"
										}
									}
								}
							}
						} );
					getWirebox().getInstance( "Document@cbelasticsearch" ).new(
						variables.testIndexName,
						"testdocs",
						{
							"_id"         : createUUID(),
							"title"       : "My Test Document",
							"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" ),
							"price"       : 9.99
						} )
						.save( refresh = true );
					var searchBuilder = getWirebox().getInstance( "SearchBuilder@cbelasticsearch" ).new(
						variables.testIndexName,
						"testdocs"
					)
					.filterTerm( "price_in_cents", "999" )
					.addField( "price_in_cents" );

					var hits = variables.model.executeSearch( searchBuilder ).getHits();
					expect( hits.len() ).toBeGT( 0 );
					for( hit in hits ){
						expect( hit.getFields() ).toHaveKey( "price_in_cents" );
						expect( hit.getDocument( includeFields = true ) ).toHaveKey( "price_in_cents" );
						expect( hit.getDocument() ).notToHaveKey( "price_in_cents" );
						expect( hit.getMemento() ).notToHaveKey( "price_in_cents" );
					}
				} );
			} );

			describe( "More fun with documents", function(){

				it( "Tests the ability to patch a document with a single field value", function(){
					expect( variables ).toHaveKey( "testDocumentId" );
					expect( variables ).toHaveKey( "testIndexName" );

					var document = variables.model.get(
						variables.testDocumentId,
						variables.testIndexName,
						"_doc"
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
						"_doc"
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
						"_doc"
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
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
					};

					var document = getWirebox()
						.getInstance( "Document@cbelasticsearch" )
						.new(
							variables.testIndexName,
							"_doc",
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
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
					};

					var document = getWirebox()
						.getInstance( "Document@cbelasticsearch" )
						.new(
							variables.testIndexName,
							"_doc",
							testDocument
						);

					var saveResult = variables.model.save( document );

					expect( variables.model.get( testDocument[ "_id" ], variables.testIndexName ) ).notToBeNull();

					var searchBuilder = getWirebox()
						.getInstance( "SearchBuilder@cbelasticsearch" )
						.new(
							variables.testIndexName,
							"_doc",
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
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
					};

					var document = getWirebox()
						.getInstance( "Document@cbelasticsearch" )
						.new(
							variables.testIndexName,
							"_doc",
							testDocument
						);

					var saveResult = variables.model.save( document );

					expect( variables.model.get( testDocument[ "_id" ], variables.testIndexName ) ).notToBeNull();

					var searchBuilder = getWirebox()
						.getInstance( "SearchBuilder@cbelasticsearch" )
						.new(
							variables.testIndexName,
							"_doc",
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
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
					};

					var document = getWirebox()
						.getInstance( "Document@cbelasticsearch" )
						.new(
							variables.testIndexName,
							"_doc",
							testDocument
						);

					var saveResult = variables.model.save( document, true );

					var searchBuilder = getWireBox()
						.getInstance( "SearchBuilder@cbElasticSearch" )
						.new( variables.testIndexName, "_doc" );

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
						.getInstance( "Document@cbelasticsearch" )
						.get(
							testDocument._id,
							variables.testIndexName,
							"_doc"
						);

					expect( updatedDocument.getMemento().title ).toBe( "My Updated Test Document" );
				} );

				it( "Tests the ability to update documents by query asynchronously", function(){
					expect( variables ).toHaveKey( "testIndexName" );

					// create document and save
					var testDocument = {
						"_id"         : createUUID(),
						"title"       : "My Test Document",
						"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
					};

					var document = getWirebox()
						.getInstance( "Document@cbelasticsearch" )
						.new(
							variables.testIndexName,
							"_doc",
							testDocument
						);

					var saveResult = variables.model.save( document, true );

					var searchBuilder = getWireBox()
						.getInstance( "SearchBuilder@cbElasticSearch" )
						.new( variables.testIndexName, "_doc" );

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

			} );

			describe( "Post index creation tests", function(){

				it( "Tests refreshIndex method ", function(){
					expect( variables ).toHaveKey( "testIndexName" );

					// test against existing index
					var refreshResult = variables.model.refreshIndex( variables.testIndexName );

					expect( refreshResult.keyExists( "_shards" ) ).toBeTrue();
					expect( refreshResult.keyExists( "error" ) ).toBeFalse();

					// test against nonexistent index
					refreshResult = variables.model.refreshIndex( "doesnotexist" );

					expect( refreshResult.keyExists( "error" ) ).toBeTrue();
					expect( refreshResult.status ).toBe( "404" );

					// test against nonexistent index, with ignore nonexistent
					refreshResult = variables.model.refreshIndex( [ "doesnotexist", "alsonotexist" ], { "ignore_unavailable" : true } );

					expect( refreshResult.keyExists( "error" ) ).toBeFalse();
					expect( refreshResult ).toHaveKey( "_shards" );
					expect( refreshResult._shards ).toHaveKey( "total" );
					expect( refreshResult._shards.total ).toBe( 0 );
				} );

				describe( "termVectors", function() {
					it( "can get term vectors by document ID", function() {
						expect( variables ).toHaveKey( "testIndexName" );

						// create document and save
						var testDocument = {
							"_id"         : createUUID(),
							"title"       : "My Test Document",
							"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
						};

						var document = getWirebox()
							.getInstance( "Document@cbelasticsearch" )
							.new(
								variables.testIndexName,
								"_doc",
								testDocument
							).save( refresh = true );
						var result = variables.model.getTermVectors(
							variables.testIndexName,
							testDocument._id,
							"title"
						);
debug( result );
						expect( result.keyExists( "error" ) ).toBeFalse();
						expect( result.keyExists( "term_vectors" ) ).toBeTrue();
						expect( result.term_vectors ).toHaveKey( "title" );
						expect( result.term_vectors.title ).toBeStruct()
															.toHaveKey( "field_statistics" )
															.toHaveKey( "terms" );
					});
					it( "can get term vectors by doc payload", function(){
						expect( variables ).toHaveKey( "testIndexName" );
	
						// test options
						var result = variables.model.getTermVectors(
							indexName = variables.testIndexName,
							options = {
								"doc" : {
									"title" : "My test document"
								},
								"filter" : {
									"min_word_length" : 3
								}
							}
						);
	
						expect( result.keyExists( "error" ) ).toBeFalse();
						expect( result ).toHaveKey( "term_vectors" );
	
						// ensure only short terms returned
						expect( result.term_vectors.title.terms )
									.toHaveKey( "document" )
									.notToHaveKey( "my" );
					} );
				});

				it( "Tests getIndexStats method ", function(){
					expect( variables ).toHaveKey( "testIndexName" );

					var stats = variables.model.getIndexStats( variables.testIndexName, [ "_all" ] );

					expect( stats.keyExists( "_all" ) ).toBeTrue();

					// test with query params
					stats = variables.model.getIndexStats(
						variables.testIndexName,
						[ "indexing", "search" ],
						{ "level" : "shards" }
					);

					expect( stats.keyExists( "_all" ) ).toBeTrue();

					// test with no index name == all indices
					stats = variables.model.getIndexStats( indexName = "", metrics = [ "indexing" ] );

					expect( stats.keyExists( "_all" ) ).toBeTrue();
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
								getInstance( "Document@cbelasticsearch" ).new(
									variables.testIndexNameOne,
									"_doc",
									{
										"_id"         : createUUID(),
										"title"       : "Test Document Number #i#",
										"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
									}
								)
							);
						}

						var savedDocs = variables.model.saveAll( documents=documents, params={ "refresh" : "wait_for" } );

						var searchOne = getWireBox()
							.getInstance( "SearchBuilder@cbElasticSearch" )
							.new(
								variables.testIndexNameOne,
								"_doc",
								{ "query" : { "match_all" : {} } }
							);

						var searchTwo = getWireBox()
							.getInstance( "SearchBuilder@cbElasticSearch" )
							.new(
								variables.testIndexNameTwo,
								"_doc",
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
								getInstance( "Document@cbelasticsearch" ).new(
									variables.testIndexNameOne,
									"_doc",
									{
										"_id"         : createUUID(),
										"title"       : "Test Document Number #i#",
										"flag"        : i % 2 == 0 ? "flag" : "noflag",
										"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" )
									}
								)
							);
						}

						var savedDocs = variables.model.saveAll( documents=documents, params={ "refresh" : "wait_for" } );

						var searchOne = getWireBox()
							.getInstance( "SearchBuilder@cbElasticSearch" )
							.new(
								variables.testIndexNameOne,
								"_doc",
								{ "query" : { "match_all" : {} } }
							);

						var searchTwo = getWireBox()
							.getInstance( "SearchBuilder@cbElasticSearch" )
							.new(
								variables.testIndexNameTwo,
								"_doc",
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
								source            = { "index" : "no_such_index", "type" : "_doc" },
								destination       = "another_nonexistent_index",
								waitForCompletion = true
							);
						} ).toThrow( type = "cbElasticsearch.HyperClient.ReindexFailedException" );
					} );
				} );
			});

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
							"createdTime" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" ),
							"description" : "Document Number #i# of 10,000"
						};

						arrayAppend(
							documents,
							getInstance( "Document@cbelasticsearch" ).new(
								variables.testIndexName,
								"_doc",
								bulkDoc
							)
						);
					}

					variables.model.saveAll( documents );

					var searchBuilder = getInstance( "SearchBuilder@cbelasticsearch" ).new(
						variables.testIndexName,
						"_doc"
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
						.getInstance( "Document@cbelasticsearch" )
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

			describe( "ILM policies", function(){
				beforeEach( function(){
					variables.testPolicyName = "es-client-test-policy";
					variables.testPolicy = {
						"_meta" : {
							"description" : "Test Policy"
						},
						"phases": {
							"delete": {
								"min_age": "1h",
								"actions": {
								"delete": {}
								}
							}
						}
					};
					variables.model.applyILMPolicy( testPolicyName, testPolicy );
				} );
				it( "Can create a new ILM policy", function(){
					variables.testPolicyName = "es-client-test-creation";
					var response = variables.model.applyILMPolicy(
						testPolicyName,
						testPolicy
					);

					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();

				} );

				it( "Can retrieve an ILM policy", function(){
					var response = variables.model.getILMPolicy( testPolicyName );
					expect( response ).toBeStruct()
										.toHaveKey( testPolicyName );
					var definition = response[ testPolicyName ];
					expect( definition )
						.toHaveKey( "policy" )
						.toHaveKey( "in_use_by" )
						.toHaveKey( "version" );
				} );

				it( "Can delete an ILM policy", function(){
					var response = variables.model.deleteILMPolicy( testPolicyName );
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();
				} );
			});

			describe( "Snapshot Repositories", function(){
				beforeEach( function(){
					variables.testSnapshotName = "my-snapshot-repository";
				});
				afterEach(function(){
					try{
						variables.model.deleteSnapshotRepository( variables.testSnapshotName );
					}catch( any e ){}
				});

				it( "Can create a snapshot repository with a location string as the definition", function(){
					var response = variables.model.applySnapshotRepository(
						variables.testSnapshotName,
						"/tmp/my-snapshots"
					);
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();
				} );

				it( "Can create a snapshot repository with a full configuration struct", function(){
					var response = variables.model.applySnapshotRepository(
						variables.testSnapshotName,
						{
							"type": "url",
							"settings": {
							  "url": "file:/tmp/my-url-snapshots"
							}
						}

					);
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();
				} );

				it( "Can determine whether a snapshot repository exists", function(){
					variables.model.applySnapshotRepository(
						variables.testSnapshotName,
						"/tmp/my-snapshots"
					);

					expect( variables.model.snapshotRepositoryExists( variables.testSnapshotName) ).toBeTrue();
				});

				it( "Can delete a snapshot repository", function(){
					variables.model.applySnapshotRepository(
						variables.testSnapshotName,
						"/tmp/my-snapshots"
					);
					var response = variables.model.deleteSnapshotRepository( variables.testSnapshotName );
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();

				} );
			} );

			// We declare these here so we can use them in the next two steps
			variables.testComponentTemplate = "my-component-template";
			variables.testComponentDefinition = {
				"_meta" : {
					"description" : "Test component template"
				},
				"template" : {
					"mappings" : {
						"dynamic_templates" : [
							{
								"message_field" : {
									"path_match"         : "message",
									"match_mapping_type" : "string",
									"mapping"            : {
										"type"   : "text",
										"norms"  : false,
										"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 1024 } }
									}
								}
							},
							{
								"string_fields" : {
									"match"              : "*",
									"match_mapping_type" : "string",
									"mapping"            : {
										"type"   : "text",
										"norms"  : false,
										"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
									}
								}
							}
						],
						"properties" : {
							// default logstash template properties
							"@timestamp" : { "type" : "date" },
							"@version"   : { "type" : "keyword" },
							"geoip"      : {
								"dynamic"    : true,
								"properties" : {
									"ip"        : { "type" : "ip" },
									"location"  : { "type" : "geo_point" },
									"latitude"  : { "type" : "half_float" },
									"longitude" : { "type" : "half_float" }
								}
							},
							// Customized properties
							"timestamp"    : { "type" : "date", "format" : "date_time_no_millis" },
							"type"         : { "type" : "keyword" },
							"application"  : { "type" : "keyword" },
							"environment"  : { "type" : "keyword" },
							"release"      : { "type" : "keyword" },
							"level"        : { "type" : "keyword" },
							"severity"     : { "type" : "integer" },
							"category"     : { "type" : "keyword" },
							"appendername" : { "type" : "keyword" },
							"stachebox"    : {
								"type"       : "object",
								"properties" : {
									"signature"    : { "type" : "keyword" },
									"isSuppressed" : { "type" : "boolean" }
								}
							}
						}
					}
				}
			};

			variables.testIndexTemplate = "my-index-template";

			variables.testIndexDefinition = {
				"index_patterns": ["my-data-stream*"],
				"data_stream": {},
				"composed_of": [ 
					"logs-mappings",
					"data-streams-mappings",
					"logs-settings", 
					variables.testComponentTemplate 
				],
				"priority": 500,
				"_meta": {
					"description": "Testbox testing index template",
					"foo": "Bar!"
				}
			};

			describe( "Component Templates", function(){
				beforeEach( function(){
					variables.testComponentTemplate = "my-component-template";
				});
				
				afterEach(function(){
					if( variables.model.indexTemplateExists( variables.testIndexTemplate ) ){
						variables.model.deleteIndexTemplate( variables.testIndexTemplate );
					}
					if( variables.model.componentTemplateExists( variables.testComponentTemplate ) ){
						variables.model.deleteComponentTemplate( variables.testComponentTemplate );
					}
				});

				it( "Can create a component template", function(){
					var response = variables.model.applyComponentTemplate(
						variables.testComponentTemplate,
						variables.testComponentDefinition
					);
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();
				} );

				it( "Can determine whether a component template exists", function(){
					variables.model.applyComponentTemplate(
						variables.testComponentTemplate,
						variables.testComponentDefinition
					);
					expect( variables.model.componentTemplateExists( variables.testComponentTemplate) ).toBeTrue();
				});

				it( "Can delete a component template", function(){
					variables.model.applyComponentTemplate(
						variables.testComponentTemplate,
						variables.testComponentDefinition
					);
					var response = variables.model.deleteComponentTemplate( variables.testComponentTemplate );
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();

				} );

			} );

			describe( "Index Templates", function(){
				beforeEach(function(){
					variables.testIndexTemplate = "my-index-template";
					variables.model.applyComponentTemplate(
						variables.testComponentTemplate,
						variables.testComponentDefinition
					);

				});

				afterEach( function(){
					try{
						variables.model.deleteIndexTemplate( variables.testIndexTemplate );
					}catch( any e ){}
				} );

				it( "Can create an index template", function(){
					var response = variables.model.applyIndexTemplate(
						variables.testIndexTemplate,
						variables.testIndexDefinition
					);
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();
				} );

				it( "Can determine whether an index template exists", function(){
					variables.model.applyIndexTemplate(
						variables.testIndexTemplate,
						variables.testIndexDefinition
					);
					expect( variables.model.indexTemplateExists( variables.testIndexTemplate) ).toBeTrue();
				});

				it( "Can delete an index template", function(){
					variables.model.applyIndexTemplate(
						variables.testIndexTemplate,
						variables.testIndexDefinition
					);
					var response = variables.model.deleteIndexTemplate( variables.testIndexTemplate );
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();

				} );

			} );

			describe( "Data Streams", function(){
				beforeEach(function(){
					variables.testDataStream = "my-data-stream-123";
					variables.model.applyComponentTemplate(
						variables.testComponentTemplate,
						variables.testComponentDefinition
					);
					variables.model.applyIndexTemplate(
						variables.testIndexTemplate,
						variables.testIndexDefinition
					);
				});

				afterEach( function(){
					try{
						variables.model.deleteDataStream( variables.testDataStream );
					}catch( any e ){}
				} );

				it( "can test whether a data stream exists", function(){
					expect( variables.model.dataStreamExists( variables.testDataStream ) ).toBeFalse();
				} );

				it( "can create a datastream", function(){
					var response = variables.model.ensureDataStream( variables.testDataStream );
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();
				} );

				it( "can get a datastream definition", function(){
					variables.model.ensureDataStream( variables.testDataStream );
					var response = variables.model.getDataStream( variables.testDataStream );
					expect( response ).toBeStruct().toHaveKey( "data_streams" );
					expect( response.data_streams ).toBeArray().toHaveLength( 1 );
				} );

				it( "can delete a data stream", function(){
					variables.model.ensureDataStream( variables.testDataStream );
					var response = variables.model.deleteDataStream( variables.testDataStream );
					expect( response ).toBeStruct().toHaveKey( "acknowledged" );
					expect( response.acknowledged ).toBeTrue();
				} );

			} );

			describe( "General requests", function() {
				it( "can query terms enum with options struct", function() {
					var result = getInstance( "HyperClient@cbelasticsearch" )
						.getTermsEnum( [ variables.testIndexName ], {
							"field" : "title",
							"size" : 50
						} );
						expect( result ).toBeStruct()
										.toHaveKey( "terms" )
										.toHaveKey( "_shards" );
				});
				it( "can query terms enum with simple arguments", function() {
					var result = getInstance( "HyperClient@cbelasticsearch" )
						.getTermsEnum(
							indexName  = variables.testIndexName,
							field = "title",
							match = "doc",
							size = 50,
							caseInsensitive = false
						);
						expect( result ).toBeStruct()
										.toHaveKey( "terms" )
										.toHaveKey( "_shards" );
				});
			});
		} );
	}

}
