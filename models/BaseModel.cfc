/**
 *
 * Base Model for Fluent Request Overrides
 *
 * Provides a foundation for builder and model objects to support per-request
 * configuration overrides via fluent method chaining. All builder classes
 * (IndexBuilder, SearchBuilder, AliasBuilder, Document, Pipeline, etc.) extend
 * this component to inherit request override capabilities.
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
            var args = [];
            if( !isNull( arguments[ 2 ] ) ) {
                args = arguments[ 2 ].reduce( function( acc, key, val ){
                    acc.append( val );
                    return acc;
                }, [] );
            }
            variables.requestOverrides[ lCase( mid( methodName, 5 ) ) ] = args;
            return this;
        }
        // For all other missing methods, raise a proper missing-method exception
 		throw(
 			type    = "MissingMethodException",
 			message = "No such method found for #methodName# on #getMetadata( this ).name#.",
 			detail  = "Use with#methodName# to set default values for request overrides on this model."
 		);
    }
}
