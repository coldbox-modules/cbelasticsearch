/**
 *
 * Elasticsearch Document Object
 *
 * @package cbElasticsearch.models
 * @author Jon Clausen <jclausen@ortussolutions.com>
 * @license Apache v2.0 <http: // www.apache.org / licenses/>
 *
 */
component accessors="true" {

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
	 * A hit score for documents in search results
	 **/
	property name="score";
	/**
	 * Highlights for the document in search results
	 **/
	property name="highlights";
	/**
	 * The structural representation of the document object
	 **/
	property name="memento";

	/**
	 * The pipeline used to process this document
	 */
	property name="pipeline";

	/**
	 * Parameters to pass through on the save request
	 */
	property name="params";


	function onDIComplete(){
		reset();
	}

	function reset(){
		var configStruct = variables.config.getConfigStruct();
		// set default document types
		variables.index  = configStruct.defaultIndex;
		variables.type   = structKeyExists( configStruct, "defaultType" ) ? configStruct.defaultType : javacast(
			"null",
			0
		);
		variables.highlights = {};
		variables.memento    = {};
		variables.params     = {};

		var nullDefaults = [ "id", "score" ];

		for ( var nullDefault in nullDefaults ) {
			if ( !structKeyExists( variables, nullDefault ) || !isNull( variables[ nullDefault ] ) ) {
				variables[ nullDefault ] = javacast( "null", 0 );
			}
		}

		return this;
	}

	/**
	 * Client provider
	 **/
	Client function getClient() provider="Client@cbElasticsearch"{
	}

	/**
	 * Persists the document to Elasticsearch
	 *
	 * @refresh  any if `true`, will return a newly populated instance of the document retreived from the index ( useful for pipelined saves ). if `"wait_for"`, will block until the next index refresh ingests the document update.
	 **/
	function save( any refresh = false ){
		return getClient().save( this, arguments.refresh );
	}

	/**
	 * Create-only method to save a document using the bulk API.  Will throw an error if the document already exists.
	 *
	 * @refresh
	 */
	function create( any refresh = false ){
		var createOptions = {
			"_index" : variables.index
		};
		if( !isNull( variables.id ) && len( variables.id ) ){
			createOptions[ "_id" ] = variables.id;
		}

		variables.params[ "refresh" ] = "wait_for";

		if( !isNull( variables.pipeline ) ){
			variables.params[ "pipeline" ] = variables.pipeline;
		}

		var response = getClient().processBulkOperation(
			[
				{
                    "operation" : { "create" :  createOptions },
                    "source" : getDocument()
                }
			],
			variables.params
        );

		if( response.errors ){
			var result = response.items[ 1 ][ "create" ];
			throw(
				type         = "cbElasticsearch.invalidRequest",
				message      = "An error occurred while performing document creation.  The response received was: #getClient().getUtil().toJSON( result.error )#",
				extendedInfo = getClient().getUtil().toJSON( result ),
				errorCode    = "200"
			);
		}

		if( arguments.refresh ){
			var idx = response.items[ 1 ][ "create" ][ "_index" ];
			var docId = response.items[ 1 ][ "create" ][ "_id" ];
			return getClient().get( id = docId, index = idx );
		} else {
			return this;
		}
		
	}

	/**
	 * Loads a document
	 * @id 		string 		The `_id` of the document to retrieve
	 * @index 	string 		The index of the document
	 * @type 	string 		The type of the document
	 **/
	function get( string id, string index, string type ){
		if ( !isNull( arguments.id ) ) {
			variables.id = arguments.id;
		}
		if ( !isNull( arguments.index ) ) {
			variables.index = arguments.index;
		}
		if ( !isNull( arguments.type ) ) {
			variables.type = arguments.type;
		}

		if ( isNull( variables.id ) ) {
			throw(
				type    = "cbElasticsearch.Document.MissingIdentifierException",
				message = "An `id` value must be provided in the method arguments or the variables scope to run the get() method"
			);
		}

		var args = {
			"index" : variables.index,
			"type"  : !isNull( variables.type ) ? variables.type : javacast( "null", 0 ),
			"id"    : variables.id
		};

		return getClient().get( argumentCollection = args );
	}

	/**
	 * Deletes the currently active document
	 *
	 * @return 	a boolean denoting whether the document was deleted
	 **/
	boolean function delete(){
		if ( isNull( variables.id ) || isNull( variables.index ) ) {
			throw(
				type    = "cbElasticsearch.Document.MissingIdentifierException",
				message = "An `id` and index value must be available to delete a document "
			);
		}

		return getClient().delete( this );
	}


	/**
	 * Returns a new Document instance
	 * @index 		string		the index name
	 * @type 		string 		the index type
	 * @properties 	struct 		the structural representation of the document
	 **/
	public Document function new(
		string index,
		string type,
		struct properties = {}
	){
		reset();

		if ( structKeyExists( arguments, "index" ) ) {
			variables.index = arguments.index;
		}

		if ( structKeyExists( arguments, "type" ) ) {
			variables.type = arguments.type;
		}

		// we need to duplicate so that we can remove any passed `_id` key
		variables.memento = duplicate( arguments.properties );

		if ( structKeyExists( variables.memento, "_id" ) ) {
			variables.id = variables.memento[ "_id" ];
			structDelete( variables.memento, "_id" );
		}

		return this;
	}

	/**
	 * Populates an existing document object
	 * @properties 	struct 		the structural representation of the document
	 **/
	public Document function populate( required struct properties ){
		if ( isNull( variables.memento ) ) {
			variables.memento = {};
		}

		structAppend(
			variables.memento,
			duplicate( arguments.properties ),
			true
		);

		if ( structKeyExists( variables.memento, "_id" ) ) {
			setId( variables.memento[ "_id" ] );
			structDelete( variables.memento, "_id" );
		}

		return this;
	}


	/**
	 * Sets a key value within the current document
	 * @name 	string 		the key name
	 * @value 	string 		the key value
	 **/
	public Document function setValue( required string name, required any value ){
		variables.memento[ arguments.name ] = arguments.value;
		return this;
	}

	/**
	 * Gets a key value within the current document
	 * @key 		string 		the key to search
	 * @return   any|null 	returns null if the key does not exist in the current document
	 **/
	public any function getValue( required string key, any default ){
		// null return if the key does not exist
		if ( !structKeyExists( variables.memento, arguments.key ) && isNull( arguments.default ) ) {
			return;
		} else if ( !structKeyExists( variables.memento, arguments.key ) && !isNull( arguments.default ) ) {
			return arguments.default;
		} else {
			return variables.memento[ arguments.key ];
		}
	}


	/**
	 * Convenience method for a flattened struct of the memento
	 * @includeKey 	boolean 	Whether to include the document key in the returned packet
	 **/
	public struct function getDocument( boolean includeKey = false ){
		var documentObject = duplicate( variables.memento );

		if ( arguments.includeKey && !isNull( variables.id ) ) {
			documentObject[ "_id" ] = variables.id;
		}

		return documentObject;
	}

	/**
	 * Adds a parameter for the document save
	 */
	public Document function addParam( required string key, required any value ){
		// pipelines cannot be url escaped or they will not be found
		if ( key != "pipeline" ) {
			arguments.value = urlEncodedFormat( arguments.value );
		}
		variables.params[ key ] = arguments.value;
		return this;
	}

	/**
	 * Returns the JSON string of the document object
	 * @includeKey 	boolean 	Whether to include the document key in the returned packet
	 **/
	public string function toString( boolean includeKey = false ){
		return serializeJSON(
			getDocument( argumentCollection = arguments ),
			false,
			listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
		);
	}

}
