/**
*
* Elasticsearch Native Client Interface
*
* @singleton
* @package cbElasticsearch.models
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
interface{


	/**
	* Closes any connections to the pool and destroys the client singleton
	* @interfaced
	**/
	void function close();


	/**
	* Execute a client search request
	* @searchBuilder 	SearchBuilder 	An instance of the SearchBuilder object
	*
	* @return 			iNativeClient 	An implementation of the iNativeClient
	* @interfaced
	**/
	cbElasticsearch.models.SearchResult function executeSearch( required cbElasticsearch.models.searchBuilder searchBuilder );

	/**
	* Retreives a count of documents matching the given query
	* @searchBuilder 	SearchBuilder 	An instance of the SearchBuilder object
	*
	* @return 			numeric         The returned count matching the search parameters
	* @interfaced
	*/
	numeric function count( cbElasticsearch.models.searchBuilder searchBuilder );

	/**
	* Verifies whether an index exists
	*
	* @indexName 		string 		the name of the index
	**/
	boolean function indexExists( required string indexName );

	/**
	* Verifies whether an index mapping exists
	*
	* @indexName 		string 		the name of the index
	* @mapping 			string 		the name of the mapping
	* @interfaced
	**/
	boolean function indexMappingExists(
		required string indexName,
		required string mapping
	);

	/**
	* Applies an index item ( create/update )
	* @indexBuilder 	IndexBuilder 	An instance of the IndexBuilder object
	*
	* @return 			struct 		A struct representation of the transaction result
	* @interfaced
	**/
	boolean function applyIndex( required cbElasticsearch.models.IndexBuilder indexBuilder );

	/**
	* Deletes an index
	*
	* @indexName 		string 		the name of the index to be deleted
	*
	**/
    struct function deleteIndex( required string indexName );

    /**
    * Applies an alias (or array of aliases)
    *
	* @aliases    AliasBuilder    An AliasBuilder instance (or array of instances)
	*
	* @return     boolean 		  Boolean result as to whether the operations were successful
	**/
	boolean function applyAliases( required any aliases );

    /**
    * Applies a reindex action
    *
    * @source               string      The source index name or struct of options
	* @destination          string      The destination index name or struct of options
	* @waitForCompletion    boolean     Whether to return the result or an asynchronous task
	* @params               any         Additional url params to add to the reindex action.
    *                                   Supports multiple formats : `requests_per_second=50&slices=5`, `{ "requests_per_second" : 50, "slices" : 5 }`, or `[ { "name" : "requests_per_second", "value" : 50 } ]` )
    * @script               any         A script to run while reindexing.
    * @throwOnError         boolean     Whether to throw an exception if the reindexing fails.  This flag is
    *                                   only used if `waitForCompletion` is `true`.
	*
	* @return               any 	    Struct result of the reindex action if waiting for completion or a Task object if dispatched asnyc
	**/
	any function reindex(
        required any source,
        required any destination,
		boolean waitForCompletion = true,
		any params,
        any script,
        boolean throwOnError = true
    );

	/**
	 * Returns a struct containing all indices in the system, with statistics
	 *
	 * @verbose 	boolean 	whether to return the full stats output for the index
	 */
	struct function getIndices( verbose = false );


	/**
	 * Returns a struct containing the mappings of all aliases in the cluster
	 *
	 * @aliases
	 */
	struct function getAliases();

	/**
	* Applies a single mapping to an index
	* @indexName 				string 		the name of the index
	* @mappingName	 			string 		the name of the mapping
	* @mappingConfig 			struct 		the mapping configuration struct
	* @interfaced
	**/
	struct function applyMapping( required string indexName, string mappingName, required struct mappingConfig );


	/**
	* Applies multiple mappings to an index
	* @indexName 		string 		The name of the index
	* @mappings 		struct 		a struct containing the mapping configuration
	* @interfaced
	**/
	struct function applyMappings( required string indexName, required struct mappings );

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
	);

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
	);

	/**
	 * Retreives a task and its status
	 *
	 * @taskId          string                          The identifier of the task to retreive
	 *
	 * @interfaced
	 */
	any function getTask( required string taskId, cbElasticsearch.models.Task taskObj );

	/**
	 * Retreives all tasks running on the cluster
	 */
	any function getTasks();

	/**
	* @document 		Document@cbElasticSearch 		An instance of the elasticsearch Document object
	*
	* @return 			iNativeClient 					An implementation of the iNativeClient
	* @interfaced
	**/
	cbElasticsearch.models.Document function save( required cbElasticsearch.models.Document document );

	/**
	 * Patches an elasticsearch document using either a script or a partial doc
	 *
	 * @index       string 		The index to operate on
	 * @identifier 	string 		The identifier of the elasticsearch document
	 * @contents    struct 		A struct of contents to update.  May contain script/doc information, along with upsert parameters  
	 * @params      struct      A struct of params to provide to the deletion request
	 * 
	 * @return      void
	 * 
	 * @see         https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update.html
	 */
	void function patch( required string index,  required string identifier, required struct contents, struct params = {} );
	
	/**
	* Deletes a single document
	* @document 		Document 		the Document object for the document to be deleted
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	* @params           struct          a struct of params to provide to the deletion request
	*
	* @return           boolean         (true|false) as to whether the doucument was deleted
	*
	* @see              https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete.html
	**/
	boolean function delete( required cbElasticsearch.models.Document document, boolean throwOnError=true, struct params = {} );

	/**
	* Deletes a single document when provided an index and identifier
	*
	* @index            string          the index to perform the operation on
	* @identifier       string          the identifier of the document
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	* @params           struct          a struct of params to provide to the deletion request
	*
	* @return           boolean         (true|false) as to whether the doucument was deleted
	*
	* @see              https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete.html
	**/
	boolean function deleteById( required string index, required string identifier, boolean throwOnError=true, params = {} );


	/**
	* Deletes items in the index by query
	* @searchBuilder 		SearchBuilder 		The search builder object to use for the query
	* @waitForCompletion    boolean             Whether to block the request until completion or return a task which can be checked
	**/
	any function deleteByQuery( required cbElasticsearch.models.SearchBuilder searchBuilder, boolean waitForCompletion = true );

	/**
	* Updates items in the index by query
	* @searchBuilder 		SearchBuilder 		The search builder object to use for the query
	* @script 				struct 				script to process on the query
	* @waitForCompletion    boolean             Whether to block the request until completion or return a task which can be checked
	**/
	any function updateByQuery( required cbElasticsearch.models.SearchBuilder searchBuilder, required struct script, boolean waitForCompletion = true );

	/**
	* Persists multiple items to the index
	* @documents 		array 					An array of elasticsearch Document objects to persist
	* @throwOnError     boolean                 Whether to throw an exception on error on individual documents which were not persisted
	*
	* @return 			array					An array of results for the saved items
	**/
	array function saveAll( required array documents, boolean throwOnError=false );

	/**
	* Deletes documents from an array of documents or IDs
	* @documents 	array 		Either an array of Document objects
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	**/
	any function deleteAll(
		required array documents,
		boolean throwOnError=false
	);

	/**
	 * Processes a bulk operation against one or a number of instances
	 *
	 * @operations  	array 		An array of operations to perform
	 * @params          struct      Parameters to apply on the request
	 * @throwOnError    boolean     Whether to throw an error if the result was unsuccessful
	 * 
	 * @see             https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html
	 */
	any function processBulkOperation( required array operations, struct params = {}, boolean throwOnError = true );

	/**
	 * Parses a parameter argument.
	 * upports multiple formats : `requests_per_second=50&slices=5`, `{ "requests_per_second" : 50, "slices" : 5 }`, or `[ { "name" : "requests_per_second", "value" : 50 } ]` )
	 *
	 * @params any the parameters to filter and transform
	 */
	array function parseParams( required any params );


}
