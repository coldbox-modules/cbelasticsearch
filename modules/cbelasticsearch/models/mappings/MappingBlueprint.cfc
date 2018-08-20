/**
*
* Elasticsearch Mapping Blueprint Object
*
* @package cbElasticsearch.models.mappings
* @author Eric Peterson <eric@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component
	accessors="true"
{

    property name="builder";
    property name="properties";

    function init() {
        variables.properties = [];
        return this;
    }

    function text( name ) {
        var mapping = variables.builder.newSimpleMapping( name, "text" );
        variables.properties.append( mapping );
        return mapping;
    }

    function keyword( name ) {
        var mapping = variables.builder.newSimpleMapping( name, "keyword" );
        variables.properties.append( mapping );
        return mapping;
    }

    function long( name ) {
        var mapping = variables.builder.newSimpleMapping( name, "long" );
        variables.properties.append( mapping );
        return mapping;
    }

    function integer( name ) {
        var mapping = variables.builder.newSimpleMapping( name, "integer" );
        variables.properties.append( mapping );
        return mapping;
    }

    function short( name ) {
        var mapping = variables.builder.newSimpleMapping( name, "short" );
        variables.properties.append( mapping );
        return mapping;
    }

    function byte( name ) {
        var mapping = variables.builder.newSimpleMapping( name, "byte" );
        variables.properties.append( mapping );
        return mapping;
    }

    function double( name ) {
        var mapping = variables.builder.newSimpleMapping( name, "double" );
        variables.properties.append( mapping );
        return mapping;
    }

    function float( name ) {
        var mapping = variables.builder.newSimpleMapping( name, "float" );
        variables.properties.append( mapping );
        return mapping;
    }

    function halfFloat( name ) {
        var mapping = variables.builder.newSimpleMapping( name, "half_float" );
        variables.properties.append( mapping );
        return mapping;
    }

    function scaledFloat( name, factor ) {
        var mapping = variables.builder.newSimpleMapping( name, "scaled_float" );
        mapping.scalingFactor( factor );
        variables.properties.append( mapping );
        return mapping;
    }

    function object( name, callback ) {
        var mapping = variables.builder.newObjectMapping( name, callback );
        variables.properties.append( mapping );
        return mapping;
    }

    function partial( name, definition ) {
        definition = normalizePartialDefinition( definition );
        var mapping = definition( variables.builder.newBlueprint() );
        if ( ! isNull( name ) ) {
            mapping.setName( name );
        }
        variables.properties.append( mapping );
        return mapping;
    }

    function toDSL() {
        return {
            "properties" = variables.properties.reduce( function( acc, prop ) {
                acc[ prop.getName() ] = prop.toDSL();
                return acc;
            }, {} )
        };
    }

    private function normalizePartialDefinition( definition ) {
        if ( isSimpleValue( definition ) ) {
            return variables.builder.resolveWireBoxMapping( definition ).getPartial;
        }

        if ( isCustomFunction( definition ) || isClosure( definition ) ) {
            return definition;
        }

        return definition.getPartial;
    }

}
