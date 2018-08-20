component extends="coldbox.system.testing.BaseTestCase" {

	function run() {
		describe( "MappingBuilder", function() {
            beforeEach( function() {
                variables.builder = getBuilder();
            } );

            describe( "property types", function() {
                it( "text", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.text( "full_name" );
                    } );

                    var expected = {
                        "full_name" = {
                            "type" = "text"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "keyword", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.keyword( "tags" );
                    } );

                    var expected = {
                        "tags" = {
                            "type" = "keyword"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "long", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.long( "views" );
                    } );

                    var expected = {
                        "views" = {
                            "type" = "long"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "integer", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.integer( "bytes" );
                    } );

                    var expected = {
                        "bytes" = {
                            "type" = "integer"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "short", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.short( "year" );
                    } );

                    var expected = {
                        "year" = {
                            "type" = "short"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "byte", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.byte( "age" );
                    } );

                    var expected = {
                        "age" = {
                            "type" = "byte"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "double", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.double( "discount" );
                    } );

                    var expected = {
                        "discount" = {
                            "type" = "double"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "float", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.float( "tax" );
                    } );

                    var expected = {
                        "tax" = {
                            "type" = "float"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "halfFloat", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.halfFloat( "proprtion" );
                    } );

                    var expected = {
                        "proprtion" = {
                            "type" = "half_float"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "scaledFloat", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.scaledFloat( "price", 100 );
                    } );

                    var expected = {
                        "price" = {
                            "type" = "scaled_float",
                            "scaling_factor": 100
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "nested objects", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.keyword( "region" );
                        mapping.object( "manager", function( mapping ) {
                            mapping.integer( "age" );
                            mapping.object( "name", function( mapping ) {
                                mapping.text( "first" );
                                mapping.text( "last" );
                            } );
                        } );
                    } );

                    var expected = {
                        "region" = { "type" = "keyword" },
                        "manager" = {
                            "properties" = {
                                "age" = { "type" = "integer" },
                                "name" = {
                                    "properties" = {
                                        "first" = { "type" = "text" },
                                        "last" = { "type" = "text" }
                                    }
                                }
                            }
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );
            } );

            describe( "parameters", function() {
                it( "forwards on further method calls as parameters", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.text( "full_name" ).index( false );
                    } );

                    var expected = {
                        "full_name" = {
                            "type" = "text",
                            "index" = false
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "converts camelCase to snake_case", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.text( "full_name" ).indexPrefixes( {
                            "min_chars" = 1,
                            "max_chars" = 10
                        } );
                    } );

                    var expected = {
                        "full_name" = {
                            "type" = "text",
                            "index_prefixes" = {
                                "min_chars" = 1,
                                "max_chars" = 10
                            }
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "can set all parameters at once", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.text( "full_name" ).setParameters( {
                            "fielddata" = true,
                            "index_prefixes" = {
                                "min_chars" = 1,
                                "max_chars" = 10
                            }
                        } );
                    } );

                    var expected = {
                        "full_name" = {
                            "type" = "text",
                            "fielddata" = true,
                            "index_prefixes" = {
                                "min_chars" = 1,
                                "max_chars" = 10
                            }
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );
            } );
		} );
    }

    private function testCase( callback, expected ) {
        // var builder = getBuilder();
        // var dsl = callback( builder );
        // expect( dsl ).toBe( { "properties" = expected } );
    }

    private function getBuilder() {
        return getInstance( "MappingBuilder@cbElasticSearch" );
    }

}
