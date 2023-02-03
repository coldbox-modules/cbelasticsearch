component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

		super.beforeAll();

		variables.model = getMockBox().createMock( className = "cbelasticsearch.models.logging.LogstashAppender" );

		variables.model.init(
			"LogstashAppenderTest",
			{
				 "applicationName"       : "testspecs",
				 "dataStream"            : "testing-data-stream",
				 "dataStreamPattern"     : "testing-data-stream",
				 "componentTemplateName" : "testing-data-mappings",
				 "indexTemplateName"     : "logstash-appender-testing",
				 "ILMPolicyName"         : "logstash-appender-test-policy",
				 "releaseVersion"        : "1.0.0",
				 "userInfoUDF"           : function(){
												return { "username" : "tester" };
										   }
			}
		);

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
		describe( "Test Elasticsearch logging appender functionality", function(){
			it( "Test that the logging appender data stream exists", function(){
				variables.model.onRegistration();
				expect( variables.model.getClient().dataStreamExists( variables.model.getProperty( "dataStream" ) ) ).toBeTrue();
			} );

			it( "Tests logMessage()", function(){
				variables.model.logMessage( variables.loge );
				sleep( 5000 );

				var documents = getWirebox()
					.getInstance( "SearchBuilder@cbElasticsearch" )
					.new( variables.model.getProperty( "dataStream" ) )
					.setQuery( { "match_all" : {} } )
					.execute()
					.getHits();

				expect( documents.len() ).toBeGT( 0 );

				var logMessage = documents[ 1 ].getMemento();

				expect( logMessage )
					.toHaveKey( "application" )
					.toHaveKey( "release" )
					.toHaveKey( "userinfo" );


				expect( isJSON( logMessage.userInfo ) ).toBeTrue();
				expect( deserializeJSON( logMessage.userinfo ) ).toHaveKey( "username" );

				debug( logMessage );
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
					.getInstance( "SearchBuilder@cbElasticsearch" )
					.new( variables.model.getProperty( "dataStream" ) )
					.setQuery( { "match_all" : {} } )
					.execute()
					.getHits();

				expect( documents.len() ).toBeGT( 0 );

				var logMessage = documents[ 1 ].getMemento();

				expect( logMessage )
					.toHaveKey( "application" )
					.toHaveKey( "release" )
					.toHaveKey( "userinfo" );


				expect( isJSON( logMessage.userInfo ) ).toBeTrue();
				expect( deserializeJSON( logMessage.userinfo ) ).toHaveKey( "username" );

				debug( logMessage );
			} );
		} );
	}

}
