component extends="coldbox.system.testing.BaseTestCase"{
	
	function beforeAll(){

		this.loadColdbox = true;

		setup();

		var props = {
			"index" : "logboxappendertests",
			"type" : "_doc"
		};

		variables.model = getMockBox().createMock(className="root.modules.cbelasticsearch.models.logging.ElasticsearchAppender");
		makePublic( variables.model, "getRotationalIndexName", "getRotationalIndexName" );

		variables.model.init( "LogAppenderTest", props );

		variables.loge = getMockBox().createMock(className="coldbox.system.logging.LogEvent");

		variables.loge.init("Unit Test Sample",3,structnew(),"UnitTest");
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

				sleep( 1000 );

				var documents = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new( variables.model.getRotationalIndexName() ).setQuery( { "match_all" : {} }).execute().getHits();

				expect( documents.len() ).toBeGT( 0 );

				var logMessage = documents[ 1 ].getMemento();

				debug( logMessage  );
			});

			it( "Tests automatic log rotation", function(){
				var documents = getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new( variables.model.getRotationalIndexName() ).setQuery( { "match_all" : {} }).execute().getHits();
				var formatter = createObject( "java", "java.text.SimpleDateFormat" ).init( "yyyy-MM-dd'T'HH:mm:ssXXX" );
				
				documents.each( function( doc ){
					doc.getMemento()["timestamp"] = formatter.format( dateAdd( "d", -50, now() ) ).replace("Z", "+00:00");
					doc.save();
				} );

				sleep( 1100 );

				variables.model.setLastDBRotation( dateAdd( "n", -20, now() ) );

				variables.model.logMessage( variables.loge );

				sleep( 1100 );

				expect( getWirebox().getInstance( "SearchBuilder@cbElasticsearch" ).new( variables.model.getRotationalIndexName() ).setQuery( { "match_all" : {} }).count() ).toBe( 1 );

			} );

		});
	}

}