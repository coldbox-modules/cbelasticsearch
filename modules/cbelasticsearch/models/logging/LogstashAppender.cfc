/**
* Elasticsearch appender for LogBox
**/
component extends="coldbox.system.logging.AbstractAppender" output="false" hint="This a logstash appender for Elasticsearch" {
    
    property name="util" inject="Util@cbelasticsearch";

    /**
     * Constructor
     */
    public LogstashAppender function init(
        required name, 
        properties={}, 
        layout="", 
        levelMin="0", 
        levelMax="4"
    ) output=false {
        
        if( !structKeyExists( application, "wirebox" ) ){
            throw( 
                type="cbElasticsearch.Elasticsearch.DependencyException",
                message="Wirebox was not detected in the application scope, but is required to use this appender"
            );
        }

        // Init supertype
        super.init( argumentCollection=arguments );
        
        // UUID generator
        instance.uuid = createobject( "java", "java.util.UUID" );

        var applicationName = properties.keyExists( "applicationName" )
                                ? properties.applicationName
                                : ( server.coldfusion.productname eq "Lucee" ? getApplicationSettings().name : getApplicationMetadata().name );

        instance.DEFAULTS = {
            "index"            : ".logstash-" & ( arguments.properties.keyExists( "index" ) ? lcase( properties.index ) : lcase( REReplaceNoCase(applicationName, "[^0-9A-Z_]", "_", "all") ) ),
            "rotate"           : true,
            "rotation"         : "daily",
            "ensureChecks"     : true,
            "autoCreate"       : true,
            "applicationName"  : applicationName,
            "releaseVersion"   : ""
        };

        for( var configKey in structKeyArray( instance.Defaults ) ){
            if( !propertyExists( configKey ) ){
                setProperty( configKey, instance.DEFAULTS[ configKey ] );
            }
        }

        if( !propertyExists( 'defaultCategory' ) ){
            setProperty( "defaultCategory", arguments.name);
        }

        application.wirebox.autowire( this );
        
        return this;
    }

    /**
    * Document provider
    **/
    Client function newDocument() provider="Document@cbElasticsearch"{}

    /**
    * Index Builder Provider
    **/
    Client function indexBuilder() provider="IndexBuilder@cbElasticsearch"{}

    /**
    * Client provider
    **/
    Client function getClient() provider="Client@cbElasticsearch"{}


    /**
     * Runs on registration
     */
    public void function onRegistration() output=false {

        if( getProperty( "ensureChecks" ) ){
                // Index Checks
                ensureIndex();
        }
    }
    //  Log Message 

    /**
     * Write an entry into the appender.
     */
    public void function logMessage(required any logEvent) output=false {
        //  ************************************************************* 
        //  ************************************************************* 
            var category 	= getProperty( "defaultCategory" );
            var cmap 		= "";
            var cols 		= "";
            var loge 		= arguments.logEvent;
            var message 	= loge.getMessage();

            var logObj = {
                "application"  : getProperty( "applicationName" ),
                "release"      : javacast( "string", getProperty( "releaseVersion" ) ),
                "type"         : "server",
                "level"        : severityToString( loge.getSeverity() ),
                "severity"     : loge.getSeverity(),
                "category"     : category,
                "timestamp"    : dateTimeFormat( loge.getTimestamp(), "yyyy-mm-dd'T'hh:nn:ssZZ" ),
                "appendername" : getName(),
                "component"    : "test",
                "message"      : loge.getMessage(),
                "stacktrace"   : isSimpleValue( loge.getExtraInfo() ) ? listToArray( loge.getExtraInfo(), "#chr(13)##chr(10)#" ) : javacast( "null", 0 ),
                "extrainfo"    : !isSimplevalue( loge.getExtraInfo() ) ? loge.getExtraInfoAsString() : javacast( "null", 0 )
            };

            if( logObj.severity < 2 ){
                
                logObj[ "snapshot" ] = {
                    "template"       : CGI.CF_TEMPLATE_PATH,
                    "path"           : CGI.PATH_INFO,
                    "host"           : CGI.HTTP_HOST,
                    "referer"        : CGI.HTTP_REFERER,
                    "browser"        : CGI.HTTP_USER_AGENT,
                    "remote_address" : CGI.REMOTE_ADDR
                };

                if( structKeyExists( application, "cbController" ) ){
                    var event = application.cbController.getRequestService().getContext();
                    logObj[ "event" ] = {
                        "name"		  : (event.getCurrentEvent() != "") ? event.getCurrentEvent() :"N/A",
                        "route"		  : (event.getCurrentRoute() != "") ? event.getCurrentRoute() & ( event.getCurrentRoutedModule() != "" ? " from the " & event.getCurrentRoutedModule() & "module router." : ""):"N/A",
                        "routed_url"  : (event.getCurrentRoutedURL() != "") ? event.getCurrentRoutedURL() :"N/A",
                        "layout"	  : (event.getCurrentLayout() != "") ? event.getCurrentLayout() :"N/A",
                        "module"	  : event.getCurrentLayoutModule(),
                        "view"		  : event.getCurrentView(),
                        "environment" : application.cbController.getSetting( "environment" )
                    };
    
                }

            }
            if( propertyExists( "userInfoUDF" ) ){
                var udf = getProperty( "userInfoUDF" );

                if( isClosure( udf ) ){
                    try{
                        logObj[ "userinfo" ] = udf();
                        if( !isSimpleValue( logObj.userinfo ) ){
                            logObj.userinfo = variables.util.toJSON( logObj.userinfo );
                        }
                    } catch( any e ){
                       logObj[ "userinfo" ] = "An error occurred when attempting to run the userInfoUDF provided.  The message received was #e.message#";     
                    }
                } 
            }

            newDocument().new( 
                index=getRotationalIndexName(),
                properties=logObj
            ).setId( instance.uuid.randomUUID() )
            .save();
    }

    // ---------------------------------------- PRIVATE ---------------------------------------
    
    /**
     * Verify or create the logging index
     */
    private void function ensureIndex() output=false {
        indexBuilder().new( 
            name=getRotationalIndexName(),
            properties={
                "mappings":{
                    "#getProperty( "type" )#":{
                        "_all"       : { "enabled": false },
                        "properties" : {
                            "type"        : { "type" : "keyword" },
                            "application" : { "type" : "keyword" },
                            "release"     : { "type" : "keyword" },
                            "level"       : { "type" : "keyword" },
                            "category"    : { "type" : "keyword" },
                            "appendername": { "type" : "keyword" },
                            "timestamp"	  : {
                                "type"  : "date",
                                "format": "date_time_no_millis"
                            },
                            "message"     : { 
                                "type" : "text",
                                "fields": {
                                    "keyword": {
                                        "type": "keyword",
                                        "ignore_above": 256
                                    }
                                } 
                            },
                            "extrainfo"   : { "type" : "text" },
                            "stacktrace"  : { "type" : "text" },
                            "snapshot"    : { 
                                "type" : "object",
                                "properties" : {
                                    "template"       : { "type" : "keyword" },
                                    "path"           : { "type" : "keyword" },
                                    "host"           : { "type" : "keyword" },
                                    "referrer"       : { "type" : "keyword" },
                                    "browser"        : { "type" : "keyword" },
                                    "remote_address" : { "type" : "keyword" } 
                                } 
                            },
                            "event" : {
                                "type" : "object", 
                                "properties" : {
                                    "name"         : { "type" : "keyword" },
                                    "route"        : { "type" : "keyword" },
                                    "routed_url"   : { "type" : "keyword" },
                                    "layout"       : { "type" : "keyword" },
                                    "module"       : { "type" : "keyword" },
                                    "view"         : { "type" : "keyword" },
                                    "environment"  : { "type" : "keyword" } 
                                }
                            },
                            "userinfo" : { "enabled" : false }
                        }
                    }
                }
            } 
        ).save();

    }

    private function getRotationalIndexName(){
        var baseName = getProperty( "index" );

        if( getProperty( "rotate" ) ){
            switch( getProperty( "rotation" ) ){
                case "monthly" : {
                    baseName &= '.' & dateFormat( now(), 'yyyy-mm' );
                    break;
                }
                case "weekly" : {
                    baseName &= '.' & dateFormat( now(), 'yyyy-w' );
                    break;
                }
                case "daily" : {
                    baseName &= '.' & dateFormat( now(), 'yyyy-mm-dd' );
                    break;
                }
                case "hourly" : {
                    baseName &= '.' & dateFormat( now(), 'yyyy-mm-dd-H' );
                    break;
                }
            }	
        }
        return baseName;
    }

    

}