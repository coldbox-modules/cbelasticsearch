component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

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
					"foo"          : "bar",
					"baz"          : { "foo" : "bar" },
					"numeric"      : 1,
					"booleanArray" : [
						{ "foo" : true },
						{ "foo" : false },
						{ "foo" : "yes" },
						{ "foo" : "no" }
					]
				};
				var hashMap = variables.model.newHashMap( ref );

				expect( function(){
					var bar = hashMap.baz;
				} ).toThrow();
				expect( function(){
					var bar = hashMap[ "baz" ].foo;
				} ).toThrow();

				debug( hashMap );

				var nativeStruct = variables.model.ensureNativeStruct( hashMap );

				debug( nativeStruct );

				expect( nativeStruct.foo ).toBe( "bar" );
				expect( nativeStruct.baz ).toBeStruct();
				expect( nativeStruct.baz.foo ).toBe( "bar" );
			} );

			it( "tests newHashMap with no arguments", function(){
				expect( getMetadata( variables.model.newHashMap() ).name ).toBe( "java.util.HashMap" );
			} );

			it( "tests newHashMap with a nested struct and arrays", function(){
				var ref = {
					"foo"     : "bar",
					"baz"     : { "foo" : "bar" },
					"bazooms" : [ { "foo" : "bar" }, { "foo" : "baz" } ]
				};
				var hashMap = variables.model.newHashMap( ref );

				expect( getMetadata( hashMap ).name ).toBe( "java.util.HashMap" );

				expect( function(){
					var baz = hashMap.baz;
				} ).toThrow();

				expect( function(){
					var baz = hashMap[ "baz" ].foo;
				} ).toThrow();

				expect( hashMap[ "foo" ] ).toBe( "bar" );
				expect( hashMap[ "baz" ][ "foo" ] ).toBe( "bar" );
				for ( var zoom in hashMap[ "bazooms" ] ) {
					expect( getMetadata( zoom ).name ).toBe( "java.util.HashMap" );
				}
			} );

			it( "tests handleResponseError with a simple error string", function(){
				var mockResponse = getMockBox().createMock( className = "Hyper.models.HyperResponse" );

				var mockError = serializeJSON( { "error" : "Incorrect HTTP method for uri [/myIndex/_doc] and method [PUT], allowed: [POST]" } );
				mockResponse.$( "getData", mockError );
				mockResponse.$( "getStatusCode", 400 );

				expect( function(){
					variables.model.handleResponseError( mockResponse );
				} ).toThrow( "cbElasticsearch.invalidRequest" );
			} );

			it( "tests handleResponseError with an error.reason struct", function(){
				var mockResponse = getMockBox().createMock( className = "Hyper.models.HyperResponse" );

				var mockError = serializeJSON( {
					"error" : {
						"reason" : "This is a test of the nested error.reason exception format.",
						"type"   : "BadDocument"
					},
					"status" : 400
				} );
				mockResponse.$( "getData", mockError );
				mockResponse.$( "getStatusCode", 400 );

				expect( function(){
					variables.model.handleResponseError( mockResponse );
				} ).toThrow( "cbElasticsearch.native.BadDocument" );
			} );
		} );
	}

}
