component accessors="true" singleton {

	property name="appEnvironment" inject="box:setting:environment";

	/**
	 * Ensures a CF native struct is returned ( allowing for dot-notation )
	 *
	 * @memento A struct to ensure
	 */
	function ensureNativeStruct( required struct memento ){
		// deserialize/serialize JSON is currently the only way to to ensure deeply nested items are converted without deep recursion
		return deserializeJSON(
			serializeJSON(
				memento,
				false,
				listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
			)
		);
	}

	/**
	 * Creates a new java.util.HashMap with an optional struct to populate
	 *
	 * @memento  a struct to populate the memento with
	 */
	function newHashMap( struct memento ){
		var hashMap = createObject( "java", "java.util.HashMap" ).init();

		if ( !isNull( arguments.memento ) ) {
			// make sure we detach any references
			hashMap.putAll( ensureBooleanCasting( duplicate( arguments.memento ) ) );
			for ( var key in hashMap ) {
				if ( isNull( hashMap[ key ] ) ) continue;

				if ( isStruct( hashMap[ key ] ) && !isInstanceOf( hashMap[ key ], "java.util.HashMap" ) ) {
					hashMap[ key ] = newHashMap( ensureBooleanCasting( hashMap[ key ] ) );
				} else if ( isArray( hashMap[ key ] ) ) {
					// scope this in for CF's compiler
					var segment = hashMap[ key ];
					segment.each( function( item, index ){
						if ( isStruct( item ) && !isInstanceOf( item, "java.util.HashMap" ) ) {
							hashMap[ key ][ index ] = newHashMap( ensureBooleanCasting( item ) );
						}
					} );
				}
			}
		}

		return hashMap;
	}

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
			 ? " Reason: #isArray( errorPayload.error.root_cause ) ? errorPayload.error.root_cause[ 1 ].reason : errorPayload.error.root_cause.reason#"
			 : (
				structKeyExists( errorPayload, "error" )
				 ? (
					isSimpleValue( errorPayload.error )
					 ? " Reason: #errorPayload.error# "
					 : " Reason: #errorPayload.error.reason#"
				)
				 : ""
			);
		}
		if ( len( errorReason ) && !isSimpleValue( errorPayload.error ) && errorPayload.error.keyExists( "type" ) ) {
			throw(
				type         = "cbElasticsearch.native.#errorPayload.error.type#",
				message      = "An error was returned when communicating with the Elasticsearch server.  The error received was: #errorReason#",
				errorCode    = errorPayload.status,
				extendedInfo = isJSON( errorPayload ) ? errorPayload : toJSON( errorPayload )
			)
		} else if ( isSimpleValue( errorPayload ) && !isJSON( errorPayload ) ) {
			throw(
				type         = "cbElasticsearch.invalidRequest",
				message      = "An error occurred while communicating with the Elasticsearch server. The response received was not JSON",
				extendedInfo = errorPayload,
				errorCode    = response.getStatusCode()
			);
		} else {
			throw(
				type         = "cbElasticsearch.invalidRequest",
				message      = "Your request was invalid.  The response returned was #toJSON( errorPayload )#",
				extendedInfo = isJSON( errorPayload ) ? errorPayload : toJSON( errorPayload )
			);
		}
	}

	void function preflightLogEntry( required struct logObj ){

		if( !arguments.logObj.keyExists( "@timestamp" ) ){
			arguments.logObj[ "@timestamp" ] = dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
		}

		// ensure consistent casing for search
		if( logObj.keyExists( "labels" ) ){
			logObj[ "labels" ][ "environment" ] = lcase( logObj.labels.environment ?: variables.appEnvironment );
		} else {
			logObj[ "labels" ] = {
				"environment" : variables.appEnvironment
			}
		}

		if( LogObj.keyExists( "error" ) ){
			var errorStringify = [
				"frames",
				"extrainfo",
				"stack_trace"
			];

			errorStringify.each( function( key ){
				if ( logObj.error.keyExists( key ) && !isSimpleValue( logObj.error[ key ] ) ) {
					logObj.error[ key ] = toJSON( logObj.error[ key ] );
				}
			} );
		}

		generateLogEntrySignature( logObj );

	}

	/**
	 * Generates a stachebox appender signature for occurence groupings
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
				".error.type",
				".error.level",
				".error.message",
				".error.stack_trace",
				".error.frames"
			];
			var sigContent = "";
			signable.each( function( key ){
				logObj.findKey( listLast( key, "." ), "all" )
							.filter( function( found ){ return found.path == key } )
							.each( function( found ){
								if( !isNull( found.value ) && len( found.value ) ){
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
	 * Trim whitespace (newlines and tabs) from a script for safe parsing as a Painless script
	 *
	 * @script Prettified Elasticsearch script which is unfit for Painless
	 * @returns uglified Painless-safe (newlines and tabs removed) single-line script.
	 */
	public string function formatToPainless( required string script ){
		return reReplace( arguments.script, "\n|\r|\t", "", "ALL" );
	}

}
