/**
 * Elasticsearch appender for LogBox
 **/
component
	extends="coldbox.system.logging.AbstractAppender"
	output ="false"
	hint   ="This a logstash appender for Elasticsearch"
{

	property name="util"         inject="Util@cbelasticsearch";
	property name="cachebox"     inject="cachebox";
	property name="asyncManager" inject="box:AsyncManager";
	// Internal flag for completion of the data stream creation
	property name="_dataStreamAssured";

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

		variables._dataStreamAssured = false;

		// Init supertype
		super.init( argumentCollection = arguments );

		// UUID generator
		instance.uuid = createObject( "java", "java.util.UUID" );

		instance.appRoot = normalizeSlashes( expandPath( "/" ) );

		var applicationName = properties.keyExists( "applicationName" )
		 ? properties.applicationName
		 : ( server.coldfusion.productname eq "Lucee" ? getApplicationSettings().name : getApplicationMetadata().name );

		instance.DEFAULTS = {
			// Data stream components
			"dataStreamPattern"     : "logs-coldbox-*",
			"dataStream"            : "logs-coldbox-logstash-appender",
			"ILMPolicyName"         : "cbelasticsearch-logs",
			"componentTemplateName" : "cbelasticsearch-logs-mappings",
			"indexTemplateName"     : "cbelasticsearch-logs",
			"indexTemplatePriority" : 150,
			"pipelineName"          : "cbelasticsearch-logs",
			// Retention of logs in number of days
			"retentionDays"         : 365,
			// optional lifecycle full policy
			"lifecyclePolicy"       : javacast( "null", 0 ),
			// the application name to use for this instance
			"applicationName"       : applicationName,
			// The release version
			"releaseVersion"        : "",
			// The number of shards for the backing indices
			"indexShards"           : 1,
			// The number of replicas for the backing indices
			"indexReplicas"         : 0,
			// The maximum shard size at which a rollover of the oldest data will occur
			"rolloverSize"          : "10gb",
			// v2 migration fields
			"index"                 : javacast( "null", 0 ),
			"migrateIndices"        : false,
			// Whether to throw an error if an attempt to save a log entry fails
			"throwOnError"          : true,
			"async"                 : false,
			// Timeout, in ms, to allow async threads to exist - otherwise they default to 0
			"asyncTimeout"          : 5000,
			// Custom labels which are applied to every log message
			"labels"                : [],
		};

		for ( var configKey in structKeyArray( instance.Defaults ) ) {
			if ( !propertyExists( configKey ) && !isNull( instance.DEFAULTS[ configKey ] ) ) {
				setProperty( configKey, instance.DEFAULTS[ configKey ] );
			}
		}

		if ( !propertyExists( "defaultCategory" ) ) {
			setProperty( "defaultCategory", arguments.name );
		}

		// Attempt to retreive the package version from the `box.json`
		if ( !len( getProperty( "releaseVersion" ) ) && fileExists( expandPath( "/box.json" ) ) ) {
			try {
				var packageInfo = deserializeJSON( fileRead( expandPath( "/box.json" ) ) );
				setProperty( "releaseVersion", packageInfo.version ?: "" );
			} catch ( any e ) {
			}
		}

		application.wirebox.autowire( this );

		return this;
	}

	/**
	 * Document provider
	 **/
	Document function newDocument() provider="Document@cbelasticsearch"{
	}

	/**
	 * Index Builder Provider
	 **/
	ILMPolicyBuilder function policyBuilder() provider="ILMPolicyBuilder@cbelasticsearch"{
	}

	/**
	 * Client provider
	 **/
	Client function getClient() provider="HyperClient@cbelasticsearch"{
	}

	/**
	 * Runs on registration
	 */
	public LogstashAppender function onRegistration() output=false{
		try {
			ensureDataStream();
			variables._dataStreamAssured = true;
		} catch ( any e ) {
			createObject( "java", "java.lang.System" ).err.println(
				"Unable to create data stream. The attempt to communicate with the Elasticsearch server returned: #e.message# - #e.detail#.  Your ability to log messages with this appender may be compromised."
			);
		}
		return this;
	}

	/**
	 * Write an entry into the appender.
	 */
	public void function logMessage( required any logEvent ) output=false{
		if ( !variables._dataStreamAssured ) {
			this.onRegistration();
			// skip out if there was a communication failure
			if ( !variables._dataStreamAssured ) {
				return;
			}
		}

		var logObj = marshallLogObject( argumentCollection = arguments );

		try {
			var document = newDocument().new( index = getProperty( "dataStream" ), properties = logObj );
			if ( getProperty( "async" ) ) {
				variables.asyncManager
					.newFuture()
					.withTimeout( getProperty( "asyncTimeout" ) )
					.run( () => document.create() );
			} else {
				document.create();
			}
		} catch ( any e ) {
			if ( getProperty( "throwOnError" ) ) {
				rethrow;
			} else {
				var eLogEvent = new coldbox.system.logging.LogEvent(
					message   = "An error occurred while attempting to save a log to Elasticsearch via the LogstashAppender.  The exception received was #e.message# - #e.detail#",
					severity  = 1,
					extraInfo = { "logData" : logObj, "exception" : e },
					category  = e.type
				);
				var appendersMap = application.wirebox.getLogbox().getAppenderRegistry();
				// Log errors out to other appenders besides this one
				appendersMap
					.keyArray()
					.filter( function( key ){
						return lCase( key ) != lCase( getName() );
					} )
					.each( function( appenderName ){
						appendersMap[ appenderName ].logMessage( eLogEvent );
					} );
			}
		}
	}

	public struct function marshallLogObject( required any logEvent ) output=false{
		var loge      = arguments.logEvent;
		var extraInfo = loge.getExtraInfo();
		var level     = lCase( severityToString( loge.getSeverity() ) );
		var message   = loge.getMessage();
		var loggerCat = loge.getCategory();
		var tzInfo    = getTimezoneInfo();

		var logObj = {
			"@timestamp" : dateTimeFormat( loge.getTimestamp(), "yyyy-mm-dd'T'HH:nn:ssZZ" ),
			"log"        : {
				"level"    : level,
				"logger"   : getName(),
				"category" : loggerCat
			},
			"message" : message,
			"labels" : [
				{ "application" : getProperty( "applicationName" ) }
			]
			"event"   : {
				"created"  : dateTimeFormat( loge.getTimestamp(), "yyyy-mm-dd'T'HH:nn:ssZZ" ),
				"severity" : loge.getSeverity(),
				"category" : loggerCat,
				"dataset"  : "cfml",
				"timezone" : tzInfo.timezone ?: createObject( "java", "java.util.TimeZone" ).getDefault().getId()
			},
			"file" : { "path" : CGI.CF_TEMPLATE_PATH },
			"url"  : {
				"domain" : CGI.SERVER_NAME,
				"path"   : CGI.PATH_INFO,
				"port"   : CGI.SERVER_PORT,
				"query"  : CGI.QUERY_STRING,
				"scheme" : lCase( listFirst( CGI.SERVER_PROTOCOL, "/" ) )
			},
			"http"    : { "request" : { "referer" : CGI.HTTP_REFERER } },
			"package" : {
				"name"    : getProperty( "applicationName" ),
				"version" : javacast( "string", getProperty( "releaseVersion" ) ),
				"type"    : "cfml",
				"path"    : expandPath( "/" )
			},
			"host"       : { "name" : CGI.HTTP_HOST, "hostname" : CGI.SERVER_NAME },
			"client"     : { "ip" : CGI.REMOTE_ADDR },
			"user"       : {},
			"user_agent" : { "original" : CGI.HTTP_USER_AGENT }
		};

		if ( propertyExists( "userInfoUDF" ) ) {
			var udf = getProperty( "userInfoUDF" );
			if ( isClosure( udf ) ) {
				try {
					logObj.user[ "info" ] = udf();
					if ( !isSimpleValue( logObj.user.info ) ) {
						if ( isStruct( logObj.user.info ) ) {
							var userKeys = [
								"email",
								"domain",
								"full_name",
								"hash",
								"id",
								"name",
								"roles",
								"username"
							];
							if( logObj.user.info.keyExists( "labels" )  && isStruct( logObj.user.info.labels ) ){
								logObj.labels.append(  logObj.user.info.labels.keyArray().map( ( acc, key ) => {
									return { "#key#" : javacast( "string" logObj.user.info.labels[ key ] ) };
								}), true );
								logObj.user.info.delete( "labels" );
							}
							userKeys.each( function( key ){
								if ( key == "username" ) key = "name";
								if ( logObj.user.info.keyExists( key ) ) {
									logObj.user[ key ] = logObj.user.info[ key ];
								}
							} );
						}
						logObj.user.info = variables.util.toJSON( logObj.user.info );
					}
				} catch ( any e ) {
					logObj[ "user" ] = {
						"error" : "An error occurred when attempting to run the userInfoUDF provided.  The message received was #e.message# #e.detail#"
					};
				}
			}
		}

		if ( structKeyExists( application, "cbController" ) ) {
			var event = application.cbController.getRequestService().getContext();
			var rc    = event.getCollection();
			structAppend(
				local.logObj.event,
				{
					"name"  : ( event.getCurrentEvent() != "" ) ? event.getCurrentEvent() : javacast( "null", 0 ),
					"route" : ( event.getCurrentRoute() != "" ) ? event.getCurrentRoute() & (
						event.getCurrentRoutedModule() != "" ? " from the " & event.getCurrentRoutedModule() & "module router." : ""
					) : javacast( "null", 0 ),
					"extension" : rc.keyExists( "format" ) ? rc.format : javacast( "null", 0 ),
					"url"       : ( event.getCurrentRoutedURL() != "" ) ? event.getCurrentRoutedURL() : javacast(
						"null",
						0
					),
					"layout" : ( event.getCurrentLayout() != "" ) ? event.getCurrentLayout() : javacast(
						"null",
						0
					),
					"module" : event.getCurrentModule(),
					"view"   : event.getCurrentView()
				},
				true
			);

			logObj.url[ "full" ] = ( event.getCurrentRoutedURL() != "" ) ? event.getCurrentRoutedURL() : javacast(
				"null",
				0
			);

			logObj.package[ "reference" ] = event.getHTMLBaseURL();

			if ( !logObj.labels.find( ( label ) => label.keyArray().first() == "environment" ) ) {
				logObj.labels.append( { "environment" : application.cbController.getSetting( name = "environment", defaultValue = "production" ) } );
			}
		}

		// Exception information
		if (
			( isStruct( extraInfo ) || isObject( extraInfo ) )
			&& extraInfo.keyExists( "StackTrace" ) && extraInfo.keyExists( "Message" ) && extraInfo.keyExists(
				"Detail"
			)
		) {
			structAppend(
				local.logObj,
				parseException(
					exception = extraInfo,
					level     = level,
					message   = message
				),
				true
			);
		} else if (
			( isStruct( extraInfo ) || isObject( extraInfo ) )
			&& extraInfo.keyExists( "exception" ) && isStruct( extraInfo.exception ) && extraInfo.exception.keyExists(
				"StackTrace"
			)
		) {
			var trimmedExtra = structCopy( extraInfo );
			trimmedExtra.delete( "exception" );

			structAppend(
				local.logObj,
				parseException(
					exception      = extraInfo.exception,
					level          = level,
					message        = message,
					additionalData = trimmedExtra
				),
				true
			);
		} else {
			local.logObj[ "error" ] = {
				"type"      : "message",
				"level"     : level,
				"message"   : loge.getMessage(),
				"extrainfo" : loge.getExtraInfoAsString()
			};
		}

		variables.util.preflightLogEntry( logObj );

		return logObj;
	}

	// ---------------------------------------- PRIVATE ---------------------------------------

	/**
	 * Verify or create the logging index
	 */
	private void function ensureDataStream() output=false{
		var dataStreamName        = getProperty( "dataStream" );
		var dataStreamPattern     = getProperty( "dataStreamPattern" );
		var componentTemplateName = getProperty( "componentTemplateName" );
		var indexTemplateName     = getProperty( "indexTemplateName" );


		var policyMeta    = { "description" : "Lifecyle Policy for cbElasticsearch logs" };
		var policyBuilder = policyBuilder().new( policyName = getProperty( "ILMPolicyName" ), meta = policyMeta );
		// Put our ILM Policy
		if ( propertyExists( "lifecyclePolicy" ) ) {
			policyBuilder.setPhases( getProperty( "lifecyclePolicy" ) );
		} else {
			policyBuilder
				.hotPhase( rollover = getProperty( "rolloverSize" ) )
				.withDeletion( age = getProperty( "retentionDays" ) );
		}

		policyBuilder.save();

		// Create our pipeline to handle data from older versions of the appender
		getClient()
			.newPipeline()
			.setId( getProperty( "pipelineName" ) )
			.setDescription( "Ingest pipeline for cbElasticsearch logstash appender" )
			.addProcessor( {
				"script" : {
					"lang"   : "painless",
					"source" : reReplace(
						fileRead(
							expandPath( "/cbelasticsearch/models/logging/scripts/v2MigrationProcessor.painless" )
						),
						"\n|\r|\t",
						"",
						"ALL"
					)
				}
			} )
			.save()

		// Upsert our component template
		getClient().applyComponentTemplate( componentTemplateName, getComponentTemplate() );

		// Upsert the current version of our template
		getClient().applyIndexTemplate(
			indexTemplateName,
			{
				"index_patterns" : [ dataStreamPattern ],
				"composed_of"    : [
					"logs-mappings",
					"data-streams-mappings",
					"logs-settings",
					componentTemplateName
				],
				"data_stream" : {},
				"priority"    : getProperty( "indexTemplatePriority" ),
				"_meta"       : {
					"description" : "Index Template for cbElasticsearch Logs ( DataStream: #dataStreamName# )"
				}
			}
		);

		if ( !getClient().dataStreamExists( dataStreamName ) ) {
			getClient().ensureDataStream( dataStreamName );
		}

		// Check for any previous indices created matching the pattern and migrate them to the datastream
		if ( propertyExists( "index" ) && getProperty( "migrateIndices" ) ) {
			var existingIndexPrefix = getProperty( "index" );
			var existingIndices     = getClient()
				.getIndices()
				.keyArray()
				.filter( function( index ){
					return len( index ) >= len( existingIndexPrefix ) && left( index, len( existingIndexPrefix ) ) == existingIndexPrefix;
				} );
			variables.asyncManager.allApply( existingIndices, function( index ){
				try {
					getClient().reindex(
						index,
						{ "index" : dataStreamName, "op_type" : "create" },
						true
					);
					getClient().deleteIndex( index );
				} catch ( any e ) {
					// Print to StdError to bypass LogBox, since we are in an appender
					createObject( "java", "java.lang.System" ).err.println(
						"Index Migration Between the Previous Index of #index# to the data stream #dataStreamName# could not be completed.  The error received was: #e.message#"
					);
				}
			} );
		}
	}

	/**
	 * @exception The exception
	 * @level The level to log
	 * @path The path to the script currently executing
	 * @additionalData Additional metadata to store with the event - passed into the extra attribute
	 * @message Optional message name to output
	 */
	private struct function parseException(
		required any exception,
		string level = "error",
		string path  = "",
		any additionalData,
		string message = ""
	){
		// Ensure expected keys exist
		arguments.exception.StackTrace = arguments.exception.StackTrace ?: "";

		arguments.exception.type       = isSimpleValue( arguments.exception.type ) ? arguments.exception.type : "error";
		arguments.exception.detail     = arguments.exception.detail ?: "";
		arguments.exception.TagContext = arguments.exception.TagContext ?: [];

		var logstashException = {
			"error" : {
				"level"       : arguments.level,
				"type"        : arguments.exception.type.toString(),
				"message"     : message & " " & arguments.exception.detail,
				"stack_trace" : isSimpleValue( arguments.exception.StackTrace ) ? listToArray(
					arguments.exception.StackTrace,
					"#chr( 13 )##chr( 10 )#"
				) : arguments.exception.StackTrace
			}
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

		if ( structCount( logstashExceptionExtra ) ) logstashException.error[ "extrainfo" ] = logstashExceptionExtra;


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
			logstashException.error[ "frames" ] = frames;
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

	public function getComponentTemplate(){
		return {
			"settings" : {
				"number_of_shards"       : getProperty( "indexShards" ),
				"number_of_replicas"     : getProperty( "indexReplicas" ),
				"index.lifecycle.name"   : getProperty( "ILMPolicyName" ),
				"index.default_pipeline" : getProperty( "pipelineName" )
			},
			"mappings" : {
				"dynamic_templates" : [
					{
						"user_info_fields" : {
							"path_match"         : "user.info.*",
							"match_mapping_type" : "string",
							"mapping"            : {
								"type"   : "text",
								"norms"  : false,
								"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 256 } }
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
					"geoip" : {
						"dynamic"    : true,
						"properties" : {
							"ip"        : { "type" : "ip" },
							"location"  : { "type" : "geo_point" },
							"latitude"  : { "type" : "half_float" },
							"longitude" : { "type" : "half_float" }
						}
					},
					"log" : {
						"type"       : "object",
						"properties" : { "category" : { "type" : "keyword" } }
					},
					"error" : {
						"type"       : "object",
						"properties" : { "extrainfo" : { "type" : "text" } }
					},
					"message" : {
						"type"   : "text",
						"fields" : { "keyword" : { "type" : "keyword", "ignore_above" : 512 } }
					},
					"event" : {
						"type"       : "object",
						"properties" : {
							"created" : { "type" : "date", "format" : "date_time_no_millis" },
							"layout"  : { "type" : "keyword" },
							"module"  : { "type" : "keyword" },
							"view"    : { "type" : "keyword" }
						}
					},
					// Customized properties
					"stachebox" : {
						"type"       : "object",
						"properties" : {
							"signature"    : { "type" : "keyword" },
							"isSuppressed" : { "type" : "boolean" },
							"assignment"   : { "type" : "keyword" }
						}
					}
				}
			}
		};
	}

}
