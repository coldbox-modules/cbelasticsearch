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

                it( "date", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.date( "createdDate" );
                    } );

                    var expected = {
                        "createdDate" = {
                            "type" = "date"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "strictDate", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.strictDate( "publishedDate" );
                    } );

                    var expected = {
                        "publishedDate" = {
                            "type" = "date",
                            "format" = "strict_date"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "boolean", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.boolean( "isSubscribed" );
                    } );

                    var expected = {
                        "isSubscribed" = {
                            "type" = "boolean"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "binary", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.binary( "blob" );
                    } );

                    var expected = {
                        "blob" = {
                            "type" = "binary"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "integerRange", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.integerRange( "expectedAtendees" );
                    } );

                    var expected = {
                        "expectedAtendees" = {
                            "type" = "integer_range"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "floatRange", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.floatRange( "standardDeviation" );
                    } );

                    var expected = {
                        "standardDeviation" = {
                            "type" = "float_range"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "longRange", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.longRange( "averageViews" );
                    } );

                    var expected = {
                        "averageViews" = {
                            "type" = "long_range"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "doubleRange", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.doubleRange( "over_under" );
                    } );

                    var expected = {
                        "over_under" = {
                            "type" = "double_range"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "dateRange", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.dateRange( "timeframe" );
                    } );

                    var expected = {
                        "timeframe" = {
                            "type" = "date_range"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "ipRange", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.ipRange( "ip_allowlist" );
                    } );

                    var expected = {
                        "ip_allowlist" = {
                            "type" = "ip_range"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "object", function() {
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
                            "type" = "object",
                            "properties" = {
                                "age" = { "type" = "integer" },
                                "name" = {
                                    "type" = "object",
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

                it( "nested", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.nested( "name", function( mapping ) {
                            mapping.text( "first" );
                            mapping.text( "last" );
                        } );
                    } );

                    var expected = {
                        "name" = {
                            "type" = "nested",
                            "properties" = {
                                "first" = { "type" = "text" },
                                "last" = { "type" = "text" }
                            }
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "geoPoint", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.geoPoint( "location" );
                    } );

                    var expected = {
                        "location" = {
                            "type" = "geo_point"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "geoShape", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.geoShape( "location" );
                    } );

                    var expected = {
                        "location" = {
                            "type" = "geo_shape"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "ip", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.ip( "ip_address" );
                    } );

                    var expected = {
                        "ip_address" = {
                            "type" = "ip"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "completion", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.completion( "suggest" );
                    } );

                    var expected = {
                        "suggest" = {
                            "type" = "completion"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "tokenCount", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.tokenCount( "length" );
                    } );

                    var expected = {
                        "length" = {
                            "type" = "token_count"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "percolator", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.percolator( "query" );
                    } );

                    var expected = {
                        "query" = {
                            "type" = "percolator"
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );

                it( "join", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.join( "my_join_field", {
                            "question": [ "answer", "comment" ],
                            "answer": "vote"
                        } );
                    } );

                    var expected = {
                        "my_join_field" = {
                            "type" = "join",
                            "relations": {
                                "question": [ "answer", "comment" ],
                                "answer": "vote"
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

                it( "can add a single parameter", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.text( "full_name" ).addParameter(
                            "index_prefixes",
                            {
                                "min_chars" = 1,
                                "max_chars" = 10
                            }
                        );
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

                it( "can create multi-fields", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.text( "city" ).fields( function( mapping ) {
                            mapping.keyword( "raw" );
                        } );
                    } );

                    var expected = {
                        "city" = {
                            "type" = "text",
                            "fields": {
                                "raw" = {
                                    "type" = "keyword"
                                }
                            }
                        }
                    };

                    expect( actual ).toBe( { "properties" = expected } );
                } );
            } );

            describe( "partials", function() {
                it( "can use a callback", function() {
                    var partialFn = function( mapping ) {
                        return mapping.object( "user", function( mapping ) {
                            mapping.integer( "age" );
                            mapping.object( "name", function( mapping ) {
                                mapping.text( "first" );
                                mapping.text( "last" );
                            } );
                        } );
                    };

                    var actual = builder.create( function( mapping ) {
                        mapping.partial( "manager", partialFn );
                        mapping.partial( definition = partialFn );
                    } );

                    var expected = {
                        "manager" = {
                            "type" = "object",
                            "properties" = {
                                "age" = { "type" = "integer" },
                                "name" = {
                                    "type" = "object",
                                    "properties" = {
                                        "first" = { "type" = "text" },
                                        "last" = { "type" = "text" }
                                    }
                                }
                            }
                        },
                        "user" = {
                            "type" = "object",
                            "properties" = {
                                "age" = { "type" = "integer" },
                                "name" = {
                                    "type" ="object",
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

                it( "can use a wirebox dsl", function() {
                    var actual = builder.create( function( mapping ) {
                        mapping.partial( "manager", "tests.resources.UserPartial" );
                        mapping.partial( definition = "tests.resources.UserPartial" );
                    } );

                    var expected = {
                        "manager" = {
                            "type" = "object",
                            "properties" = {
                                "age" = { "type" = "integer" },
                                "name" = {
                                    "type" = "object",
                                    "properties" = {
                                        "first" = { "type" = "text" },
                                        "last" = { "type" = "text" }
                                    }
                                }
                            }
                        },
                        "user" = {
                            "type" = "object",
                            "properties" = {
                                "age" = { "type" = "integer" },
                                "name" = {
                                    "type" = "object",
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

                it( "can use a component with a getPartial methods", function() {
                    var userPartial = new tests.resources.UserPartial();

                    var actual = builder.create( function( mapping ) {
                        mapping.partial( "manager", userPartial );
                        mapping.partial( definition = userPartial );
                    } );

                    var expected = {
                        "manager" = {
                            "type" = "object",
                            "properties" = {
                                "age" = { "type" = "integer" },
                                "name" = {
                                    "type" = "object",
                                    "properties" = {
                                        "first" = { "type" = "text" },
                                        "last" = { "type" = "text" }
                                    }
                                }
                            }
                        },
                        "user" = {
                            "type" = "object",
                            "properties" = {
                                "age" = { "type" = "integer" },
                                "name" = {
                                    "type" = "object",
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
