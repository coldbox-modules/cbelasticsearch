interface hint="The interface for all elasticsearch clients" {
	
	/**
	* Closes any connections to an active pool - for REST-based clients, this will not be necessary
	* 
	* @interfaced
	**/
	void function close(){}

	/**
	* Applies an index item
	* @indexBuilder 	IndexBuilder 	An instance of the IndexBuilder object
	* 
	* @return 			iNativeClient 	An implementation of the iNativeClient
	* @interfaced
	**/
	iNativeClient function applyIndex( required IndexBuilder indexBuilder ){}


	/**
	* Retrieves a document by ID
	* @id 		any 		The document key
	* @index 	string 		The name of the index
	* @type 	type 		The name of the type
	* @interfaced
	**/
	Document function get( 
		required any id,
		string index,
		string type
	){}

	/**
	* Persists an item to the index
	* @document 		Document@cbElasticSearch 		An instance of the elasticsearch Document object
	* 
	* @return 			iNativeClient 					An implementation of the iNativeClient
	* @interfaced
	**/
	iNativeClient function save( required Document document ){}

	/**
	* Persists an item to the index
	* @documents 		array 					An array of elasticsearch Document objects to persist
	* 
	* @return 			iNativeClient 			An implementation of the iNativeClient
	* @interfaced
	**/
	iNativeClient function saveAll( required array documents ){}

	/**
	* Execute a client search request
	* @searchBuilder 	SearchBuilder 	An instance of the SearchBuilder object
	* 
	* @return 			iNativeClient 	An implementation of the iNativeClient
	* @interfaced
	**/
	any function executeSearch( required searchBuilder searchBuilder ){}

	/**
	* Converts common client objects ( e.g. java object ) in to native CFML types
	* @obj 		any 		The object to convert
	* @interfaced
	**/
	any function toCFML( required any obj ){}

}