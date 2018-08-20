/**
*
* Elasticsearch Mapping Builder Object
*
* @package cbElasticsearch.models.mappings
* @author Eric Peterson <eric@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component
	accessors="true"
{
    property name="wirebox" inject="wirebox";

    function create( callback ) {
        var blueprint = newBlueprint();
        callback( blueprint );
        return blueprint.toDSL();
    }

    function newBlueprint() {
        var blueprint = wirebox.getInstance( "MappingBlueprint@cbElasticSearch" );
        blueprint.setBuilder( this );
        return blueprint;
    }

    function resolveWireBoxMapping( dsl ) {
        return wirebox.getInstance( dsl = dsl );
    }

    function newSimpleMapping( name, type ) {
        var mapping = wirebox.getInstance( "SimpleMapping@cbElasticSearch" );
        mapping.setName( name );
        mapping.setType( type );
        mapping.setBuilder( this );
        return mapping;
    }

    function newObjectMapping( name, callback ) {
        var mapping = wirebox.getInstance( "ObjectMapping@cbElasticSearch" );
        mapping.setName( name );
        mapping.setBuilder( this );
        mapping.setCallback( callback );
        return mapping;
    }

}
