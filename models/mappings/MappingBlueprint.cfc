/**
 *
 * ElasticSearch Mapping Blueprint Object
 *
 * @package cbElasticsearch.models.mappings
 * @author  Eric Peterson <eric@ortussolutions.com>
 * @license Apache v2.0 <http: // www.apache.org / licenses/>
 *
 */
component accessors="true" {

	property name="wirebox" inject="wirebox";
	property name="builder" inject="MappingBuilder@cbElasticSearch";

	property name="properties";

	function init(){
		variables.properties = [];
		return this;
	}

	function text( name ){
		var mapping = variables.builder.newSimpleMapping( name, "text" );
		variables.properties.append( mapping );
		return mapping;
	}

	function keyword( name ){
		var mapping = variables.builder.newSimpleMapping( name, "keyword" );
		variables.properties.append( mapping );
		return mapping;
	}

	function long( name ){
		var mapping = variables.builder.newSimpleMapping( name, "long" );
		variables.properties.append( mapping );
		return mapping;
	}

	function integer( name ){
		var mapping = variables.builder.newSimpleMapping( name, "integer" );
		variables.properties.append( mapping );
		return mapping;
	}

	function short( name ){
		var mapping = variables.builder.newSimpleMapping( name, "short" );
		variables.properties.append( mapping );
		return mapping;
	}

	function byte( name ){
		var mapping = variables.builder.newSimpleMapping( name, "byte" );
		variables.properties.append( mapping );
		return mapping;
	}

	function double( name ){
		var mapping = variables.builder.newSimpleMapping( name, "double" );
		variables.properties.append( mapping );
		return mapping;
	}

	function float( name ){
		var mapping = variables.builder.newSimpleMapping( name, "float" );
		variables.properties.append( mapping );
		return mapping;
	}

	function halfFloat( name ){
		var mapping = variables.builder.newSimpleMapping( name, "half_float" );
		variables.properties.append( mapping );
		return mapping;
	}

	function scaledFloat( name, factor ){
		var mapping = variables.builder.newSimpleMapping( name, "scaled_float" );
		mapping.scalingFactor( factor );
		variables.properties.append( mapping );
		return mapping;
	}

	function date( name ){
		var mapping = variables.builder.newSimpleMapping( name, "date" );
		variables.properties.append( mapping );
		return mapping;
	}

	function strictDate( name ){
		var mapping = variables.builder.newSimpleMapping( name, "date" );
		mapping.format( "strict_date" );
		variables.properties.append( mapping );
		return mapping;
	}

	function boolean( name ){
		var mapping = variables.builder.newSimpleMapping( name, "boolean" );
		variables.properties.append( mapping );
		return mapping;
	}

	function binary( name ){
		var mapping = variables.builder.newSimpleMapping( name, "binary" );
		variables.properties.append( mapping );
		return mapping;
	}

	function integerRange( name ){
		var mapping = variables.builder.newSimpleMapping( name, "integer_range" );
		variables.properties.append( mapping );
		return mapping;
	}

	function floatRange( name ){
		var mapping = variables.builder.newSimpleMapping( name, "float_range" );
		variables.properties.append( mapping );
		return mapping;
	}

	function longRange( name ){
		var mapping = variables.builder.newSimpleMapping( name, "long_range" );
		variables.properties.append( mapping );
		return mapping;
	}

	function doubleRange( name ){
		var mapping = variables.builder.newSimpleMapping( name, "double_range" );
		variables.properties.append( mapping );
		return mapping;
	}

	function dateRange( name ){
		var mapping = variables.builder.newSimpleMapping( name, "date_range" );
		variables.properties.append( mapping );
		return mapping;
	}

	function ipRange( name ){
		var mapping = variables.builder.newSimpleMapping( name, "ip_range" );
		variables.properties.append( mapping );
		return mapping;
	}

	function object( name, callback ){
		var mapping = variables.builder.newObjectMapping( name, callback );
		variables.properties.append( mapping );
		return mapping;
	}

	function nested( name, callback ){
		var mapping = variables.builder.newObjectMapping( name, callback );
		mapping.setType( "nested" );
		variables.properties.append( mapping );
		return mapping;
	}

	function geoPoint( name ){
		var mapping = variables.builder.newSimpleMapping( name, "geo_point" );
		variables.properties.append( mapping );
		return mapping;
	}

	function geoShape( name ){
		var mapping = variables.builder.newSimpleMapping( name, "geo_shape" );
		variables.properties.append( mapping );
		return mapping;
	}

	function ip( name ){
		var mapping = variables.builder.newSimpleMapping( name, "ip" );
		variables.properties.append( mapping );
		return mapping;
	}

	function completion( name ){
		var mapping = variables.builder.newSimpleMapping( name, "completion" );
		variables.properties.append( mapping );
		return mapping;
	}

	function tokenCount( name ){
		var mapping = variables.builder.newSimpleMapping( name, "token_count" );
		variables.properties.append( mapping );
		return mapping;
	}

	function percolator( name ){
		var mapping = variables.builder.newSimpleMapping( name, "percolator" );
		variables.properties.append( mapping );
		return mapping;
	}

	function join( name, relations ){
		var mapping = variables.builder.newSimpleMapping( name, "join" );
		mapping.relations( relations );
		variables.properties.append( mapping );
		return mapping;
	}

	function partial( name, definition ){
		definition  = normalizePartialDefinition( definition );
		var mapping = definition( variables.builder.newBlueprint() );
		if ( !isNull( name ) ) {
			mapping.setName( name );
		}
		variables.properties.append( mapping );
		return mapping;
	}

	function toDSL(){
		return {
			"properties" : variables.properties.reduce( function( acc, prop ){
				acc[ prop.getName() ] = prop.toDSL();
				return acc;
			}, {} )
		};
	}

	private function normalizePartialDefinition( definition ){
		if ( isSimpleValue( definition ) ) {
			return wirebox.getInstance( dsl = definition ).getPartial;
		}

		if ( isCustomFunction( definition ) || isClosure( definition ) ) {
			return definition;
		}

		return definition.getPartial;
	}

}
