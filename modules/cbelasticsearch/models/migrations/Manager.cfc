component {

	property name="wirebox" inject="wirebox";
	property name="migrationsIndex" default=".cfmigrations";

	public Manager function init(){
		for ( var key in arguments ) {
			if ( !isNull( arguments[ key ] ) ) {
				variables[ key ] = arguments[ key ];
			}
		}
		return this;
	}

	public boolean function isReady(){
		return wirebox.getInstance( "Client@cbelasticsearch" ).indexExists( variables.migrationsIndex );
	}

	/**
	 * Performs the necessary routines to setup the migration manager for operation
	 */
	public void function install(){
		if ( !isReady() ) {
			wirebox
				.getInstance( "IndexBuilder@cbelasticsearch" )
				.new(
					name       = variables.migrationsIndex,
					properties = {
						"_doc" : {
							"properties" : {
								"name"         : { "type" : "keyword" },
								"migrationRan" : { "type" : "date", "format" : "date_time_no_millis" }
							}
						}
					}
				)
				.save();
		}
	}

	/**
	 * Uninstalls the migrations schema
	 */
	public void function uninstall(){
		wirebox.getInstance( "Client@cbelasticsearch" ).deleteIndex( variables.migrationsIndex );
	}

	/**
	 * Not implemented due to the cross-index nature of Elasticsearch
	 */
	public void function reset(){
	}

	/**
	 * Finds all processed migrations
	 */
	array function findProcessed(){
		var searchBuilder = wirebox.getInstance( "SearchBuilder@cbelasticsearch" ).new( variables.migrationsIndex );
		searchBuilder
			.setQuery( { "match_all" : {} } )
			.setSourceIncludes( [ "name", "migrationRan" ] )
			.setMaxRows( searchBuilder.count() )
			.sort( "migrationRan desc" );
		return searchBuilder
			.execute()
			.getHits()
			.map( function( hit ){
				return hit.getMemento().name;
			} );
	}


	/**
	 * Determines whether a migration has been run
	 *
	 * @componentName The component to inspect
	 */
	boolean function isMigrationRan( string componentName ){
		return !!findProcessed().find( function( processed ){
			return processed == componentName;
		} );
	}

	/**
	 * Logs a migration as completed
	 *
	 * @direction  Whether to log it as up or down
	 * @componentName The component name to log
	 */
	private void function logMigration( string direction, string componentName ){
		if ( arguments.direction == "down" ) {
			variables.wirebox
				.getInstance( "Client@cbelasticsearch" )
				.deleteByQuery(
					wirebox
						.getInstance( "SearchBuilder@cbelasticsearch" )
						.new( variables.migrationsIndex )
						.term( "name", arguments.componentName )
				);
		} else {
			var formatter = createObject( "java", "java.text.SimpleDateFormat" ).init( "yyyy-MM-dd'T'HH:mm:ssXXX" );
			wirebox
				.getInstance( "Document@cbelasticsearch" )
				.new(
					index      = variables.migrationsIndex,
					properties = {
						"name"         : arguments.componentName,
						"migrationRan" : formatter.format( now() ).replace( "Z", "+00:00" )
					}
				)
				.save( true );
		}
	}


	/**
	 * Runs a single migration
	 *
	 * @direction The direction for which to run the available migrations — `up` or `down`.
	 * @migrationStruct A struct containing the meta of the migration to be run
	 * @postProcessHook  A callback to run after running each migration. Defaults to an empty function.
	 * @preProcessHook  A callback to run before running each migration. Defaults to an empty function.
	 */
	public void function runMigration(
		required string direction,
		required struct migrationStruct,
		function postProcessHook,
		function preProcessHook
	){
		var closure = function(){
		};
		param arguments.preProcessHook  = closure;
		param arguments.postProcessHook = closure;

		install();

		var migrationRan = isMigrationRan( migrationStruct.componentName );

		if ( migrationRan && direction == "up" ) {
			throw( "Cannot run a migration that has already been ran." );
		}

		if ( !migrationRan && direction == "down" ) {
			throw( "Cannot rollback a migration if it hasn't been ran yet." );
		}

		var migration = wirebox.getInstance( migrationStruct.componentPath );

		var searchClient = wirebox.getInstance( "Client@cbelasticsearch" );

		preProcessHook( migrationStruct );

		invoke( migration, direction, [ searchClient ] );

		logMigration( direction, migrationStruct.componentName );

		postProcessHook( migrationStruct );
	}

	/**
	 * Runs a single seed
	 *
	 * @invocationPath the component invocation path for the seed
	 */
	public void function runSeed( required string invocationPath ){
		var seeder       = wirebox.getInstance( arguments.invocationPath );
		var searchClient = wirebox.getInstance( "Client@cbelasticsearch" );
		invoke(
			seeder,
			"run",
			[
				searchClient,
				wirebox.getInstance( "MockData@mockdatacfc" )
			]
		);
	}

}
