/**
* ElasticSearch Document Object
**/
component 
	accessors="true"
{
	property name="config" inject="Config@cbElasticsearch";

	/**
	* The index which contains or will contain this document
	**/
	property name="index";
	/**
	* The type within the index where this document will be categorized
	**/
	property name="type";
	/**
	* The `_id` value of the document
	**/
	property name="id";
	/**
	* The structural representation of the document object
	**/
	property name="document";

	function onDIComplete(){

		var configStruct = variables.config.getConfigStruct();
		//set default document types
		variables.index = configStruct.defaultIndex;
		variables.type = structKeyExists( configStruct, "defaultType") ? configStruct.defaultType : "search_collection";

		return this;
	}


	/**
	* Returns a new Document instance
	* @index 		string		the index name
	* @type 		string 		the index type
	* @properties 	struct 		the structural representation of the document
	**/
	public function new( 
		required string index, 
		required string type, 
		struct properties={}
	){
		variables.index 	= arguments.index;
		variables.type  	= arguments.type;
		variables.document 	= arguments.properties;
	}

	/**
	* Populates an existing document object
	* @properties 	struct 		the structural representation of the document
	**/
	public function populate( 
		required struct properties
	){

		structAppend( variables.document, duplicate( arguments.properties ), true);
		
		if( structKeyExists( variables.document, "_id" ) ){
			setId( variables.document[ "_id" ] );
			structDelete( variables.document, "_id" );
		}

	}


	/**
	* Sets a key value within the current document
	* @name 	string 		the key name
	* @value 	string 		the key value
	**/
	public function set( 
		required string name, 
		required any value 
	){
		variables.document[ arguments.name ] = arguments.value;
	}

	/**
	* Gets a key value within the current document
	* @key 		string 		the key to search
	* @return   any|null 	returns null if the key does not exist in the current document
	**/
	public any function get( 
		required string key
	){
		//null return if the key does not exist
		if( !structKeyExists( variables.document, arguments.key ) ) return;

		return variables.document[ arguments.key ];
	}

	/**
	* Returns the JSON string of the document object
	* @includeKey 	boolean 	Whether to include the document key in the returned packet
	**/
	public string function toString( boolean includeKey=false){

		var documentObject = duplicate( variables.document );
		
		if( arguments.includeKey && !isNull( variables.id ) ){
			documentObject[ "_id" ] = variables.id;
		}

		return serializeJSON( documentObject );
	}
	
}