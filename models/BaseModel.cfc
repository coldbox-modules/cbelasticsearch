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
    property name="requestOverrides" type="struct";

    public BaseModel function init(){
        variables.requestOverrides = {};
        return this;
    }

    public BaseModel function withRequestOverrides( struct overrides ){
        setRequestOverrides( arguments.overrides );
        return this;
    }

    public struct function getRequestOverrides(){
        return variables.requestOverrides ?: {};
    }

    /**
     * Handles any missing methods that start with "with" and adds the value to the requestOverrides struct for request configuration
      * Example: withTimeout( 1000 ) would set a default timeout of 1000ms on all requests created by this model
      *
      * @param methodName the name of the method being called
      * @param arguments the arguments passed to the method, where arguments[1] is expected to be the value to set for the default
      * @return returns the model instance for chaining
      */
    public BaseModel function onMissingMethod( string methodName, struct arguments ){
        if( left( methodName, 4 ) == "with" ){
            var defaultKey = lCase( mid( methodName, 5 ) );
            if( !isNull( arguments[ 2 ][ 1 ] ) ) {
                variables.requestOverrides[ defaultKey ] = arguments[ 2 ][ 1 ];
            }
            return this;
        }
        return this;
    }
}