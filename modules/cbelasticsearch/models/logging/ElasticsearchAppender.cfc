/**
* Elasticsearch appender for LogBox
**/
component extends="LogstashAppender" output="false" hint="This a simple implementation of a log appender for Elasticsearch" accessors="true"{

	property name="lastDBRotation";
	
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

		structAppend( 
			arguments.properties,
			{
				"index"            : "logbox",
				"rotate"           : false,
				"rotationDays"     : 30,
				"rotationFrequency": 5,
				"ensureChecks"     : true,
				"autoCreate"       : true
			},
			false 
		);

		// Init supertype
		super.init( argumentCollection=arguments );

		variables.lastDBRotation = now();

		return this;

	}

    /**
    * Search Builder Provider
    **/
    Client function searchBuilder() provider="SearchBuilder@cbElasticsearch"{}

	/**
	 * Write an entry into the appender.
	 */
	public void function logMessage(required any logEvent) output=false {
		super.logMessage( argumentCollection=arguments );
		//  rotation 
		this.rotationCheck();
	}
	//  rotationCheck 

	/**
	 * Rotation checks
	 */
	public any function rotationCheck() output=false {

			if( 
				!isNull( variables.lastDBRotation ) 
				&& 
				dateDiff( "n",  variables.lastDBRotation, now() ) <= getProperty( "rotationFrequency" ) 
			){
				return;
			}
			
			// Rotations
			this.doRotation();
			
			// Store last profile time
			variables.lastDBRotation = now();

	}
	//  doRotation 

	/**
	 * Do Rotation
	 */
	public any function doRotation() output=false {
		
		var targetDate 	= dateAdd( "d", "-#getProperty( "rotationDays" )#", now() );
		var formatter = createObject( "java", "java.text.SimpleDateFormat" ).init( "yyyy-MM-dd'T'HH:mm:ssXXX" );

		//purge log entries that are greater than the number of specified rotationDays
		searchBuilder().new( 
			index=getRotationalIndexName()
		).setQuery(
			{
				"bool": {
					"filter": {
						"range": {
								"timestamp": {
									"lte": formatter.format( targetDate ).replace("Z", "+00:00")
								}
						}
					}
				}
			}
		)
		.deleteAll();

	}

}