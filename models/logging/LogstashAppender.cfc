/**
 * Elasticsearch appender for LogBox
 **/
component
	extends="coldbox.system.logging.AbstractAppender"
	output ="false"
	hint   ="This a logstash appender for Elasticsearch"
{

	property name="util" inject="Util@cbelasticsearch";
	property name="cachebox" inject="cachebox";
	property name="asyncManager" inject="box:AsyncManager";

	/**
	 * Constructor
	 */
	public LogstashAppender function init(
		required name,
		properties = {},
		layout     = "",
		levelMin   = "0",
		levelMax   = "4"
	) output=false{
		if ( !structKeyExists( application, "wirebox" ) ) {
			throw(
				type    = "cbElasticsearch.Elasticsearch.DependencyException",
				message = "Wirebox was not detected in the application scope, but is required to use this appender"
			);
		}

		// Init supertype
		super.init( argumentCollection = arguments );

		// UUID generator
		instance.uuid = createObject( "java", "java.util.UUID" );

		instance.appRoot = normalizeSlashes( expandPath( "/" ) );

		var applicationName = properties.keyExists( "applicationName" )
		 ? properties.applicationName
		 : ( server.coldfusion.productname eq "Lucee" ? getApplicationSettings().name : getApplicationMetadata().name );

		instance.DEFAULTS = {
			"dataStreamPattern" : "logs-coldbox-*",
			"dataStream" : "logs-coldbox-logstash-appender",
			"ILMPolicyName"   : "cbelasticsearch-logs",
			"componentTemplateName" : "cbelasticsearch-logs-mappings",
			"indexTemplateName" : "cbelasticsearch-logs",
			// Retention of logs in number of days
			"retentionDays"   : 365,
			// optional lifecycle full policy
			"lifecyclePolicy" : javacast( "null", 0 ),
			"applicationName" : applicationName,
			"releaseVersion"  : "",
			"indexShards"     : 1,
			"indexReplicas"   : 0,
			"rolloverSize"    : "10gb",
			"cacheName"       : "template",
			"migrateIndices"  : false
		};

		for ( var configKey in structKeyArray( instance.Defaults ) ) {
			if ( !propertyExists( configKey ) && !isNull( instance.DEFAULTS[ configKey ] ) ) {
				setProperty( configKey, instance.DEFAULTS[ configKey ] );
			}
		}

		// Backward compatibility
		if( propertyExists( "index" ) ){
			setProperty( "dataStream", left( getProperty( "index" ), 5 ) == "logs-" ? getProperty( "index" ) : "logs-" & getProperty( "index" ) );
			setProperty( "dataStreamPattern", getProperty( "dataStream" ) );
		}

		if ( !propertyExists( "defaultCategory" ) ) {
			setProperty( "defaultCategory", arguments.name );
		}

		application.wirebox.autowire( this );

		return this;
	}

	/**
	 * Document provider
	 **/
	Document function newDocument() provider="Document@cbElasticsearch"{
	}

	/**
	 * Index Builder Provider
	 **/
	ILMPolicyBuilder function policyBuilder() provider="ILMPolicyBuilder@cbElasticsearch"{
	}

	/**
	 * Client provider
	 **/
	Client function getClient() provider="Client@cbElasticsearch"{
	}

	/**
	 * Runs on registration
	 */
	public LogstashAppender function onRegistration() output=false{
		ensureDataStream();
		return this;
	}

	/**
	 * Write an entry into the appender.
	 */
	public void function logMessage( required any logEvent ) output=false{
		var loge      = arguments.logEvent;
		var extraInfo = loge.getExtraInfo();
		var level     = uCase( severityToString( loge.getSeverity() ) );
		var message   = loge.getMessage();
		var loggerCat = loge.getCategory();

		// Is this an exception or not?
		if (
			( isStruct( extraInfo ) || isObject( extraInfo ) )
			&& extraInfo.keyExists( "StackTrace" ) && extraInfo.keyExists( "Message" ) && extraInfo.keyExists(
				"Detail"
			)
		) {
			local.logObj = parseException(
				exception = extraInfo,
				level     = level,
				message   = message,
				logger    = loggerCat
			);
		} else if (
			( isStruct( extraInfo ) || isObject( extraInfo ) )
			&& extraInfo.keyExists( "exception" ) && isStruct( extraInfo.exception ) && extraInfo.exception.keyExists(
				"StackTrace"
			)
		) {
			var trimmedExtra = structCopy( extraInfo );
			trimmedExtra.delete( "exception" );

			local.logObj = parseException(
				exception      = extraInfo.exception,
				level          = level,
				message        = message,
				logger         = loggerCat,
				additionalData = trimmedExtra
			);
		} else {
			local.logObj = {
				"application" : getProperty( "applicationName" ),
				"release"     : len( getProperty( "releaseVersion" ) ) ? javacast(
					"string",
					getProperty( "releaseVersion" )
				) : javacast( "null", 0 ),
				"type"      : "message",
				"level"     : level,
				"category"  : loggerCat,
				"message"   : loge.getMessage(),
				"extrainfo" : loge.getExtraInfoAsString()
			};
		}
		logObj[ "timestamp" ]    = dateTimeFormat( loge.getTimestamp(), "yyyy-mm-dd'T'hh:nn:ssZZ" );
		logObj[ "severity" ]     = loge.getSeverity();
		logObj[ "appendername" ] = getName();

		// Logstash/Kibana Convention Keys
		structAppend(
			logObj,
			{
				"@timestamp" : logObj.timestamp,
				"host"       : { "name" : CGI.HTTP_HOST, "hostname" : CGI.SERVER_NAME }
			},
			false
		);

		if ( logObj.severity < 2 ) {
			logObj[ "snapshot" ] = {
				"template"       : CGI.CF_TEMPLATE_PATH,
				"path"           : CGI.PATH_INFO,
				"referer"        : CGI.HTTP_REFERER,
				"browser"        : CGI.HTTP_USER_AGENT,
				"remote_address" : CGI.REMOTE_ADDR
			};

			if ( structKeyExists( application, "cbController" ) ) {
				var event         = application.cbController.getRequestService().getContext();
				logObj[ "event" ] = {
					"name"  : ( event.getCurrentEvent() != "" ) ? event.getCurrentEvent() : "N/A",
					"route" : ( event.getCurrentRoute() != "" ) ? event.getCurrentRoute() & (
						event.getCurrentRoutedModule() != "" ? " from the " & event.getCurrentRoutedModule() & "module router." : ""
					) : "N/A",
					"routed_url" : ( event.getCurrentRoutedURL() != "" ) ? event.getCurrentRoutedURL() : "N/A",
					"layout"     : ( event.getCurrentLayout() != "" ) ? event.getCurrentLayout() : "N/A",
					"module"     : event.getCurrentModule(),
					"view"       : event.getCurrentView()
				};

				if ( !logObj.keyExists( "environment" ) ) {
					logObj[ "environment" ] = application.cbController.getSetting(
						name         = "environment",
						defaultValue = "production"
					);
				}
			}
		}
		if ( propertyExists( "userInfoUDF" ) ) {
			var udf = getProperty( "userInfoUDF" );

			if ( isClosure( udf ) ) {
				try {
					logObj[ "userinfo" ] = udf();
				} catch ( any e ) {
					logObj[ "userinfo" ] = "An error occurred when attempting to run the userInfoUDF provided.  The message received was #e.message#";
				}
			}
		}

		preflightLogEntry( logObj );

		newDocument()
			.new( index = getProperty( "dataStream" ), properties = logObj )
			.create();

	}

	// ---------------------------------------- PRIVATE ---------------------------------------

	/**
	 * Verify or create the logging index
	 */
	private void function ensureDataStream() output=false{

		var dataStreamName = getProperty( "dataStream" );
		var dataStreamPattern = getProperty( "dataStreamPattern" );
		var componentTemplateName = getProperty( "componentTemplateName" );
		var indexTemplateName = getProperty( "indexTemplateName" );

		
		var policyMeta = {
			"description" : "Lifecyle Policy for cbElasticsearch logs"
		};
		var policyBuilder = policyBuilder().new( policyName=getProperty( "ILMPolicyName" ), meta=policyMeta );
		// Put our ILM Policy
		if( propertyExists( "lifecyclePolicy" ) ){
			policyBuilder.setPolicy( getProperty( "lifecyclePolicy" ) );
		} else {
			policyBuilder.withDeletion(
				age = getProperty( "retentionDays" )
			);
		}

		policyBuilder.save();

		// Upsert our component template
		getClient().applyComponentTemplate(
			componentTemplateName,
			getComponentTemplate()
		);

		// Upsert the current version of our template
		getClient().applyIndexTemplate(
			indexTemplateName,
			{
				"index_patterns" : [ dataStreamPattern ],
				"composed_of" : [ 
					"logs-mappings",
					"data-streams-mappings",
					"logs-settings", 
					componentTemplateName 
				],
				"data_stream" : {},
				"priority" : 150,
				"_meta" : {
					"description" : "Index Template for cbElasticsearch Logs"
				}
			}
		);

		// Check for any previous indices created matching the pattern and migrate them to the datastream
		if( propertyExists( "index" ) && left( getProperty( "index" ), 5 ) != "logs-" && getProperty( "migrateIndices" ) ){
			var existingIndexPrefix = getProperty( "index" );
			var existingIndices = getClient().getIndices().keyArray().filter(
				function( index ){
					return len( index ) >= len( existingIndexPrefix ) && left( index, len( existingIndexPrefix ) ) == existingIndexPrefix;
				}
			);
			variables.asyncManager.allApply(
				existingIndices,
				function( index ){
					try{
						getClient().reindex( index, dataStream, true );
					} catch( any e ){
						// Print to StdError to bypass LogBox, since we are in an appender
						createObject( "java", "java.lang.System" ).err.println( "[ERROR] Index Migration Between the Previous Index of #index# to the data stream #dataStreamName# could not be completed.  The error received was: #e.message#" );
					}
				}
			);
		} else if( propertyExists( "index" ) && getProperty( "migrateIndices" ) ){
			getClient().migrateToDataStream( dataStreamName );
		} else if( !getClient().dataStreamExists( dataStreamName ) ){
			getClient().ensureDataStream( dataStreamName );
		}
		
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
		string path  = "",
		any additionalData,
		string message = "",
		string logger  = getName()
	){
		// Ensure expected keys exist
		arguments.exception.StackTrace = arguments.exception.StackTrace ?: "";

		arguments.exception.type       = isSimpleValue( arguments.exception.type ) ? arguments.exception.type : "error";
		arguments.exception.detail     = arguments.exception.detail ?: "";
		arguments.exception.TagContext = arguments.exception.TagContext ?: [];

		var logstashException = {
			"application" : getProperty( "applicationName" ),
			"release"     : javacast( "string", getProperty( "releaseVersion" ) ),
			"type"        : arguments.exception.type.toString(),
			"level"       : arguments.level,
			"category"    : logger,
			"component"   : "test",
			"message"     : message & " " & arguments.exception.detail,
			"stacktrace"  : isSimpleValue( arguments.exception.StackTrace ) ? listToArray(
				arguments.exception.StackTrace,
				"#chr( 13 )##chr( 10 )#"
			) : arguments.exception.StackTrace
		};

		var logstashexceptionExtra = {};
		var file                   = "";
		var fileArray              = "";
		var currentTemplate        = "";
		var tagContext             = arguments.exception.TagContext;
		var i                      = 1;
		var st                     = "";

		// If there's no tag context, include the stack trace instead
		if ( !tagContext.len() ) {
			var showJavaStackTrace = true;
		} else {
			var showJavaStackTrace = false;
		}

		if ( showJavaStackTrace ) {
			st = reReplace(
				arguments.exception.StackTrace,
				"\r",
				"",
				"All"
			);
			st                                         = reReplace( st, "\t", "", "All" );
			logstashExceptionExtra[ "javaStacktrace" ] = listToArray( st, "#chr( 13 )##chr( 10 )#" );
		}

		// Applies to type = "database". Native error code associated with exception. Database drivers typically provide error codes to diagnose failing database operations. Default value is -1.
		if ( structKeyExists( arguments.exception, "NativeErrorCode" ) ) {
			logstashExceptionExtra[ "database" ][ "nativeErrorCode" ] = arguments.exception.NativeErrorCode;
		}

		// Applies to type = "database". SQLState associated with exception. Database drivers typically provide error codes to help diagnose failing database operations. Default value is 1.
		if ( structKeyExists( arguments.exception, "SQLState" ) ) {
			logstashExceptionExtra[ "database" ][ "SQLState" ] = arguments.exception.SQLState;
		}

		// Applies to type = "database". The SQL statement sent to the data source.
		if ( structKeyExists( arguments.exception, "Sql" ) ) {
			logstashExceptionExtra[ "database" ][ "SQL" ] = arguments.exception.Sql;
		}

		// Applies to type ="database". The error message as reported by the database driver.
		if ( structKeyExists( arguments.exception, "queryError" ) ) {
			logstashExceptionExtra[ "database" ][ "queryError" ] = arguments.exception.queryError;
		}

		// Applies to type= "database". If the query uses the cfqueryparam tag, query parameter name-value pairs.
		if ( structKeyExists( arguments.exception, "where" ) ) {
			logstashExceptionExtra[ "database" ][ "where" ] = arguments.exception.where;
		}

		// Applies to type = "expression". Internal expression error number.
		if ( structKeyExists( arguments.exception, "ErrNumber" ) ) {
			logstashExceptionExtra[ "expression" ][ "errorNumber" ] = arguments.exception.ErrNumber;
		}

		// Applies to type = "missingInclude". Name of file that could not be included.
		if ( structKeyExists( arguments.exception, "MissingFileName" ) ) {
			logstashExceptionExtra[ "missingInclude" ][ "missingFileName" ] = arguments.exception.MissingFileName;
		}

		// Applies to type = "lock". Name of affected lock (if the lock is unnamed, the value is "anonymous").
		if ( structKeyExists( arguments.exception, "LockName" ) ) {
			logstashExceptionExtra[ "lock" ][ "name" ] = arguments.exception.LockName;
		}

		// Applies to type = "lock". Operation that failed (Timeout, Create Mutex, or Unknown).
		if ( structKeyExists( arguments.exception, "LockOperation" ) ) {
			logstashExceptionExtra[ "lock" ][ "operation" ] = arguments.exception.LockOperation;
		}

		// Applies to type = "custom". String error code.
		if (
			structKeyExists( arguments.exception, "ErrorCode" ) && len( arguments.exception.ErrorCode ) && arguments.exception.ErrorCode != "0"
		) {
			logstashExceptionExtra[ "custom" ][ "errorCode" ] = arguments.exception.ErrorCode;
		}

		// Applies to type = "application" and "custom". Custom error message; information that the default exception handler does not display.
		if ( structKeyExists( arguments.exception, "ExtendedInfo" ) && len( arguments.exception.ExtendedInfo ) ) {
			logstashExceptionExtra[ "application" ][ "extendedInfo" ] = arguments.exception.ExtendedInfo;
		}

		if ( structCount( logstashExceptionExtra ) ) logstashException[ "extrainfo" ] = logstashExceptionExtra;


		var frames = [];
		for ( i = arrayLen( tagContext ); i > 0; i-- ) {
			var thisTCItem = tagContext[ i ];
			if ( compareNoCase( thisTCItem[ "TEMPLATE" ], currentTemplate ) ) {
				fileArray = [];
				if ( fileExists( thisTCItem[ "TEMPLATE" ] ) ) {
					file = fileOpen( thisTCItem[ "TEMPLATE" ], "read" );
					while ( !fileIsEOF( file ) ) {
						arrayAppend( fileArray, fileReadLine( file ) );
					}
					fileClose( file );
				}
				currentTemplate = thisTCItem[ "TEMPLATE" ];
			}

			var thisStackItem = {
				"abs_path"     : thisTCItem[ "TEMPLATE" ],
				"filename"     : normalizeSlashes( thisTCItem[ "TEMPLATE" ] ).replace( instance.appRoot, "" ),
				"lineno"       : thisTCItem[ "LINE" ],
				"pre_context"  : [],
				"context_line" : "",
				"post_context" : []
			};

			// for source code rendering
			var fileLen   = arrayLen( fileArray );
			var errorLine = thisTCItem[ "LINE" ];

			if ( errorLine - 3 >= 1 && errorLine - 3 <= fileLen ) {
				thisStackItem.pre_context[ 1 ] = fileArray[ errorLine - 3 ];
			}
			if ( errorLine - 2 >= 1 && errorLine - 2 <= fileLen ) {
				thisStackItem.pre_context[ 1 ] = fileArray[ errorLine - 2 ];
			}
			if ( errorLine - 1 >= 1 && errorLine - 1 <= fileLen ) {
				thisStackItem.pre_context[ 2 ] = fileArray[ errorLine - 1 ];
			}

			if ( errorLine <= fileLen ) {
				thisStackItem[ "context_line" ] = fileArray[ errorLine ];
			}

			if ( fileLen >= errorLine + 1 ) {
				thisStackItem.post_context[ 1 ] = fileArray[ errorLine + 1 ];
			}
			if ( fileLen >= errorLine + 2 ) {
				thisStackItem.post_context[ 2 ] = fileArray[ errorLine + 2 ];
			}

			frames.append( thisStackItem );
		}

		if ( frames.len() ) {
			logstashException[ "frames" ] = frames;
		}

		return logstashException;
	}

	/**
	 * Turns all slashes in a path to forward slashes except for \\ in a Windows UNC network share
	 * Also changes double slashes to a single slash
	 * @path The path to normalize
	 */
	private function normalizeSlashes( string path ){
		var normalizedPath = arguments.path.replace( "\", "/", "all" );
		if ( arguments.path.left( 2 ) == "\\" ) {
			normalizedPath = "\\" & normalizedPath.mid( 3, normalizedPath.len() - 2 );
		}
		return normalizedPath.replace( "//", "/", "all" );
	}

	private function preflightLogEntry( required struct logObj ){
		var stringify = [
			"frames",
			"extrainfo",
			"stacktrace",
			"snapshot",
			"event",
			"userinfo"
		];

		stringify.each( function( key ){
			if ( logObj.keyExists( key ) && !isSimpleValue( logObj[ key ] ) ) {
				logObj[ key ] = variables.util.toJSON( logObj[ key ] );
			}
		} );

		if ( !arguments.logObj.keyExists( "stachebox" ) ) {
			arguments.logObj[ "stachebox" ] = { "isSuppressed" : false };
		}
		// Attempt to create a signature for grouping
		if ( !arguments.logObj.stachebox.keyExists( "signature" ) ) {
			var signable = [
				"application",
				"type",
				"level",
				"message",
				"stacktrace",
				"frames"
			];
			var sigContent = "";
			signable.each( function( key ){
				if ( logObj.keyExists( key ) ) {
					sigContent &= logObj[ key ];
				}
			} );
			if ( len( sigContent ) ) {
				arguments.logObj.stachebox[ "signature" ] = hash( sigContent );
			}
		}
		
		// ensure consistent casing for search
		logObj[ "environment" ] = lcase( logObj.environment ?: "production" );

	}

	public function getComponentTemplate(){
		return {
			"settings" : {
				"index.refresh_interval" : "5s",
				"number_of_replicas"     : getProperty( "indexReplicas" ),
				"index.lifecycle.name": getProperty( "ILMPolicyName" )
			},
			"mappings" : {
				"dynamic_templates" : [
					{
						"message_field" : {
							"path_match"         : "message",
							"match_mapping_type" : "string",
							"mapping"            : {
								"type"   : "text",
								"norms"  : false,
								"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 1024 } }
							}
						}
					},
					{
						"string_fields" : {
							"match"              : "*",
							"match_mapping_type" : "string",
							"mapping"            : {
								"type"   : "text",
								"norms"  : false,
								"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
							}
						}
					}
				],
				"properties" : {
					"geoip"      : {
						"dynamic"    : true,
						"properties" : {
							"ip"        : { "type" : "ip" },
							"location"  : { "type" : "geo_point" },
							"latitude"  : { "type" : "half_float" },
							"longitude" : { "type" : "half_float" }
						}
					},
					// Customized properties
					"timestamp"    : { "type" : "date", "format" : "date_time_no_millis" },
					"type"         : { "type" : "keyword" },
					"application"  : { "type" : "keyword" },
					"environment"  : { "type" : "keyword" },
					"release"      : { "type" : "keyword" },
					"level"        : { "type" : "keyword" },
					"severity"     : { "type" : "integer" },
					"category"     : { "type" : "keyword" },
					"appendername" : { "type" : "keyword" },
					"stachebox"    : {
						"type"       : "object",
						"properties" : {
							"signature"    : { "type" : "keyword" },
							"isSuppressed" : { "type" : "boolean" }
						}
					}
				}
			}
		};
	}

}
