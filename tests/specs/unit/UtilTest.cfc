component extends="coldbox.system.testing.BaseTestCase"{
    function beforeAll(){
        this.loadColdbox=true;

        setup();

        variables.model = getWirebox().getInstance( "Util@cbElasticSearch" );

    }

    function afterAll(){

        super.afterAll();
    }

    function run(){
        describe( "Runs core util tests", function(){

            it( "tests ensureNativeStruct", function(){

                var ref = { 
                    "foo" : "bar", 
                    "baz" : { "foo" : "bar" },
                    "numeric" : 1,
                    "booleanArray" : [
                        {"foo" : true },
                        {"foo" : false },
                        {"foo" : "yes" },
                        {"foo" : "no" }
                    ]
                };
                var hashMap = variables.model.newHashMap( ref );
                
                expect( function(){
                    var bar = hashMap.baz;
                } ).toThrow();
                expect( function(){
                    var bar = hashMap["baz"].foo;
                } ).toThrow();

                debug( hashMap );
                
                var nativeStruct = variables.model.ensureNativeStruct( hashMap );

                debug( nativeStruct );

                expect( nativeStruct.foo ).toBe( "bar" );
                expect( nativeStruct.baz ).toBeStruct();
                expect( nativeStruct.baz.foo ).toBe( "bar" );


            });

            it( "tests newHashMap with no arguments", function(){

                expect( getMetaData( variables.model.newHashMap() ).name ).toBe( "java.util.HashMap" );
                
            });

            it( "tests newHashMap with a nested struct and arrays", function(){
                var ref = { 
                    "foo" : "bar", 
                    "baz" : { "foo" : "bar" } ,
                    "bazooms" : [
                        { "foo" : "bar" },
                        { "foo" : "baz" }
                    ]
                };
                var hashMap = variables.model.newHashMap( ref );

                expect( getMetaData( hashMap ).name ).toBe( "java.util.HashMap" );

                expect( function(){
                    var baz = hashMap.baz;
                } ).toThrow();

                expect( function(){
                    var baz = hashMap[ "baz" ].foo;
                } ).toThrow();

                expect( hashMap[ "foo" ] ).toBe( "bar" );
                expect( hashMap[ "baz" ][ "foo" ] ).toBe( "bar" );
                for( var zoom in hashMap[ "bazooms" ] ){
                    expect( getMetadata( zoom ).name ).toBe( "java.util.HashMap" );
                }

            });

            it( "tests ensureBooleanCasting", function(){
                
                var jLoader = variables.model.getJLoader();

                var settings = {
                    "mapping" : {
                        "ignore_malformed" = true
                    },
                    "numeric" : 1,
                    "booleanArray" : [
                        {"foo" : true },
                        {"foo" : false },
                        {"foo" : "yes" },
                        {"foo" : "no" }
                    ]
                };
                var gson = jLoader.create( "com.google.gson.Gson" );

                var currentClass = getMetadata( settings.mapping.ignore_malformed ).name;
                var expectedClass = "java.lang.Boolean";
                
                if( currentClass == 'coldfusion.runtime.CFBoolean' ){
                    var testConversion = deserialzeJSON( gson.toJSON( settings ) );
                    if( isStruct( testConvert.mapping.ignore_malformed ) ){
                        debug( "ACF Bug CF-4206423 is still open: https://tracker.adobe.com/##/view/CF-4206423" );
                    } else {
                        settings.mapping.ignore_malformed = "yes";
                    }
                } else {
                    settings.mapping.ignore_malformed = "yes";
                }

                variables.model.ensureBooleanCasting( settings );

                expect( getMetadata( settings.mapping.ignore_malformed ).name ).toBe( expectedClass );
                expect( settings.numeric ).toBeNumeric();
                settings.booleanArray.each( function( item ){
                    expect( getMetadata( item.foo ).name ).toBe( expectedClass );
                } );


            });

        } );

    }
}