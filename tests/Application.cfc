/**
* Copyright Since 2005 Ortus Solutions, Corp
* www.coldbox.org | www.luismajano.com | www.ortussolutions.com | www.gocontentbox.org
**************************************************************************************
*/
component{
	this.name = "A TestBox Runner Suite " & hash( getCurrentTemplatePath() );
	// any other application.cfc stuff goes below:
	this.sessionManagement = true;
	// Turn on/off white space managemetn
	this.whiteSpaceManagement = "smart";

	// any mappings go here, we create one that points to the root called test.
	this.mappings[ "/tests" ] = getDirectoryFromPath( getCurrentTemplatePath() );
	rootPath = REReplaceNoCase( this.mappings[ "/tests" ], "tests(\\|/)", "" );
	this.mappings[ "/root" ]   = rootPath;

	this.mappings[ "/hyper" ]           = rootPath & "modules/hyper";
	this.mappings[ "/cbelasticsearch" ] = rootPath & "modules/cbelasticsearch";
	this.mappings[ "/cbjavaloader" ]    = rootPath & "modules/cbjavaloader";
	this.mappings[ "/coldbox" ]         = rootPath & "coldbox";

	// COLDBOX STATIC PROPERTY, DO NOT CHANGE UNLESS THIS IS NOT THE ROOT OF YOUR COLDBOX APP
	COLDBOX_APP_ROOT_PATH = rootPath;
	// The web server mapping to this application. Used for remote purposes or static purposes
	COLDBOX_APP_MAPPING   = "root";
	// COLDBOX PROPERTIES
	COLDBOX_CONFIG_FILE 	 = "";
	// COLDBOX APPLICATION KEY OVERRIDE
	COLDBOX_APP_KEY 		 = "";

	// application start
	public boolean function onApplicationStart(){
		application.cbBootstrap = new coldbox.system.Bootstrap( COLDBOX_CONFIG_FILE, COLDBOX_APP_ROOT_PATH, COLDBOX_APP_KEY, COLDBOX_APP_MAPPING );
		application.cbBootstrap.loadColdbox();
		return true;
	}
	public void function onSessionStart(){
		application.cbBootStrap.onSessionStart();
	}

	public void function onSessionEnd( struct sessionScope, struct appScope ){
		arguments.appScope.cbBootStrap.onSessionEnd( argumentCollection=arguments );
	}

	public boolean function onMissingTemplate( template ){
		return application.cbBootstrap.onMissingTemplate( argumentCollection=arguments );
	}

	function onRequestStart( string targetPage ){
		setting requestTimeout="180";

		if( ! structKeyExists( application, "cbBootstrap" ) ){
			onApplicationStart();
		}
		// Process ColdBox Request
		application.cbBootstrap.onRequestStart( arguments.targetPage );
		
		// Clear out the previous framework objects so that the first spec with `loadColdbox` set to `true` will reload them
		if( structKeyExists( url, "persistColdbox" ) && !url.persistColdbox ){

			structDelete( application, "cbController" );
			structDelete( application, "wirebox" );

		}

	}

	public function onRequestEnd(string targetPage) {

		if( structKeyExists( URL, "reinitApp" ) ){
			applicationStop();
		}

	}
}
