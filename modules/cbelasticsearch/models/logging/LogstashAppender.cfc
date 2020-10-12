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

        instance.appRoot = normalizeSlashes( expandPath('/') );

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

        var loge = arguments.logEvent;
        var extraInfo = loge.getExtraInfo();
		var level = lcase( severityToString( loge.getSeverity() ) );
		var message = loge.getMessage();
        var loggerCat = loge.getCategory();

        // Is this an exception or not?
        if( 
            ( isStruct( extraInfo ) || isObject( extraInfo ) )
            && extraInfo.keyExists( "StackTrace" ) && extraInfo.keyExists( "Message" ) && extraInfo.keyExists( "Detail" ) 
        ){
            
            local.logObj = parseException(
                exception = extraInfo,
                level 	= level,
                message = message,
                logger = loggerCat
            );
                
        } else if( 
            ( isStruct( extraInfo ) || isObject( extraInfo ) )
            && extraInfo.keyExists( "exception" ) && isStruct( extraInfo.exception ) && extraInfo.exception.keyExists( "StackTrace" ) 
        ){    
            var trimmedExtra = structCopy( extraInfo );
            trimmedExtra.delete( 'exception' );
            
            local.logObj = parseException(
                exception = extraInfo.exception,
                level 	= level,
                message = message,
                logger = loggerCat,
                additionalData = trimmedExtra
            );
                
        } else {
                        
            local.logObj = {
                "application"  : getProperty( "applicationName" ),
                "release"      : javacast( "string", getProperty( "releaseVersion" ) ),
                "type"         : "message",
                "level"        : level,
                "severity"     : loge.getSeverity(),
                "category"     : loggerCat,
                "message"      : loge.getMessage(),
                "extrainfo"    : loge.getExtraInfoAsString()
            };
                
        }

        logObj[ "timestamp" ] = dateTimeFormat( loge.getTimestamp(), "yyyy-mm-dd'T'hh:nn:ssZZ" );
        logObj[ "severity" ] = loge.getSeverity();
        logObj[ "appendername" ] = getName();

        // Logstash/Kibana Convention Keys
        structAppend( 
            logObj, 
            {
                "@timestamp"    : logObj.timestamp,
                "host" : {
                    "name" : CGI.HTTP_HOST,
                    "hostname" : CGI.SERVER_NAME         
                }
            },
            false
        );

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
                    "module"	  : event.getCurrentModule(),
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
        if( getClient().indexExists( getRotationalIndexName() ) ) return;

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
                            "@timestamp"	  : {
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
                            "host" : {
                                "type" : "object",
                                "properties" : {
                                    "name" : { "type" : "keyword" },
                                    "hostnamename" : { "type" : "keyword" }
                                }
                            },
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
                            "userinfo" : { "type" : "text" },
                            "frames"  : { "type" : "text" }
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

    /**
	* @exception The exception
	* @level The level to log
	* @path The path to the script currently executing
	* @additionalData Additional metadata to store with the event - passed into the extra attribute
	* @message Optional message name to output
	* @logger Optional logger to use
	*/
	private struct function parseException(
		required any exception,
		string level = "error",
		string path = "",
		any additionalData,
		string message = '',
		string logger=getName()
	) {


		// Ensure expected keys exist
		arguments.exception.StackTrace = arguments.exception.StackTrace ?: '';
		arguments.exception.type = isSimpleValue( arguments.exception.type ) ? arguments.exception.type : 'error';
		arguments.exception.detail = arguments.exception.detail ?: '';
        arguments.exception.TagContext = arguments.exception.TagContext ?: [];
        
        var logstashException = {
            "application"  : getProperty( "applicationName" ),
            "release"      : javacast( "string", getProperty( "releaseVersion" ) ),
            "type"         : arguments.exception.type,
            "level"        : arguments.level,
            "category"     : logger,
            "component"    : "test",
            "message"      : message & " " & arguments.exception.detail,
            "stacktrace"   : isSimpleValue( arguments.exception.StackTrace ) ? listToArray( arguments.exception.StackTrace, "#chr(13)##chr(10)#" ) : arguments.exception.StackTrace
        };
				
		var logstashexceptionExtra 	= {};
		var file 					= "";
		var fileArray 				= "";
		var currentTemplate 		= "";
		var tagContext 				= arguments.exception.TagContext;
		var i 						= 1;
		var st 						= "";

		// If there's no tag context, include the stack trace instead
		if( !tagContext.len() ) {
			 var showJavaStackTrace = true;
		} else {
            var showJavaStackTrace = false;
        }

		if ( showJavaStackTrace ){
			st = reReplace(arguments.exception.StackTrace, "\r", "", "All");
			if (arguments.removeTabsOnJavaStackTrace)
				st = reReplace(st, "\t", "", "All");
			logstashExceptionExtra["Java StackTrace"] = listToArray( st, "#chr(13)##chr(10)#" );
		}

		// Applies to type = "database". Native error code associated with exception. Database drivers typically provide error codes to diagnose failing database operations. Default value is -1.
		if( structKeyExists( arguments.exception, 'NativeErrorCode' ) ) {
			logstashExceptionExtra[ "DataBase" ][ "NativeErrorCode" ] = arguments.exception.NativeErrorCode;
		}
		
		// Applies to type = "database". SQLState associated with exception. Database drivers typically provide error codes to help diagnose failing database operations. Default value is 1.
		if( structKeyExists( arguments.exception, 'SQLState' ) ) {
			logstashExceptionExtra[ "DataBase" ][ "SQL State" ] = arguments.exception.SQLState;
		}
		
		// Applies to type = "database". The SQL statement sent to the data source.
		if( structKeyExists( arguments.exception, 'Sql' ) ) {
			logstashExceptionExtra[ "DataBase" ][ "SQL" ] = arguments.exception.Sql;
		}
		
		// Applies to type ="database". The error message as reported by the database driver.
		if( structKeyExists( arguments.exception, 'queryError' ) ) {
			logstashExceptionExtra[ "DataBase" ][ "Query Error" ] = arguments.exception.queryError;
		}
		
		// Applies to type= "database". If the query uses the cfqueryparam tag, query parameter name-value pairs.
		if( structKeyExists( arguments.exception, 'where' ) ) {
			logstashExceptionExtra[ "DataBase" ][ "Where" ] = arguments.exception.where;
		}
		
		// Applies to type = "expression". Internal expression error number.
		if( structKeyExists( arguments.exception, 'ErrNumber' ) ) {
			logstashExceptionExtra[ "expression" ][ "Error Number" ] = arguments.exception.ErrNumber;
		}
		
		// Applies to type = "missingInclude". Name of file that could not be included.
		if( structKeyExists( arguments.exception, 'MissingFileName' ) ) {
			logstashExceptionExtra[ "missingInclude" ][ "Missing File Name" ] = arguments.exception.MissingFileName;
		}
		
		// Applies to type = "lock". Name of affected lock (if the lock is unnamed, the value is "anonymous").
		if( structKeyExists( arguments.exception, 'LockName' ) ) {
			logstashExceptionExtra[ "lock" ][ "Lock Name" ] = arguments.exception.LockName;
		}
		
		// Applies to type = "lock". Operation that failed (Timeout, Create Mutex, or Unknown).
		if( structKeyExists( arguments.exception, 'LockOperation' ) ) {
			logstashExceptionExtra[ "lock" ][ "Lock Operation" ] = arguments.exception.LockOperation;
		}
		
		// Applies to type = "custom". String error code.
		if( structKeyExists( arguments.exception, 'ErrorCode' ) && len( arguments.exception.ErrorCode ) && arguments.exception.ErrorCode != '0' ) {
			logstashExceptionExtra[ "custom" ][ "Error Code" ] = arguments.exception.ErrorCode;
		}
		
		// Applies to type = "application" and "custom". Custom error message; information that the default exception handler does not display.
		if( structKeyExists( arguments.exception, 'ExtendedInfo' ) && len( arguments.exception.ExtendedInfo ) ) {
			logstashExceptionExtra[ "application" ][ "Extended Info" ] = arguments.exception.ExtendedInfo;
		}
		
		if ( structCount( logstashExceptionExtra ) )
			logstashException[ "extrainfo" ] = variables.util.toJSON( logstashExceptionExtra );

		
		var frames = [];
		for (i=arrayLen(tagContext); i > 0; i--) {
			var thisTCItem = tagContext[i];
			if (compareNoCase(thisTCItem["TEMPLATE"],currentTemplate)) {
				fileArray = [];
				if (fileExists(thisTCItem["TEMPLATE"])) {
					file = fileOpen(thisTCItem["TEMPLATE"], "read");
					while (!fileIsEOF(file)) {
						arrayAppend(fileArray, fileReadLine(file));
					}
					fileClose(file);
				}
				currentTemplate = thisTCItem["TEMPLATE"];
			}

			var thisStackItem = {
				"abs_path" 	= thisTCItem["TEMPLATE"],
				"filename" 	= normalizeSlashes( thisTCItem["TEMPLATE"] ).replace( instance.appRoot, ""),
				"lineno" 	= thisTCItem["LINE"],
				"pre_context" = [],
				"context_line" = '',
				"post_context" = []
			};

			// for source code rendering
			var fileLen = arrayLen( fileArray );
			var errorLine = thisTCItem[ "LINE" ];

			if (errorLine-3 >= 1 && errorLine-3 <= fileLen ) {
				thisStackItem.pre_context[1] = fileArray[errorLine-3];
			}
			if (errorLine-2 >= 1 && errorLine-2 <= fileLen) {
				thisStackItem.pre_context[1] = fileArray[errorLine-2];
			}
			if (errorLine-1 >= 1 && errorLine-1 <= fileLen) {
				thisStackItem.pre_context[2] = fileArray[errorLine-1];
			}

			if (errorLine <= fileLen) {
				thisStackItem["context_line"] = fileArray[errorLine];
			}

			if (fileLen >= errorLine+1) {
				thisStackItem.post_context[1] = fileArray[errorLine+1];
			}
			if (fileLen >= errorLine+2) {
				thisStackItem.post_context[2] = fileArray[errorLine+2];
			}

			frames.append( thisStackItem );
        }
        
        if( frames.len() ){
            logstashException[ "frames" ] = variables.util.toJSON( frames );
        }
		
		return logstashException;
    }
    
    /**
	 * Turns all slashes in a path to forward slashes except for \\ in a Windows UNC network share
	 * Also changes double slashes to a single slash
	 * @path The path to normalize
	 */
	private function normalizeSlashes( string path ) {
		var normalizedPath = arguments.path.replace( "\", "/", "all" );
		if( arguments.path.left( 2 ) == "\\" ) {
			normalizedPath = "\\" & normalizedPath.mid( 3, normalizedPath.len() - 2 );
		} 
		return normalizedPath.replace( "//", "/", "all" );	
	}

}
