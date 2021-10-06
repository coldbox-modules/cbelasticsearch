component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

		setup();

		variables.model = getMockBox().createMock( className = "cbelasticsearch.models.logging.LogstashAppender" );

		variables.model.init(
			"LogstashAppenderTest",
			{
				"applicationName" : "testspecs",
				"releaseVersion"  : "1.0.0",
				"userInfoUDF"     : function(){
					return { "username" : "tester" };
				}
			}
		);

		makePublic(
			variables.model,
			"getRotationalIndexName",
			"getRotationalIndexName"
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
		variables.model.getClient().deleteIndex( variables.model.getRotationalIndexName() );

		super.afterAll();
	}

	function run(){
		describe( "Test Elasticsearch logging appender functionality", function(){
			it( "Test that the logging appender index exists", function(){
				variables.model.onRegistration();

				expect( variables.model.getClient().indexExists( variables.model.getRotationalIndexName() ) ).toBeTrue();
			} );

			it( "Tests logMessage()", function(){
				variables.model.logMessage( variables.loge );
				sleep( 5000 );

				var documents = getWirebox()
					.getInstance( "SearchBuilder@cbElasticsearch" )
					.new( variables.model.getRotationalIndexName() )
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
					structDelete( e, "tagContext" );
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
					.new( variables.model.getRotationalIndexName() )
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
