component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

		super.beforeAll();

		variables.model = getMockBox().createMock( className = "cbelasticsearch.models.logging.LogstashAppender" );

		variables.model.init(
			"LogstashAppenderTest",
			{
				 "applicationName"       : "testspecs",
				 "dataStream"            : "logs-testing-data-stream",
				 "dataStreamPattern"     : "logs-testing-data-stream*",
				 "componentTemplateName" : "testing-data-mappings",
				 "indexTemplateName"     : "logstash-appender-testing",
				 "ILMPolicyName"         : "logstash-appender-test-policy",
				 "releaseVersion"        : "1.0.0",
				 "userInfoUDF"           : function(){
												return { 
													"name" : "tester", 
													"full_name" : "Test Testerson", 
													"username" : "tester" 
												};
										   }
			}
		);

		variables.model.onRegistration();

		makePublic(
			variables.model,
			"getProperty"
		);

		variables.loge = getMockBox().createMock( className = "coldbox.system.logging.LogEvent" );

		// create an error message
		try {
			var a = b;
		} catch ( any e ) {
			variables.loge.init(
				message   = len( e.detail ) ? e.detail : e.message,
				severity  = 0,
				extraInfo = e,
				category  = e.type
			);
		}
	}

	function afterAll(){
		var esClient = variables.model.getClient();
		if( esClient.dataStreamExists( variables.model.getProperty( "dataStream" ) ) ){
			esClient.deleteDataStream( variables.model.getProperty( "dataStream" ) );
		}

		if( esClient.indexTemplateExists( variables.model.getProperty( "indexTemplateName" ) ) ){
			esClient.deleteIndexTemplate( variables.model.getProperty( "indexTemplateName" ) );
		}

		if( esClient.componentTemplateExists( variables.model.getProperty( "componentTemplateName" ) ) ){
			esClient.deleteComponentTemplate( variables.model.getProperty( "componentTemplateName" ) );
		}

		if( esClient.ILMPolicyExists( variables.model.getProperty( "ILMPolicyName" ) ) ){
			esClient.deleteILMPolicy( variables.model.getProperty( "ILMPolicyName" ) );
		}

		super.afterAll();
	}

	function run(){
		describe( "Tests the data stream configuration", function(){
			it( "Tests that all data stream objects are in place", function(){
				var esClient = variables.model.getClient();
				expect( esClient.dataStreamExists( variables.model.getProperty( "dataStream" ) ) ).toBeTrue();
				expect( esClient.indexTemplateExists( variables.model.getProperty( "indexTemplateName" ) ) ).toBeTrue();
				expect( esClient.componentTemplateExists( variables.model.getProperty( "componentTemplateName" ) ) ).toBeTrue();
				expect( esClient.ILMPolicyExists( variables.model.getProperty( "ILMPolicyName" ) ) ).toBeTrue();
				expect( isNull( variables.model.getClient().getPipeline( variables.model.getProperty( "pipelineName" ) ) ) ).toBeFalse();
			} );
		} );
		describe( "Test Elasticsearch logging appender functionality", function(){
			it( "Test that the logging appender data stream exists", function(){
				variables.model.onRegistration();
				expect( variables.model.getClient().dataStreamExists( variables.model.getProperty( "dataStream" ) ) ).toBeTrue();
			} );

			it( "Tests logMessage()", function(){
				variables.model.logMessage( variables.loge );
				sleep( 5000 );

				var documents = getWirebox()
					.getInstance( "SearchBuilder@cbelasticsearch" )
					.new( variables.model.getProperty( "dataStream" ) )
					.setQuery( { "match_all" : {} } )
					.execute()
					.getHits();

				expect( documents.len() ).toBeGT( 0 );

				var logMessage = documents[ 1 ].getMemento();

				expect( logMessage )
					.toHaveKey( "@timestamp" )
					.toHaveKey( "log" )
					.toHaveKey( "event" )
					.toHaveKey( "file" )
					.toHaveKey( "url" )
					.toHaveKey( "http" )
					.toHaveKey( "labels" )
					.toHaveKey( "package" )
					.toHaveKey( "host" )
					.toHaveKey( "client" )
					.toHaveKey( "user" )
					.toHaveKey( "user_agent" )
					.toHaveKey( "stachebox" );
				
				expect( logMessage.stachebox ).toHaveKey( "signature" );

				expect( logMessage.user )
					.toHaveKey( "info" )
					.toHaveKey( "full_name" );


				expect( isJSON( logMessage.user.info ) ).toBeTrue();
				expect( deserializeJSON( logMessage.user.info ) ).toHaveKey( "username" );

			} );

			it( "Tests the component path filter template", function(){
				testLoge = getMockBox().createMock( className = "coldbox.system.logging.LogEvent" );

				testLoge.init(
					message   = "Many.Dots.In.Snuffalupagus.Log",
					severity  = 4,
					extraInfo = {
						"friend" : "Big Bird",
						"program" : "Sesame Street"
					},
					category  = "SesameLogs"
				);

				variables.model.logMessage( testLoge );
				sleep( 5000 );

				var documents = getWirebox()
					.getInstance( "SearchBuilder@cbelasticsearch" )
					.new( variables.model.getProperty( "dataStreamPattern" ) )
					.setQuery( { 
						"bool" : {
							"must" : [
								{ "match" : { "message" : "Snuffalupagus" } }
							]
						}
					 } )
					.execute()
					.getHits();

				expect( documents.len() ).toBeGT( 0 );

				debug( documents.first().getDocument() );

			} );

			it( "Tests logMessage() with java stack trace", function(){
				// create an error message
				try {
					var a = b;
				} catch ( any e ) {
					e.tagContext = [];
					var otherLog = variables.loge.init(
						message   = len( e.detail ) ? e.detail : e.message,
						severity  = 0,
						extraInfo = e,
						category  = e.type
					);
				}
				variables.model.logMessage( otherLog );
				sleep( 5000 );

				var documents = getWirebox()
					.getInstance( "SearchBuilder@cbelasticsearch" )
					.new( variables.model.getProperty( "dataStream" ) )
					.setQuery( { "match_all" : {} } )
					.execute()
					.getHits();

				expect( documents.len() ).toBeGT( 0 );

				var logMessage = documents[ 1 ].getMemento();

				expect( logMessage )
					.toHaveKey( "@timestamp" )
					.toHaveKey( "log" )
					.toHaveKey( "event" )
					.toHaveKey( "file" )
					.toHaveKey( "url" )
					.toHaveKey( "http" )
					.toHaveKey( "labels" )
					.toHaveKey( "package" )
					.toHaveKey( "host" )
					.toHaveKey( "client" )
					.toHaveKey( "user" )
					.toHaveKey( "user_agent" )
					.toHaveKey( "error" )
					.toHaveKey( "stachebox" );
				
				expect( logMessage.stachebox ).toHaveKey( "signature" );

				expect( logMessage.user )
					.toHaveKey( "info" )
					.toHaveKey( "full_name" );

				expect( logMessage.error )
					.toHaveKey( "stack_trace" )
					.toHaveKey( "level" )
					.toHaveKey( "message" )
					.toHaveKey( "type" );


				expect( isJSON( logMessage.user.info ) ).toBeTrue();
				expect( deserializeJSON( logMessage.user.info ) ).toHaveKey( "username" );

			} );

			it( "Can convert a v2 document to a v3 document via the ingest pipeline", function(){
				var v2Error = deserializeJSON( fileRead( expandPath( "/tests/resources/data/v2error.json" ) ) );
				expect( isNull( variables.model.getClient().getPipeline( variables.model.getProperty( "pipelineName" ) ) ) ).toBeFalse();
				var doc = variables.model.newDocument().new(
					index = variables.model.getProperty( "dataStream" ),
					properties = v2Error
				).create( true );

				expect( doc.getMemento() )
					.toHaveKey( "@timestamp" )
					.toHaveKey( "log" )
					.toHaveKey( "event" )
					.toHaveKey( "file" )
					.toHaveKey( "url" )
					.toHaveKey( "http" )
					.toHaveKey( "labels" )
					.toHaveKey( "package" )
					.toHaveKey( "host" )
					.toHaveKey( "client" )
					.toHaveKey( "user" )
					.toHaveKey( "user_agent" )
					.toHaveKey( "error" );

			} );
		} );
	}

}
