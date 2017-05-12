/**
* Coldbox Cache Provider Tests
**/
component extends="CacheProviderTest"{
	
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
		}

		// Create Provider
		// Find a way to make the "RedisApp" mapping dynamic for people (like Brad) running this in the root :)
		cache = getMockBox().createMock("root.modules.elasticsearch.models.cache.ColdboxProvider").init();

		getWirebox().autowire( cache );

		cache.setConfiguration( config );

		cache.setCacheFactory( mockFactory );
		cache.setEventManager( mockEventManager );
		
		// Configure the provider
		cache.configure();
	}
	
}