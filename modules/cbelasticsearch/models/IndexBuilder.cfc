/**
*
* Elasticsearch Index Builder Object
*
* @package cbElasticsearch.models
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component
	accessors="true"
{
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

		variables.mappings 	= {};

		variables.aliases 	= {};

		variables.indexName = getConfig().get( "defaultIndex" );

		var nullDefaults = [ "settings" ];

		for( var nullable in nullDefaults ){
			if( !isNull( variables[ nullable ] ) ){
				variables[ nullable ] = javacast( "null", 0 );
			}
		}
	}

	/**
	* MappingBuilder provider
	**/
    MappingBuilder function getMappingBuilder() provider="MappingBuilder@cbElasticsearch"{}

	/**
	* Config provider
	**/
	Config function getConfig() provider="Config@cbElasticsearch"{}

	/**
	* Client provider
	**/
	Client function getClient() provider="Client@cbElasticsearch"{}

	/**
	* Persists the document to Elasticsearch
	**/
	function save(){
		return getClient().applyIndex( this );
	}

	/**
	* Deletes the index named in the configured builder
	**/
	function delete(){
		return getClient().deleteIndex( this.getIndexName() );
	}

	IndexBuilder function new( string name, any properties, struct settings){

        reset();

		if( !isNull( arguments.name ) ){

			variables.indexName = arguments.name;

		}

		if( !isNull( arguments.properties ) ){
            if ( isCustomFunction( arguments.properties ) || isClosure( arguments.properties ) ) {
                arguments.properties = arguments.properties( getMappingBuilder() );
            }
			for( var propName in arguments.properties ){
				switch( propName ){
					case "settings":{
						variables.settings = arguments.properties[ propName ];
						//ensure we cast our keys properly
						if( structKeyExists( variables.settings, "number_of_shards" ) ){
							variables.settings.number_of_shards = javacast( "int", variables.settings.number_of_shards );
						}
						if( structKeyExists( variables.settings, "number_of_replicas" ) ){
							variables.settings.number_of_replicas = javacast( "int", variables.settings.number_of_replicas );
						}
						break;
					}
					case "mappings":{
						variables.mappings = arguments.properties[ propName ];
						break;
					}
					case "aliases":{
						variables.aliases = arguments.properties[ propName ];
						break;
					}

					//we assume they are mappings if we are unable to find explicit keys
					default:{
						variables.mappings[ propName ] = arguments.properties[ propName ];
					}

				}
			}

        }
        if ( ! isNull( arguments.settings ) ) {
            for ( var key in arguments.settings ) {
                var value = arguments.settings[ key ];
                variables.settings[ key ] = value;
            }
            //ensure we cast our keys properly
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

		if( !isNull( variables.settings ) ){
			dsl[ "settings" ] = variables.settings;
		}

		if( !isNull( variables.indexName ) ){
			dsl[ "name" ] = variables.indexName;
		}

		if( !isNull( variables.aliases ) ){
			dsl[ "aliases" ] = variables.aliases;
		}

		if( !isNull( variables.type ) ){
			dsl[ "type" ] = variables.type;
		}

		if( !isNull( variables.mappings ) && !structIsEmpty( variables.mappings ) ){
			dsl[ "mappings" ] = variables.mappings;
		}

		return dsl;
	}

	string function getJSON(){

		return serializeJSON( getDSL(), false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false );
	}


}
