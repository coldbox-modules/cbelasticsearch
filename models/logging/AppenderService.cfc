component accessors="true" singleton {

	property name="logbox"              inject="logbox";
	property name="elasticsearchClient" inject="Client@cbelasticsearch";
	property name="util"                inject="Util@cbelasticsearch";
	property name="detachedAppenders";

	this.logLevels = new coldbox.system.logging.LogLevels();

	function init(){
		variables.detachedAppenders = [];
		return this;
	}

	/**
	 * Create a detached appender for use in ad-hoc logging
	 *
	 * @name The name of the appender
	 * @properties
	 * @class The class to use for the appender. Defaults to LogStashAppender
	 */
	public void function createDetachedAppender(
		required string name,
		struct properties = {},
		string class      = "cbelasticsearch.models.logging.LogStashAppender"
	){
		structAppend(
			arguments.properties,
			{
				// The data stream name to use for this appenders logs
				"dataStreamPattern" : "logs-coldbox-#lCase( arguments.name )#*",
				"dataStream"        : "logs-coldbox-#lCase( arguments.name )#",
				"retentionDays"     : 365,
				// The max shard size at which the hot phase will rollover data
				"rolloverSize"      : "50gb"
			},
			false
		)

		variables.logBox.registerAppender(
			name       = arguments.name,
			class      = arguments.class,
			// Turn this appender off for all other logging, as it is intended to be used ad-hoc
			levelMin   = -1,
			levelMax   = -1,
			properties = arguments.properties
		);

		variables.detachedAppenders.append( arguments.name );
	}

	/**
	 * Method for retrieving a LogEvent instance.
	 */
	public LogEvent function getLogEvent(){
		return new coldbox.system.logging.LogEvent( argumentCollection = arguments );
	}

	/**
	 * Method for retrieving a struct of registered logbox appenders.
	 */
	public struct function getAppenderRegistry(){
		return variables.logBox.getAppenderRegistry();
	}


	/**
	 * Retreives a specific appender from the logbox registry
	 *
	 * @appenderName The name of the appender to retrieve
	 */
	public function getAppender( required string appenderName ){
		var registry = getAppenderRegistry();
		return registry.keyExists( appenderName ) ? registry[ appenderName ] : nullValue();
	}

	/**
	 * Logs a message out to a specific appender
	 *
	 * @appenderName The name of the appender to log to
	 * @message The message to log
	 * @severity The severity of the message
	 * @extraInfo Any extra information to log
	 * @category The category to log the message under
	 */
	public function logToAppender(
		required string appenderName,
		required string message,
		required any severity,
		struct extraInfo = {},
		string category
	){
		if ( !isNumeric( arguments.severity ) ) {
			if ( !this.logLevels.keyExists( arguments.severity ) ) {
				throw(
					type    = "cbelasticsearch.logging.InvalidSeverity",
					message = "The severity [#arguments.severity#] provided is not valid.  Please provide a valid numeric serverity or one of the following levels [#this.logLevels.keyArray().toList()#]."
				);
			}
			arguments.severity = this.logLevels[ arguments.severity ];
		}

		var appender = getAppender( appenderName );
		if ( !isNull( appender ) ) {
			appender.logMessage(
				getLogEvent(
					message   = arguments.message,
					category  = arguments.category ?: appenderName,
					severity  = arguments.severity,
					// we pre-stringify the json because of the OOM errors from COLDBOX-1288
					extraInfo = serializeJSON( arguments.extraInfo )
				)
			);
		} else {
			logbox
				.getRootLogger()
				.error(
					"Could not find a registered appender with the name: #appenderName#. Registered appenders are: #getAppenderRegistry().keyArray().toList()#",
					arguments
				);
		}
	}

	/**
	 * Logs a pre-formatted message or messages out to a specific appender.  The messages provided should should be structs, adhering to the [Elastic Common Schema](https://www.elastic.co/guide/en/ecs/current/ecs-field-reference.html)
	 *
	 * @appenderName The name of the appender to log to
	 * @message The message struct or or array of messages to log
	 */
	public function logRawToAppender(
		required string appenderName,
		required any messages,
		boolean refresh = false
	){
		var appender = getAppender( appenderName );
		if ( !isNull( appender ) ) {
			var createOptions = { "_index" : appender.getProperty( "dataStream" ) };

			if ( !isArray( messages ) ) {
				messages = [ messages ];
			}

			var inserts = messages.map( ( log ) => {
				structAppend( log, getCommonFields(), false );
				variables.util.preflightLogEntry( log );
				return log;
			} );

			elasticsearchClient.processBulkOperation(
				inserts.map( ( doc ) => [
					"operation": { "create" : createOptions },
					"source"   : doc
				] ),
				{ "refresh" : refresh }
			);
		} else {
			logbox
				.getRootLogger()
				.error(
					"Could not find a registered appender with the name: #appenderName#. Registered appenders are: #getAppenderRegistry().keyArray().toList()#",
					arguments
				);
		}
	}


	/**
	 * Returns common log entry fields
	 */
	function getCommonFields(){
		return {
			"@timestamp" : dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ssZZ" ),
			"file"       : { "path" : CGI.CF_TEMPLATE_PATH },
			"url"        : {
				"domain" : CGI.SERVER_NAME,
				"path"   : CGI.PATH_INFO,
				"port"   : CGI.SERVER_PORT,
				"query"  : CGI.QUERY_STRING,
				"scheme" : lCase( listFirst( CGI.SERVER_PROTOCOL, "/" ) )
			},
			"http"       : { "request" : { "referer" : CGI.HTTP_REFERER } },
			"host"       : { "name" : CGI.HTTP_HOST, "hostname" : CGI.SERVER_NAME },
			"client"     : { "ip" : CGI.REMOTE_ADDR },
			"user"       : {},
			"user_agent" : { "original" : CGI.HTTP_USER_AGENT }
		};
	}

}
