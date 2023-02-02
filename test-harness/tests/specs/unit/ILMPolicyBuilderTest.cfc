component extends="coldbox.system.testing.BaseTestCase"{
    this.loadColdbox = true;

    function beforeAll(){
        super.beforeAll();
        variables.client = getWirebox().getInstance( "Client@cbelasticsearch" );
    }

    function afterAll(){
        super.afterAll();
    }

    function run(){
        describe( "ILMPolicy Object Tests", function(){
            
            beforeEach( function(){
                variables.model = getWirebox().getInstance( "ILMPolicyBuilder@cbElasticSearch" );
                variables.testPolicyName = "cbelasticsearch-ilm-object-policy";
            } );

            afterEach( function(){
                try{
                    variables.client.deleteILMPolicy( testPolicyName );
                } catch( any e ){}
            } );

            it( "Can create a basic ILM policy", function(){
                model.new( testPolicyName )
                        .hotPhase(
                            rollover="10mb"
                        ).warmPhase(
                            age = "1d"
                        )
                        .withDeletion(
                            age = "2d"
                        ).save();
                expect( variables.client.getILMPolicy( testPolicyName ) ).toBeStruct().toHaveKey( testPolicyName );
            } );

            it( "Can modify an existing ILM policy", function(){
                
                expect(	function(){
                    varaibles.client.getILMPolicy( textPolicyName );
                } ).toThrow();
                
                model.new( testPolicyName )
                        .hotPhase(
                            rollover="10mb"
                        ).warmPhase(
                            age = "1d"
                        )
                        .withDeletion(
                            age = "2d"
                        ).save();
                        

                model.hotPhase( rollover="35mb" ).save();

                var policy = variables.client.getILMPolicy( testPolicyName );

                expect( policy ).toBeStruct().toHaveKey( testPolicyName );
                expect( policy[ testPolicyName ] ).toHaveKey( "version" );
                expect( policy[ testPolicyName ]. version ).toBe( 2 );

            } );

            it( "Will throw and error if the age argument is not provided in required steps", function(){
                expect(	function(){
                    variables.model.new( testPolicyName ).warmPhase();
                } ).toThrow( "cbElasticsearch.ILMPolicy.InvalidPolicyException" );
    
                expect(	function(){
                    variables.model.new( testPolicyName ).coldPhase();
                } ).toThrow( "cbElasticsearch.ILMPolicy.InvalidPolicyException" );
   
                expect(	function(){
                    variables.model.new( testPolicyName ).withDeletion();
                } ).toThrow( "cbElasticsearch.ILMPolicy.InvalidPolicyException" );
   
            } );

            it( "Can create a complex policy for all phases", function(){
                var createdPolicy = model.new( testPolicyName )
                        .hotPhase(
                            rollover="10mb",
                            priority=100,
                            shards=3,
                            downsample="1m"
                        ).warmPhase(
                            age = 1,
                            priority = 50,
                            shards = 1,
                            downsample = "1h",
                            allocate = 0,
                            readOnly = true
                        ).coldPhase(
                            age = 2,
                            priority = 50,
                            downsample = "2h",
                            allocate = 0,
                            readOnly = true
                        )
                        .withDeletion(
                            age = "4d",
                            deleteSnapshot = false
                        ).save();
                var result = variables.client.getILMPolicy( testPolicyName );
                expect( result ).toBeStruct().toHaveKey( testPolicyName );
                var phases = result[ testPolicyName ].policy.phases;
                var modelPhases = model.getDSL().phases;
                debug( modelPhases );
                modelPhases.keyArray().each(
                    function( phase ){
                        expect( phases[ phase ].keyArray().len() ).toBeGTE( modelPhases[ phase ].keyArray().len() );
                    }
                );
            } )
        } );
    }
}