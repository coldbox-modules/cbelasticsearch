/**
*
* Elasticsearch Simple Mapping Object
*
* @package cbElasticsearch.models.mappings
* @author Eric Peterson <eric@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component
    extends="AbstractMapping"
	accessors="true"
{

    function toDSL() {
        var dsl = {
            "type" = variables.type
        };
        structAppend( dsl, variables.parameters );
        return dsl;
    }

}
