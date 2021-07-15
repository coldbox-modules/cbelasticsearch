component extends="coldbox.system.testing.BaseTestCase" {

	this.loadColdbox = true;

	function beforeAll(){
		super.afterAll();
		setup();

        variables.searchClient = getWirebox().getInstance( "Client@cbelasticsearch" );
        variables.migrationsIndex = ".cfmigrations-testing";
        variables.model = new cbelasticsearch.models.migrations.Manager( migrationsIndex=variables.migrationsIndex );
        getWirebox().autowire( variables.model );
        if( variables.searchClient.indexExists( variables.migrationsIndex ) ){
            variables.searchClient.deleteIndex( variables.migrationsIndex );
        }
    }

    function run(){
        describe( "Migration service workflow tests", function(){
            
            it( "tests isReady method", function(){
                expect( variables.model.isReady() ).toBeFalse();
            } );

            it( "tests the install method", function(){
                variables.model.install();
                expect( variables.searchClient.indexExists( variables.migrationsIndex ) ).toBeTrue();
            } );

            it( "tests the isMigrationRan method", function(){
                expect( variables.model.isMigrationRan( "2021_07_15_150758_Test-Migration" ) ).toBeFalse();
            } );

            it( "tests the runMigration method", function(){
                var migrationStruct = {
                    "componentName" : "2021_07_15_150758_Test-Migration",
                    "componentPath" : "tests.resources.migrations.2021_07_15_150758_Test-Migration"
                };
                variables.model.runMigration( "up", migrationStruct );
                expect( variables.model.isMigrationRan( migrationStruct.componentName ) ).toBeTrue();
            } );

            it( "tests the findProcessed method", function(){
                var processed = variables.model.findProcessed();
                expect( processed ).toBeArray();
                processed.each( function( hit ){
                    expect( hit ).toBeStruct().toHaveKey( "name" ).toHaveKey( "migrationRan" );
                } );
            });

            it( "tests the runSeed method", function(){
                variables.model.runSeed( "tests.resources.seeds.SeederTest" );
            } );

            it( "tests the uninstall method", function(){
                variables.model.uninstall();
                expect( variables.searchClient.indexExists( variables.migrationsIndex ) ).toBeFalse();
            });

        } );
    }
}
