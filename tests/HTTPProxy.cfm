<cfscript>
if( !structKeyExists( url, "route" ) ){
	writeOutput( "Proxy route not defined in the URL scope. Could not continue." );
	abort;
}

/**
* Provides a proxy to the the application handlers for HTTP-based testing
**/
// In case bootstrap or controller are missing, perform a manual startup
if ( 
	!structKeyExists( application, "cbBootstrap" ) 
	||
	!structKeyExists( application, "cbController" )
	|| 	
	application.cbBootStrap.isfwReinit() )
{

	COLDBOX_APP_ROOT_PATH 	= expandPath( "/root" );
	COLDBOX_APP_MAPPING		= "";
	COLDBOX_CONFIG_FILE 	= COLDBOX_APP_ROOT_PATH & "config/Coldbox.cfc";
	//we need a separate app key so that we don't mess up the existing context of our test runner
	COLDBOX_APP_KEY 		= "WEAT-Test-Proxy";

	application.cbBootstrap = new coldbox.system.Bootstrap( 
														COLDBOX_CONFIG_FILE, 
														COLDBOX_APP_ROOT_PATH, 
														COLDBOX_APP_KEY, 
														COLDBOX_APP_MAPPING 
													);
	application.cbBootstrap.loadColdbox();
}

// Local Logging
if( 
	structKeyExists( application, "cbController")
	&& 
	application.cbController.getSetting( "environment" ) == "development" 
){
	this.ormsettings.logSQL = true;
}

// Process ColdBox Request
application.cbBootstrap.onRequestStart( "/index.cfm" & URL.route );
</cfscript>