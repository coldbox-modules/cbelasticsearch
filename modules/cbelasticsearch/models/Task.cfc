/**
 *
 * Elasticsearch Task Object
 *
 * @package cbElasticsearch.models
 * @author Jon Clausen <jclausen@ortussolutions.com>
 * @license Apache v2.0 <http: // www.apache.org / licenses/>
 *
 */
component accessors="true" {

	// native tasks API properties
	property name="id";
	property name="node";
	property name="type";
	property name="status";
	property name="action";
	property name="cancellable";
	property name="description" default="";
	property name="requests_per_second";
	property name="start_time_in_millis";
	property name="running_time_in_nanos";
	property name="parent_task_id";
	property name="headers";
	property name="response";
	property name="error";
	property
		name   ="completed"
		type   ="boolean"
		default=false;

	// aggregates
	property name="runningTime";
	property name="startTime";

	public function populate( struct properties ){
		if ( arguments.keyExists( "properties" ) ) {
			if ( structKeyExists( arguments.properties, "error" ) ) {
				setError( arguments.properties.error );
			}
			if ( structKeyExists( arguments.properties, "task" ) ) {
				var taskProperties = arguments.properties.task;
				if ( structKeyExists( arguments.properties, "completed" ) ) {
					variables.completed = arguments.properties.completed;
				}
				if ( structKeyExists( arguments.properties, "response" ) ) {
					variables.response = arguments.properties.response;
				}
			} else {
				var taskProperties = arguments.properties;
			}

			// append matched name keys
			variables.append( taskProperties );

			// calculate our time
			if ( taskProperties.keyExists( "start_time_in_millis" ) )
				var epochDate = createDateTime( "1970", "01", "01", "00", "00", "00" );
			variables.startTime = dateAdd(
				"s",
				taskProperties.start_time_in_millis / 1000,
				epochDate
			);
			variables.runningTime = dateDiff(
				"s",
				dateAdd(
					"l",
					taskProperties.running_time_in_nanos / 1000000,
					variables.startTime
				),
				variables.startTime
			);
		}

		return this;
	}

	/**
	 * Client provider
	 **/
	Client function getClient() provider="Client@cbElasticsearch"{
	}

	public function getIdentifier(){
		if ( isNull( variables.node ) || isNull( variables.id ) ) {
			throw(
				type    = "cbElasticsearch.Task.UnknownNodeException",
				message = "An identifier for the task could not be constructed because either a node value or task id was not available"
			);
		}
		return variables.node & ":" & variables.id;
	}

	public boolean function isChildTask(){
		return !isNull( variables.parent_task_id );
	}

	public any function getParentTask(){
		return isChildTask() ? getClient().getTask( variables.parent_task_id ) : javacast( "null", 0 );
	}

	public any function refresh(){
		return getClient().getTask( getIdentifier(), this );
	}

	/**
	 * Returns the complete status of the task after a refresh
	 *
	 * @refresh    boolean      Whether to refresh the task
	 * @delay      numeric      The delay time in milliseconds - useful to slow down a while() loop
	 */
	public boolean function isComplete( boolean refresh = true, numeric delay = 0 ){
		if ( !variables.completed && arguments.refresh ) {
			if ( arguments.delay > 0 ) {
				sleep( arguments.delay );
			}
			// we need to scope this invocation or ACF throws an entity exception
			this.refresh();
		}
		return variables.completed;
	}

}
