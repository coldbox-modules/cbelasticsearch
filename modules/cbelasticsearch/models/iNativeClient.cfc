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
	SearchResult function executeSearch( required searchBuilder searchBuilder );

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
	boolean function applyIndex( required IndexBuilder indexBuilder );

	/**
	* Deletes an index
	* 
	* @indexName 		string 		the name of the index to be deleted
	* 
	**/
	struct function deleteIndex( required string indexName );


	/**
	* Applies a single mapping to an index
	* @indexName 				string 		the name of the index
	* @mappingName	 			string 		the name of the mapping
	* @mappingConfig 			struct 		the mapping configuration struct
	* @interfaced
	**/
	struct function applyMapping( required string indexName, required string mappingName, required struct mappingConfig );


	/**
	* Applies multiple mappings to an index
	* @indexName 		string 		The name of the index
	* @mappings 		struct 		a struct containing the mapping configuration
	* @interfaced
	**/
	struct function applyMappings( required string indexName, required struct mappings );

	/**
	* Deletes a mapping
	* 
	* @indexName 		string 		the name of the index which contains the mapping
	* @mapping 			string 		the mapping ( e.g. type ) to delete
	* @throwOnError 	boolean	  	Whether to throw an error if the mapping could not be deleted ( default=false )
	* 
	* @return 			struct 		the deletion transaction response
	**/
	boolean function deleteMapping( required string indexName, required string mapping, boolean throwOnError=false );

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
	* @document 		Document@cbElasticSearch 		An instance of the elasticsearch Document object
	* 
	* @return 			iNativeClient 					An implementation of the iNativeClient
	* @interfaced
	**/
	Document function save( required Document document );

	/**
	* Deletes a single document
	* @document 		Document 		the Document object for the document to be deleted
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	**/
	boolean function delete( required any document, boolean throwOnError=true );


	/**
	* Deletes items in the index by query
	* @searchBuilder 		SearchBuilder 		The search builder object to use for the query
	**/
	boolean function deleteByQuery( required SearchBuilder searchBuilder );

	/**
	* Persists multiple items to the index
	* @documents 		array 					An array of elasticsearch Document objects to persist
	* 
	* @return 			array					An array of results for the saved items
	* @interfaced
	**/
	array function saveAll( required array documents );

	/**
	* Deletes documents from an array of documents or IDs
	* @documents 	array 		Either an array of Document objects
	* @throwOnError 	boolean			whether to throw an error if the document cannot be deleted ( default: false )
	**/
	any function deleteAll( 
		required array documents, 
		boolean throwOnError=false 
	);


}