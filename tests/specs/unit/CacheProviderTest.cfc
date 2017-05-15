/**
* Cache Provider Tests
**/
component extends="coldbox.system.testing.BaseTestCase"{

	function beforeAll(){
		this.loadColdbox = true;
		
		setup();

		//Mocks
		mockFactory      = getMockBox().createEmptyMock( className='coldbox.system.cache.CacheFactory' );
		mockEventManager = getMockBox().createEmptyMock( className='coldbox.system.core.events.EventPoolManager' );
		mockLogBox       = getMockBox().createEmptyMock( "coldbox.system.logging.LogBox" );
		mockLogger       = getMockBox().createEmptyMock( "coldbox.system.logging.Logger" );	
		// Mock Methods
		mockFactory.$( "getLogBox", mockLogBox );
		mockLogBox.$( "getLogger", mockLogger );
		mockLogger.$( "error" ).$( "debug" ).$( "info" ).$( "canDebug", true ).$( "canInfo", true ).$( "canError", true );
		mockEventManager.$( "processState" );

		var config = {
			maxConnections               = 10
			,defaultTimeoutUnit          = "MINUTES"
			,objectDefaultTimeout        = 30
			,opQueueMaxBlockTime         = 5000
			,opTimeout                   = 5000
			,timeoutExceptionThreshold   = 5000
			,ignoreElasticsearchTimeouts = true
			,index                       = "escache-cacheprovidertests"
			,server                      = "localhost:9200" // This can be an array
			,password                    = ""
			,caseSensitiveKeys           : true
			,updateStats                 : true
			,dbIndex                     = 0
		};

		// Create Provider
		variables.cache = getMockBox().createMock("root.modules.cbelasticsearch.models.Cache.Provider").init();

		getWirebox().autowire( cache );

		// Decorate it
		cache.setConfiguration( config );

		cache.setCacheFactory( mockFactory );
		cache.setEventManager( mockEventManager );
		
		// Configure the provider
		cache.configure();
		cache.clearAll();


		super.beforeAll();
	}

	function afterAll(){
		super.afterAll();
	}
	

	function run(){
		
		describe( "Performs ElasticSearch cache provider tests", function(){

			it( "Tests shutdown", function(){
				//cache.shutdown();
			});

			it( "Tests lookup()", function(){

				expect( cache.lookup( 'invalid' ) ).toBeFalse();

				cache.set( 'valid', "Totally valid!" );

				sleep( 1000 );

				expect( cache.lookup( 'valid' ) ).toBeTrue();

				cache.clear( 'valid' );

			});

			it( "Tests lookupQuiet()", function(){
				//implemented by lookup()
			});

			it( "Tests get()", function(){
				// null value
				var r = cache.get( 'invalid' );

				expect( isNull( r ) ).toBeTrue();
					
				var testVal = {name="luis", age=32};
				
				cache.set( "unittestkey", testVal );
				
				sleep( 2000 );	
				
				var results = cache.get( 'unittestkey' );

				expect( isNull( results ) ).toBeFalse();

				expect( results ).toBe( testVal );

			});

			it( "Tests getQuiet()", function(){
				//implemented through get() tests
			});

			it( "Tests set()", function(){
				// test our case senstivity setting
				var testVal = {name="luis", age=32};
				cache.set( 'unitTestKey', testVal );
				
				var results = cache.get( "unittestkey" );
				
				expect( !isNull( results ) ).toBeTrue();
				expect( results ).toBeStruct();
				expect( results ).toHaveKey( "name" );
				expect( results.name ).toBe( "luis" );

				cache.set( 'anotherKey', 'Hello Elasticsearch!');
				var results = cache.get( "anotherKey" );

				expect( isNull( results ) ).toBeFalse();
				expect( results ).toBe( "Hello Elasticsearch!" );

			});

			it( "Tests setQuiet()", function(){
				//implemented through set() tests
			});

			it( "Tests expireObject()", function(){
				// test not valid object
				cache.expireObject( "invalid" );

				// test real object
				
				cache.set( "unitTestKey", 'Testing' );
				cache.expireObject( "unitTestKey" );
				
				sleep( 2 );
				
				results = cache.get( 'unitTestKey' );
				
				assertTrue( isNull( results ) );
			});

			it( "Tests setMulti()", function(){

				var multi = {};

				for( var i=1; i <= 10; i++  ){

					multi[ createUUID() ] = "Testing #i#";
				
				}

				cache.setMulti( multi );

				for( var key in multi  ){
					expect( cache.lookup( key ) ).toBeTrue();
				}

				variables.multipleRecords = structKeyArray( multi );

			});

			it( "Tests getMulti()", function(){

				expect( variables ).toHaveKey( "multipleRecords" );

				var multiGet = cache.getMulti( variables.multipleRecords );

				expect( arrayLen( structKeyArray( multiGet ) ) ).toBe( arrayLen( variables.multipleRecords ) );

			});

			it( "Tests expireAll()", function(){

				expect( variables ).toHaveKey( "multipleRecords" );

				cache.expireAll();

				sleep( 1000 );

				expect( structIsEmpty( cache.getMulti( variables.multipleRecords ) ) ).toBeTrue();

			});

			it( "Tests clear()", function(){

				cache.set( "unitTestKey", 'Testing' );

				cache.clear( "unitTestKey" );

				expect( cache.lookup( "unitTestKey" ) ).toBeFalse();

			});

			it( "Tests clearQuiet()", function(){
				//implemented by clear()
			});

			it( "Tests reap()", function(){
				cache.reap();
			});

			it( "Tests getCachedObjectMetadata()", function(){
				
				cache.set( "unittestkey", 'Test Data' );
				
				var r = cache.getCachedObjectMetadata( 'unittestkey' );

				expect( r.isExpired ).toBeFalse();

			});

		});

	}
	
}