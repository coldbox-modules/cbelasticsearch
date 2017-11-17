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

	//example CF Mappings
	this.mappings[ "/cbElasticsearch" ] 	= rootPath & "modules/elasticsearch";
	this.mappings[ "/cbjavaloader" ] 	= rootPath & "modules/cbjavaloader";
	
	// any orm definitions go here.

	function onRequestStart(){
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