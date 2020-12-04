/**
*
* Elasticsearch Config
*
* The configuration object for the module 
* @singleton
* @package cbElasticsearch.models.Elasticsearch
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
* 
*/
component accessors="true"{
	property name="configStruct" inject="coldbox:modulesettings:cbelasticsearch";
	

	/**
	* Returns a key value in the config struct
	* @key 				string  	the key value to search for. Dot notation may be used to retrieve a nested key
	* @configNode 		any  		a configuration node to search.  Accepts an argument of any to support recursion. 
	* @return 			any|null 	returns null if the key does not exist. Otherwise returns the value
	**/
	public any function get( required string key, any configNode=variables.configStruct ){

		if( !isStruct( arguments.configNode ) ) return javacast( "null", 0 );

		var keyArray = listToArray( arguments.key, "." );

		for( var i=1; i <= arrayLen( keyArray ); i++ ){
		
			var nodeKey = keyArray[ i ];
			
			// return a null if we have no matching key
			if( !structKeyExists( arguments.configNode, nodeKey ) ) return javacast( "null", 0 );

			// if the last item in the key string, return the value
			if( i == arrayLen( keyArray ) ){
			
				return arguments.configNode[ nodeKey ];
			
			// otherwise recurse further
			} else {
				
				var remainingKeys = duplicate( keyArray );

				for( var j=1; j <= i; j++ ){
					arrayDeleteAt( remainingKeys, j );
				}

				return get( arrayToList( remainingKeys, "." ), arguments.configNode[ nodeKey ] );
			
			}

		}

	}

}
