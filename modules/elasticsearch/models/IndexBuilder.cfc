component 
	accessors="true"
{
	property name="configObject" inject="Config@cbElasticsearch";

	// All of our index settings ( i.e. shards, replicas, etc )
	property name="settings";

	// Our index mappings ( i.e. typings and fields );
	property name="mappings";
	

	function onDIComplete(){
		variables.settings = {
			"number_of_shards"   : variables.configObject.get( "defaultIndexShards" ),
			"number_of_replicas" : veriables.configObject.get( "defaultIndexReplicas" )
		};
		variables.mappings = {}
	}

	IndexBuilder function new( required string name, struct properties){

	}

	IndexBuilder function param( required string name, required any value, type ){}


}