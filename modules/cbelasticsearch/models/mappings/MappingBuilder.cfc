/**
*
* Elasticsearch Mapping Builder Object
*
* @package cbElasticsearch.models.mappings
* @author Eric Peterson <eric@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component singleton accessors="true" {

    property name="wirebox" inject="wirebox";

    function create( callback ) {
        var blueprint = newBlueprint();
        callback( blueprint );
        return blueprint.toDSL();
    }

    function newBlueprint() {
        return wirebox.getInstance( "MappingBlueprint@cbElasticSearch" );
    }

    function newSimpleMapping( name, type ) {
        var mapping = wirebox.getInstance( "SimpleMapping@cbElasticSearch" );
        mapping.setName( name );
        mapping.setType( type );
        return mapping;
    }

    function newObjectMapping( name, callback ) {
        var mapping = wirebox.getInstance( "ObjectMapping@cbElasticSearch" );
        mapping.setName( name );
        mapping.setCallback( callback );
        return mapping;
    }

}
