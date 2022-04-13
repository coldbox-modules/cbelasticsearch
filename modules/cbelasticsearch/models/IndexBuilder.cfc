/**
 *
 * Elasticsearch Index Builder Object
 *
 * @package cbElasticsearch.models
 * @author Jon Clausen <jclausen@ortussolutions.com>
 * @license Apache v2.0 <http: // www.apache.org / licenses/>
 *
 */
component accessors="true" {

	// The name of our index
	property name="indexName";

	// The type declaration of our index - used for mapping
	property name="type";

	// All of our index settings ( i.e. shards, replicas, etc )
	property name="settings";

	// Our index mappings ( i.e. typings and fields );
	property name="mappings";

	// Our index aliases
	property name="aliases";


	function onDIComplete(){
		reset();
	}

	function reset(){
		variables.settings = {
			"number_of_shards"   : javacast( "int", getConfig().get( "defaultIndexShards" ) ),
			"number_of_replicas" : javacast( "int", getConfig().get( "defaultIndexReplicas" ) )
		};

		variables.mappings = {};

		variables.aliases = {};

		variables.indexName = getConfig().get( "defaultIndex" );
	}

	/**
	 * MappingBuilder provider
	 **/
	MappingBuilder function getMappingBuilder() provider="MappingBuilder@cbElasticsearch"{
	}

	/**
	 * Config provider
	 **/
	Config function getConfig() provider="Config@cbElasticsearch"{
	}

	/**
	 * Client provider
	 **/
	Client function getClient() provider="Client@cbElasticsearch"{
	}

	/**
	 * Persists the document to Elasticsearch
	 **/
	function save(){
		return getClient().applyIndex( this );
	}

	/**
	 * Deletes the index named in the configured builder
	 *
	 * @indexName Specify an index name to delete, if not already populated from the indexBuilder.new() method.
	 **/
	function delete( string indexName ){
		if ( !isNull( arguments.indexName ) ) {
			setIndexName( arguments.indexName );
		}
		return getClient().deleteIndex( this.getIndexName() );
	}

	/**
	 * Create a new index
	 *
	 * @name 		{String}	Index name. Defaults to the default index set in configuration.
	 * @properties 	{Struct}	Index mapping. Defines the fields and types used in the index.
	 * @settings 	{Struct}	Key/value struct of index settings such as `number_of_shards`.
	 */
	IndexBuilder function new( string name, any properties, struct settings ){
		reset();

		return this.populate( argumentCollection = arguments );
	}

	/**
	 * Update an existing index
	 *
	 * @name 		{String}	Index name. Defaults to the default index set in configuration.
	 * @properties 	{Struct}	Index mapping. Defines the fields and types used in the index.
	 * @settings 	{Struct}	Key/value struct of index settings such as `number_of_shards`.
	 */
	boolean function patch( string name, any properties, struct settings ){
		reset();

		return this.populate( argumentCollection = arguments ).save();
	}

	IndexBuilder function populate( string name, any properties, struct settings ){
		reset();

		if ( !isNull( arguments.name ) ) {
			variables.indexName = arguments.name;
		}

		if ( !isNull( arguments.properties ) ) {
			if ( isCustomFunction( arguments.properties ) || isClosure( arguments.properties ) ) {
				arguments.properties = arguments.properties( getMappingBuilder() );
			}
			for ( var propName in arguments.properties ) {
				switch ( propName ) {
					case "settings": {
						for ( var key in arguments.properties[ propName ] ) {
							variables.settings[ key ] = arguments.properties[ propName ][ key ];
						}
						// ensure we cast our keys properly
						if ( structKeyExists( variables.settings, "number_of_shards" ) ) {
							variables.settings.number_of_shards = javacast(
								"int",
								variables.settings.number_of_shards
							);
						}
						if ( structKeyExists( variables.settings, "number_of_replicas" ) ) {
							variables.settings.number_of_replicas = javacast(
								"int",
								variables.settings.number_of_replicas
							);
						}
						break;
					}
					case "mappings": {
						variables.mappings = arguments.properties[ propName ];
						break;
					}
					case "aliases": {
						variables.aliases = arguments.properties[ propName ];
						break;
					}

					// we assume they are mappings if we are unable to find explicit keys
					default: {
						variables.mappings[ propName ] = arguments.properties[ propName ];
					}
				}
			}
		}
		if ( !isNull( arguments.settings ) ) {
			for ( var key in arguments.settings ) {
				var value                 = arguments.settings[ key ];
				variables.settings[ key ] = value;
			}
			// ensure we cast our keys properly
			if ( structKeyExists( variables.settings, "number_of_shards" ) ) {
				variables.settings.number_of_shards = javacast( "int", variables.settings.number_of_shards );
			}
			if ( structKeyExists( variables.settings, "number_of_replicas" ) ) {
				variables.settings.number_of_replicas = javacast( "int", variables.settings.number_of_replicas );
			}
		}

		return this;
	}

	struct function getDSL(){
		var dsl = {};

		if ( !isNull( variables.settings ) ) {
			dsl[ "settings" ] = variables.settings;
		}

		if ( !isNull( variables.indexName ) ) {
			dsl[ "name" ] = variables.indexName;
		}

		if ( !isNull( variables.aliases ) ) {
			dsl[ "aliases" ] = variables.aliases;
		}

		if ( !isNull( variables.type ) ) {
			dsl[ "type" ] = variables.type;
		}

		if ( !isNull( variables.mappings ) && !structIsEmpty( variables.mappings ) ) {
			dsl[ "mappings" ] = variables.mappings;
		}

		return dsl;
	}

	string function getJSON(){
		return serializeJSON(
			getDSL(),
			false,
			listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false
		);
	}

}
