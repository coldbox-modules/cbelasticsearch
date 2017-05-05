/**
*
* Elasticsearch Client
*
* @singleton
* @package cbElasticsearch.models.Elasticsearch
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
* 
*/
component 
	name="ElasticsearchClient" 
	accessors="true" 
	threadsafe 
	singleton
{
	
	/**
	* Utility Class
	*/

	property name="config" inject="Config@cbElasticsearch";

	/**
	* Properties created on init()
	*/
	property name="nativeClient";
	
	/**
	* Constructor
	*/
	public function init(){

		return this;
	}

	/**
	* Pool close method
	**/
	public function close(){
		variables.nativeClient.close();
	}

	/**
	* After init the autowire properties
	*/
	public function onDIComplete(){
		
		//The Elasticsearch driver client
		variables.nativeClient = variables.config.getNativeClient();

		return this;
	}



}