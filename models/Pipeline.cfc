component accessors="true" threadSafe {

	property name="Util" inject="Util@cbelasticsearch";

	/**
	 * The identifier of the pipeline
	 */
	property name="id";

	/**
	 * Description
	 */
	property name="description";

	/**
	 * Version - not used internally by elasticsearch
	 */
	property name="version";

	/**
	 * The array of processors used in this pipeline
	 */
	property name="processors" type="array";

	/**
	 * Provider for the client
	 */
	cbElasticsearch.models.Client function getClient() provider="HyperClient@cbelasticsearch"{
	}


	cbElasticsearch.models.Pipeline function init( struct definition ){
		variables.description = "";
		variables.processors  = [];

		return !isNull( arguments.definition ) ? this.new( definition ) : this;
	}


	cbElasticsearch.models.Pipeline function new( struct definition ){
		structAppend( variables, definition, true );

		return this;
	}

	cbElasticsearch.models.Pipeline function addProcessor( required struct processor ){
		variables.processors.append( processor );
		return this;
	}

	struct function getDSL(){
		var dsl = {
			"description" : variables.description,
			"processors"  : variables.processors
		};

		if ( !isNull( variables.version ) ) {
			dsl[ "version" ] = variables.version;
		}

		return dsl;
	}

	string function getJSON(){
		return Util.toJSON( getDSL() );
	}

	any function save(){
		return getClient().applyPipeline( this );
	}

}
