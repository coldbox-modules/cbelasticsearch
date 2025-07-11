component accessors="true" singleton {

	property name="appEnvironment"     inject="box:setting:environment";
	property name="interceptorService" inject="coldbox:InterceptorService";
	property name="configStruct" 	   inject="box:modulesettings:cbelasticsearch";

	/**
	 * Workaround for Adobe 2018 metadata mutation bug with GSON: https://tracker.adobe.com/#/view/CF-4206423
	 * @deprecated   As soon as the bug above is fixed
	 **/
	any function ensureBooleanCasting( required any memento ){
		if ( isArray( memento ) ) {
			memento.each( function( item ){
				ensureBooleanCasting( item );
			} );
		} else if ( isStruct( memento ) ) {
			memento
				.keyArray()
				.each( function( key ){
					if ( !isNull( memento[ key ] ) && !isNumeric( memento[ key ] ) && isBoolean( memento[ key ] ) ) {
						memento[ key ] = javacast( "boolean", memento[ key ] );
					} else if ( !isNull( memento[ key ] ) && !isSimpleValue( memento[ key ] ) ) {
						ensureBooleanCasting( memento[ key ] );
					}
				} );
		}
		return memento;
	}

	/**
	 * Convenience method to ensure valid JSON, when prefixing is enabled
	 *
	 * @obj   any  the object to be serialized
	 */
	string function toJSON( any obj ){
		return serializeJSON(
			obj,
			false,
			listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
		);
	}


	void function handleResponseError( required Hyper.models.HyperResponse response ){
		var errorPayload = isJSON( response.getData() ) ? deserializeJSON( response.getData() ) : response.getData();
		var errorReason  = "";
		if ( !isSimpleValue( errorPayload ) ) {
			errorReason = (
				errorPayload.keyExists( "error" )
				&& !isSimpleValue( errorPayload.error )
				&& errorPayload.error.keyExists( "root_cause" )
			)
			 ? " Reason: #isArray( errorPayload.error.root_cause ) ? ( errorPayload.error.root_cause[ 1 ].reason ?: "None" ) : (
				errorPayload.error.root_cause.reason ?: "None"
			)#"
			 : (
				structKeyExists( errorPayload, "error" )
				 ? (
					isSimpleValue( errorPayload.error )
					 ? " Reason: #errorPayload.error# "
					 : " Reason: #errorPayload.error.reason ?: "None"#"
				)
				 : ""
			);
		}
		var message = "Your request was invalid.  The response returned was #toJSON( errorPayload )#";
		var type    = "cbElasticsearch.invalidRequest";
		if ( len( errorReason ) && !isSimpleValue( errorPayload.error ) && errorPayload.error.keyExists( "type" ) ) {
			type    = "cbElasticsearch.native.#errorPayload.error.type#";
			message = "An error was returned when communicating with the Elasticsearch server.  The error received was: #errorReason#";
		} else if ( isSimpleValue( errorPayload ) && !isJSON( errorPayload ) ) {
			message = "Elasticsearch server responded with [#response.getStatus()#]. The response received was not JSON.";
		}
		throw(
			type         = type,
			message      = message,
			errorCode    = isStruct( errorPayload ) && errorPayload.keyExists( "status" ) ? errorPayload.status : response.getStatusCode(),
			extendedInfo = isJSON( errorPayload ) ? errorPayload : toJSON( errorPayload )
		);
	}

	void function preflightLogEntry( required struct logObj ){
		if ( !arguments.logObj.keyExists( "@timestamp" ) ) {
			arguments.logObj[ "@timestamp" ] = now();
		}

		// We pre-test this because ACF2018 will not recognize an already formatted ISO8601 datetime with offset
		if ( isDate( arguments.logObj[ "@timestamp" ] ) ) {
			arguments.logObj[ "@timestamp" ] = dateTimeFormat(
				arguments.logObj[ "@timestamp" ],
				"yyyy-mm-dd'T'HH:nn:ssZZ"
			);
		}

		if ( arguments.logObj.keyExists( "event" ) && arguments.logObj.event.keyExists( "created" ) ) {
			if ( isDate( arguments.logObj.event.created ) ) {
				arguments.logObj.event.created = dateTimeFormat(
					arguments.logObj.event.created,
					"yyyy-mm-dd'T'HH:nn:ssZZ"
				);
			}
		}

		// ensure consistent casing for search
		if ( logObj.keyExists( "labels" ) ) {
			logObj[ "labels" ][ "environment" ] = lCase( logObj.labels.environment ?: variables.appEnvironment );
		} else {
			logObj[ "labels" ] = { "environment" : variables.appEnvironment }
		}

		if ( LogObj.keyExists( "error" ) ) {
			var errorStringify = [ "frames", "extrainfo", "stack_trace" ];

			errorStringify.each( function( key ){
				if ( logObj.error.keyExists( key ) && !isSimpleValue( logObj.error[ key ] ) ) {
					logObj.error[ key ] = toJSON( logObj.error[ key ] );
				}
			} );
		}

		generateLogEntrySignature( logObj );

		interceptorService.announce( "onLogstashEntryCreate", { "entry" : logObj } );
	}

	/**
	 * Generates a stachebox appender signature for occurence groupings
	 * @logObj The log object to be parsed
	 */
	void function generateLogEntrySignature( required struct logObj ){
		if ( !arguments.logObj.keyExists( "stachebox" ) ) {
			arguments.logObj[ "stachebox" ] = { "isSuppressed" : false };
		}
		// Attempt to create a signature for grouping
		if ( !arguments.logObj.stachebox.keyExists( "signature" ) ) {
			var signable = [
				".message",
				".labels.application",
				".log.level",
				".error.type",
				".error.level",
				".error.message",
				".error.stack_trace",
				".error.frames"
			];
			var sigContent = "";
			signable.each( function( key ){
				logObj
					.findKey( listLast( key, "." ), "all" )
					.filter( function( found ){
						return found.path == key
					} )
					.each( function( found ){
						if ( !isNull( found.value ) && len( found.value ) ) {
							sigContent &= found.value;
						}
					} );
			} );
			if ( len( sigContent ) ) {
				arguments.logObj.stachebox[ "signature" ] = hash( sigContent );
			}
		}
	}

	/**
	 * Parses Lucee HTML error messages ( usually emitted through the App.cfc onError method )
	 * @entry  The entry struct
	 * @key  The key to extract the message from
	 */
	function processHTMLFormattedMessages( required struct entry, string key = "message" ){
		// Lucee will sometimes transmit the error template as the exception message
		var htmlMessageRegex = "<td class=""label"">Message<\/td>\s*<td>(.*?)<\/td>";
		if (
			reFindNoCase(
				htmlMessageRegex,
				arguments.entry[ arguments.key ],
				1,
				false
			)
		) {
			var match = reFindNoCase(
				htmlMessageRegex,
				arguments.entry[ arguments.key ],
				1,
				true
			).match;
			if ( match.len() >= 2 ) {
				if ( arguments.entry.keyExists( "error" ) ) {
					arguments.entry.error[ "extrainfo" ] = arguments.entry[ arguments.key ];
				}
				arguments.entry[ arguments.key ] = match[ 2 ];
			}
		}
	}

	/**
	 * Trim whitespace (newlines and tabs) from a script for safe parsing as a Painless script
	 *
	 * @script Prettified Elasticsearch script which is unfit for Painless
	 * @returns uglified Painless-safe (newlines and tabs removed) single-line script.
	 */
	public string function formatToPainless( required string script ){
		return reReplace( arguments.script, "\n|\r|\t", "", "ALL" );
	}

	/**
	 * Get Real IP, by looking at clustered, proxy headers and locally.
	 * borrowed from cbSecurity
	 * 
	 * @trustUpstream If true, we check the forwarded headers first, else we don't
	 */
	string function getRealIP( boolean trustUpstream = configStruct.trustUpstream ){
		// When going through a proxy, the IP can be a delimtied list, thus we take the last one in the list
		if ( arguments.trustUpstream ) {
			var headers = getHTTPRequestData( false ).headers;
			if ( structKeyExists( headers, "x-cluster-client-ip" ) ) {
				return trim( listLast( headers[ "x-cluster-client-ip" ] ) );
			}
			if ( structKeyExists( headers, "X-Forwarded-For" ) ) {
				return trim( listFirst( headers[ "X-Forwarded-For" ] ) );
			}
		}

		return len( cgi.remote_addr ) ? trim( listFirst( cgi.remote_addr ) ) : "127.0.0.1";
	}
}
