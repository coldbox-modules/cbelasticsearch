/**
*
* Elasticsearch Object Mapping Object
*
* @package cbElasticsearch.models.mappings
* @author Eric Peterson <eric@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component extends="AbstractMapping" accessors="true" {

    property name="callback";

    function toDSL() {
        var result = variables.builder.create( callback );
        result[ "type" ] = getType();
        return result;
    }

}
