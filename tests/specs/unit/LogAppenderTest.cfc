component extends="coldbox.system.testing.BaseTestCase"{
	
	function beforeAll(){

		this.loadColdbox = true;

		setup();

		var props = {
			"index" : "logboxappendertests",
			"type" : "_doc"
		};

		variables.model = getMockBox().createMock(className="root.modules.cbelasticsearch.models.logging.ElasticsearchAppender");

		variables.model.init( "LogAppenderTest", props );

		variables.loge = getMockBox().createMock(className="coldbox.system.logging.LogEvent");

		variables.loge.init("Unit Test Sample",0,structnew(),"UnitTest");
	}

	function afterAll(){

		super.afterAll();
		
		variables.model.getClient().deleteIndex( "logboxappendertests" );
		
	}

	function run(){
		
		describe( "Test Elasticsearch logging appender functionality", function(){

			it( "Test that the logging appender index exists", function(){

				variables.model.onRegistration();

				expect( variables.model.getClient().indexExists( variables.model.getProperty( "index" ) ) ).toBeTrue();
			
			});

			it( "Tests logMessage()", function(){

				variables.model.logMessage( variables.loge );
			
			});

		});
	}

}