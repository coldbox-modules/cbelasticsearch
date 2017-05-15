/**
* Elasticsearch appender for LogBox
**/
component extends="coldbox.system.logging.AbstractAppender" output="false" hint="This a simple implementation of a log appender for Elasticsearch" {
	
	/**
	 * Constructor
	 */
	public ElasticsearchAppender function init(
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

		instance.DEFAULTS = {
			"index"            : "logbox",
			"type"             : "logs-" & dateFormat( now(), "yyyy-mm-dd" ),
			"rotate"           : true,
			"rotationDays"     : 30,
			"rotationFrequency": 5,
			"ensureChecks"     : true,
			"autoCreate"       : true
		};

		for( var configKey in structKeyArray( instance.Defaults ) ){
			if( !propertyExists( configKey ) ){
				setProperty( configKey, instance.DEFAULTS[ configKey ] );
			}
		}

		if( !propertyExists( 'defaultCategory' ) ){
			setProperty( "defaultCategory", arguments.name);
		}
					
		// DB Rotation Time
		instance.lastDBRotation = now();

		application.wirebox.autowire( this );
		
		return this;
	}

	/**
	* Client provider
	**/
	Client function getClient() provider="Client@cbElasticsearch"{}

	/**
	* Document provider
	**/
	Client function newDocument() provider="Document@cbElasticsearch"{}

	/**
	* Index Builder Provider
	**/
	Client function indexBuilder() provider="IndexBuilder@cbElasticsearch"{}

	/**
	* Search Builder Provider
	**/
	Client function searchBuilder() provider="SearchBuilder@cbElasticsearch"{}

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

			newDocument().new( 
				getProperty( "index" ),
				getProperty( "type" ),
				{
					"severity"     : severityToString(loge.getseverity()),
					"category"     : category,
					"logdate"      : dateTimeFormat( loge.getTimestamp(), "yyyy-mm-dd'T'hh:nn:ssZZ" ),
					"appendername" : getName(),
					"message"      : loge.getMessage(),
					"extrainfo"    : loge.getExtraInfoAsString(),
					"entryTime"    : dateTimeFormat( now(), "yyyy-mm-dd'T'hh:nn:ssZZ" )
				}
			).setId( instance.uuid.randomUUID() )
			.save();
		
		//  rotation 
		this.rotationCheck();
	}
	//  rotationCheck 

	/**
	 * Rotation checks
	 */
	public any function rotationCheck() output=false {

			// Verify if in rotation frequency
			if( 
				isDate( instance.lastDBRotation ) 
				&& 
				dateDiff( "n",  instance.lastDBRotation, now() ) <= getProperty( "rotationFrequency" ) 
			){
				return;
			}
			
			// Rotations
			this.doRotation();
			
			// Store last profile time
			instance.lastDBRotation = now();

	}
	//  doRotation 

	/**
	 * Do Rotation
	 */
	public any function doRotation() output=false {
		var targetDate 	= dateAdd( "d", "-#getProperty( "rotationDays" )#", now() );

		//set our type name to todays date
		setProperty( "type", "logs-" & dateFormat( now(), "yyyy-mm-dd" ) );

		//purge log entries that are greater than the number of specified rotationDays
		searchBuilder().new( 
			index=getProperty( "index" ),
			properties={
				"filtered": {
			        "query": {
				        "query_string": {
				          "query": "*"
				        }
			        }
			    },
			    "filter": {
			        "range": {
			          "@timestamp": {
			            "lte": dateTimeFormat( targetDate, "yyyy-mm-dd'T'hh:nn:ssZZ" )
			          }
			        }
			    }
			}
		).deleteAll();

	}
	// ---------------------------------------- PRIVATE ---------------------------------------
	
	/**
	 * Verify or create the logging index
	 */
	private void function ensureIndex() output=false {

		indexBuilder().new( 
			name=getProperty( "index" ),
			properties={
				"mappings":{
					"#getProperty( "type" )#":{
						"_all"       : { "enabled": false },
						"properties" : {
							"severity"    : {"type" : "string"},
							"category"    : {"type" : "string"},
							"appendername": {"type" : "string"},
							"logdate"	  : {
								"type"  : "date",
								"format": "date_time_no_millis"
							},
							"message"     : {"type" : "string"},
							"extrainfo"   : {"type" : "string"},
							"entryTime"	  : {
								"type"  : "date",
								"format": "date_time_no_millis"
							}
						}
					}
				}
			} 
		).save();

	}

	

}