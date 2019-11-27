/**
*
* Elasticsearch Client
*
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
	property name="wirebox" inject="wirebox";

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
		variables.nativeClient = variables.wirebox.getInstance( getConfig().get( 'client' ) );

		return this;
	}

	/**
	* Provider for Config object
	**/
	public function getConfig() provider="Config@cbElasticsearch"{}

	/**
	* Provider for search builder
	**/
	public function getSearchBuilder() provider="SearchBuilder@cbElasticsearch"{}

	/**
	* Execute a client search request
	* @searchBuilder 	SearchBuilder 	An instance of the SearchBuilder object
	*
	* @return 			iNativeClient 	An implementation of the iNativeClient
	* @interfaced
	**/
	SearchResult function executeSearch( required searchBuilder searchBuilder ){

		return variables.nativeClient.executeSearch( argumentCollection=arguments );

	}

	/**
	* Retreives a count of documents matching the given query
	* @searchBuilder 	SearchBuilder 	An instance of the SearchBuilder object
	*
	* @return 			numeric         The returned count matching the search parameters
	* @interfaced
	*/
	numeric function count( searchBuilder searchBuilder ){

		return variables.nativeClient.count( argumentCollection=arguments );

	}

	/**
	* Verifies whether an index exists
	*
	* @indexName 		string 		the name of the index
	**/
	boolean function indexExists( required string indexName ){

		return variables.nativeClient.indexExists( argumentCollection=arguments );
	}

	/**
	* Verifies whether an index mapping exists
	*
	* @indexName 		string 		the name of the index
	* @mapping 			string 		the name of the mapping
	**/
	boolean function indexMappingExists(
		required string indexName,
		required string mapping
	){

		return variables.nativeClient.indexMappingExists( argumentCollection=arguments );

    }



	/**
	* Applies an index item ( create/update )
	* @indexBuilder 	IndexBuilder 	An instance of the IndexBuilder object
	*
	* @return 			boolean 		Boolean result as to whether the index was created
	**/
	boolean function applyIndex( required IndexBuilder indexBuilder ){

		return variables.nativeClient.applyIndex( argumentCollection=arguments );

	}

	/**
	* Deletes an index
	*
	* @indexName 		string 		the name of the index to be deleted
	*
	**/
	struct function deleteIndex( required string indexName ){

		return variables.nativeClient.deleteIndex( argumentCollection=arguments );

    }

    /**
    * Applies a reindex action
    *
    * @source      string   The source index name or struct of options
	* @destination string   The destination index name or struct of options
	* @waitForCompletion boolean whether to return the result or an asynchronous task
	* @params any   Additional url params to add to the reindex action. 
	*               Supports multiple formats : `requests_per_second=50&slices=5`, `{ "requests_per_second" : 50, "slices" : 5 }`, or `[ { "name" : "requests_per_second", "value" : 50 } ]` )
	*
	* @return      any 	Struct result of the reindex action if waiting for completion or a Task object if dispatched asnyc
	**/
	any function reindex(
        required any source,
        required any destination,
		boolean waitForCompletion = true,
		any params
    ) {
		return variables.nativeClient.reindex( argumentCollection = arguments );
	}

	/**
	 * Returns a struct containing all indices in the system, with statistics
	 * 
	 * @verbose 	boolean 	whether to return the full stats output for the index
	 */
	struct function getIndices( verbose = false ){
		return variables.nativeClient.getIndices( argumentCollection = arguments );
	}

	/**
	 * Returns a struct containing the mappings of all aliases in the cluster
	 *
	 * @aliases 
	 */
	struct function getAliases(){
		return variables.nativeClient.getAliases( argumentCollection=arguments );
	}

	/**
	* Deletes an index type
	*
	* @indexName 		string 		the name of the index to be deleted
	* @type 			type 		the index typing to be deleted
	*
	* @deprecated   This method will be removed once support for ES v6.x has ended
	*
	**/
	boolean function deleteType( required string indexName, required string type ){

		var searchBuilder = getSearchBuilder().new(  arguments.indexName, arguments.type, { "match_all" : {} }  );

		return deleteByQuery( searchBuilder );

    }

    /**
    * Applies an alias (or array of aliases)
    *
	* @aliases    AliasBuilder    An AliasBuilder instance (or array of instances)
	*
	* @return     boolean 		  Boolean result as to whether the operations were successful
	**/
	boolean function applyAliases( required any aliases ) {
		return variables.nativeClient.applyAliases( argumentCollection=arguments );
	}

	/**
	* Applies a single mapping to an index
	* @indexName 				string 		the name of the index
	* @mappingName	 			string 		the name of the mapping
	* @mappingConfig 			struct 		the mapping configuration struct
	**/
	struct function applyMapping( required string indexName, required string mappingName, required struct mappingConfig ){

		return variables.nativeClient.applyMapping( argumentCollection=arguments );
	}


	/**
	* Applies mappings to an index
	* @indexName 		string 		the index containing the mappings
	* @mappings 		struct 		the struct representation of the mappings
	**/
	struct function applyMappings( required string indexName, required struct mappings ){

		return variables.nativeClient.applyMappings( argumentCollection=arguments );

	}

	/**
	* Deletes a mapping
	*
	* @indexName 		string 		the name of the index which contains the mapping
	* @mapping 			string 		the mapping ( e.g. type ) to delete
	* @throwOnError 	boolean	  	Whether to throw an error if the mapping could not be deleted ( default=false )
	*
	* @return 			struct 		the deletion transaction response
	**/
	boolean function deleteMapping(
		required string indexName,
		required string mapping,
		boolean throwOnError=false
	){

		return variables.nativeClient.deleteMapping( argumentCollection=arguments );

	}

	/**
	* Retrieves a document by ID
	* @id 		any 		The document key
	* @index 	string 		The name of the index
	* @type 	type 		The name of the type
	* @interfaced
	*
	* @return 	any 		Returns a Document object if found, otherwise returns null
	**/
	any function get(
		required any id,
		string index,
		string type
	){

		return variables.nativeClient.get( argumentCollection=arguments );

	}

	/**
	* Gets multiple items when provided an array of keys
	* @keys 	array 		An array of keys to retrieve
	* @index 	string 		The name of the index
	* @type 	type 		The name of the type
	* @interfaced
	*
	* @return 	array 		An array of Document objects
	**/
	array function getMultiple(
		required array keys,
		string index,
		string type
	){
		return variables.nativeClient.getMultiple( argumentCollection=arguments );
	}

	/**
	 * Retreives a task and its status 
	 * 
	 * @taskId          string                          The identifier of the task to retreive
	 * @taskObj         Task                            The task object used for population - defaults to a new task
	 * 
	 * @interfaced
	 */
	any function getTask( required string taskId, Task taskObj ){
		return variables.nativeClient.getTask( argumentCollection=arguments );
	}

	/**
	 * Retreives all tasks running on the cluster
	 * 
	 * @interfaced
	 */
	any function getTasks(){
		return variables.nativeClient.getTasks();
	}

	/**
	* @document 		Document@cbElasticSearch 		An instance of the elasticsearch Document object
	*
	* @return 			Document@cbElasticsearch 		The saved document object
	**/
	Document function save( required Document document ){

		return variables.nativeClient.save( argumentCollection=arguments );

	}

	/**
	* Deletes a single document
	* @document 		Document 		the Document object for the document to be deleted
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	**/
	boolean function delete( required any document, boolean throwOnError=true ){
		return variables.nativeClient.delete( argumentCollection=arguments );
	}

	/**
	* Deletes items in the index by query
	* @searchBuilder 		SearchBuilder 		The search builder object to use for the query
	* @waitForCompletion    boolean             Whether to block the request until completion or return a task which can be checked
	**/
	any function deleteByQuery( required SearchBuilder searchBuilder, boolean waitForCompletion = true ){

		return variables.nativeClient.deleteByQuery( argumentCollection=arguments );

	}

	/**
	* Updates items in the index by query
	* @searchBuilder 		SearchBuilder 		The search builder object to use for the query
	* @script 				struct 				script to process on the query
	* @waitForCompletion    boolean             Whether to block the request until completion or return a task which can be checked
	**/
	any function updateByQuery( required SearchBuilder searchBuilder, required struct script, boolean waitForCompletion = true ){

		return variables.nativeClient.updateByQuery( argumentCollection=arguments );

	}

	/**
	* Persists multiple items to the index
	* @documents 		array 					An array of elasticsearch Document objects to persist
	*
	* @return 			array					An array of results for the saved items
	**/
	array function saveAll( required array documents ){

		return variables.nativeClient.saveAll( argumentCollection=arguments );

	}

	/**
	* Deletes documents from an array of documents or IDs
	* @documents 	array 		Either an array of Document objects
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	**/
	any function deleteAll(
		required array documents,
		boolean throwOnError=false
	){

		return variables.nativeClient.deleteAll( documents );

	}


	/**
	 * Parses a parameter argument.
	 * upports multiple formats : `requests_per_second=50&slices=5`, `{ "requests_per_second" : 50, "slices" : 5 }`, or `[ { "name" : "requests_per_second", "value" : 50 } ]` )
	 * 
	 * @params any the parameters to filter and transform
	 */
	array function parseParams( required any params ){
		return variables.nativeClient.parseParams( argumentCollection=arguments );
	}



}
