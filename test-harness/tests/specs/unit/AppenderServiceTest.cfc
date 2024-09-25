component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

		super.beforeAll();
        variables.esClient = getWirebox().getInstance( "Client@cbelasticsearch" );
		variables.model = getMockBox().createMock( className = "cbelasticsearch.models.logging.AppenderService" );
        variables.model.init();
		getWirebox().autowire( variables.model );

        var mockDataArgs = {
            "$num" : 10,
            "log.level"    : "oneof:info:warn:error",
            "message" : "sentence"
        };

        variables.testEntries = mockData( argumentCollection = mockDataArgs );
		
	}

	function afterAll(){
        var detachedAppenders = variables.model.getDetachedAppenders();
        
        detachedAppenders.each( function( appenderName ){
            var appender = variables.model.getAppender( appenderName );
            if( !isNull( appender ) ){
                if( esClient.dataStreamExists( appender.getProperty( "dataStream" ) ) ){
                    esClient.deleteDataStream( appender.getProperty( "dataStream" ) );
                }
                if( esClient.indexTemplateExists( appender.getProperty( "indexTemplateName" ) ) ){
                    esClient.deleteIndexTemplate( appender.getProperty( "indexTemplateName" ) );
                }
        
                if( esClient.componentTemplateExists( appender.getProperty( "componentTemplateName" ) ) ){
                    esClient.deleteComponentTemplate( appender.getProperty( "componentTemplateName" ) );
                }
        
                if( esClient.ILMPolicyExists( appender.getProperty( "ILMPolicyName" ) ) ){
                    esClient.deleteILMPolicy( appender.getProperty( "ILMPolicyName" ) );
                }
            }
        } );

		super.afterAll();
	}

	function run(){
		describe( "Tests detached appenders", function(){
			it( "Tests the ability to create a detached appender", function(){
                var appenderName = "detachedAppenderTest";
				variables.model.createDetachedAppender( 
                    appenderName,
                    {
                        // The data stream name to use for this appenders logs
                        "dataStreamPattern"     : "logs-coldbox-#lcase( appenderName )#*",
                        "dataStream"            : "logs-coldbox-#lcase( appenderName )#",
                        "ILMPolicyName"         : "cbelasticsearch-logs-#lcase( appenderName )#",
                        "indexTemplateName"     : "cbelasticsearch-logs-#lcase( appenderName )#",
                        "componentTemplateName" : "cbelasticsearch-logs-#lcase( appenderName )#",
                        "pipelineName"          : "cbelasticsearch-logs-#lcase( appenderName )#",
                        "indexTemplatePriority" : 151,
                        "retentionDays"         : 1,
                        // The name of the application which will be transmitted with the log data and used for grouping
                        "applicationName"       : "Detached Test Appender Logs",
                        // The max shard size at which the hot phase will rollover data
                        "rolloverSize"          : "1gb"
                    }
                );
                var createdAppender = variables.model.getAppender( appenderName );
                expect( isNull( createdAppender) ).toBeFalse();

                expect( createdAppender.getProperty( "dataStream" ) ).toBe( "logs-coldbox-#lcase( appenderName )#" );

			} );

            describe( "Perform actions on detached appender", function(){
                var appenderName = "detachedAppenderTest";
                beforeEach( function(){
                    var appender = variables.model.getAppender( appenderName );
                    if( isNull( appender ) ){
                        variables.model.createDetachedAppender( 
                            appenderName,
                            {
                                // The data stream name to use for this appenders logs
                                "dataStreamPattern"     : "logs-coldbox-#lcase( appenderName )#*",
                                "dataStream"            : "logs-coldbox-#lcase( appenderName )#",
                                "ILMPolicyName"         : "cbelasticsearch-logs-#lcase( appenderName )#",
                                "indexTemplateName"     : "cbelasticsearch-logs-#lcase( appenderName )#",
                                "componentTemplateName" : "cbelasticsearch-logs-#lcase( appenderName )#",
                                "pipelineName"          : "cbelasticsearch-logs-#lcase( appenderName )#",
                                "indexTemplatePriority" : 151,
                                "retentionDays"         : 1,
                                // The name of the application which will be transmitted with the log data and used for grouping
                                "applicationName"       : "Detached Test Appender Logs",
                                // The max shard size at which the hot phase will rollover data
                                "rolloverSize"          : "1gb"
                            }
                        );
                    }
                });

                it( "Tests the ability to log a single message to the appender", function(){
                    var appender = variables.model.getAppender( appenderName );
                    var dataStreamCount = getDataStreamCount( appender.getProperty( "dataStreamPattern" ) );
                    variables.model.logToAppender(
                        appenderName,
                        "Test message",
                        4
                    );
                    sleep( 1000 );
                    expect( getDataStreamCount( appender.getProperty( "dataStreamPattern" ) ) ).toBe( dataStreamCount + 1 );
                } );

                it( "Tests the ability to log a single raw message to the appender", function(){
                    var appender = variables.model.getAppender( appenderName );
                    var dataStreamCount = getDataStreamCount( appender.getProperty( "dataStreamPattern" ) );
                    variables.model.logRawToAppender( 
                        appenderName,
                        variables.testEntries.first(),
                        true
                    );
                    expect( getDataStreamCount( appender.getProperty( "dataStreamPattern" ) ) ).toBe( dataStreamCount + 1 );
                } );



                it( "Tests the ability to log a multiple raw message to the appender", function(){
                    var appender = variables.model.getAppender( appenderName );
                    var dataStreamCount = getDataStreamCount( appender.getProperty( "dataStreamPattern" ) );
                    variables.model.logRawToAppender( 
                        appenderName,
                        variables.testEntries,
                        true
                    );
                    expect( getDataStreamCount( appender.getProperty( "dataStreamPattern" ) ) ).toBe( dataStreamCount + variables.testEntries.len() );
                } );


            } );
		} );
	}

    function getDataStreamCount( required string dataStreamPattern ){
        return getWirebox().getInstance( "SearchBuilder@cbelasticsearch" ).setIndex( dataStreamPattern ).setQuery( { "match_all" : {} } ).count();
    }

}
