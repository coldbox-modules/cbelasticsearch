component accessors="true" singleton{
    property name="jLoader" inject="loader@cbjavaloader";
    property name="streamBuilder" inject="StreamBuilder@cbstreams";

    /**
     * Ensures a CF native struct is returned ( allowing for dot-notation )
     *
     * @memento A struct to ensure
     */
    function ensureNativeStruct( required struct memento ){
        // deserialize/serialize JSON is currently the only way to to ensure deeply nested items are converted without deep recursion 
        return deserializeJSON( serializeJSON( memento, false, listFindNoCase( "Lucee", server.coldfusion.productname ) ? "utf-8" : false ) );

    }

    /**
     * Creates a new java.util.HashMap with an optional struct to populate
     * 
     * @memento  a struct to populate the memento with
     */
    function newHashMap( struct memento ){
        var map = variables.jLoader.create( "java.util.HashMap" ).init();

        if( !isNull( arguments.memento ) ){
            map.putAll( ensureBooleanCasting( arguments.memento ) );
            for( var key in map ){
                if( isStruct( map[ key ] ) && !isInstanceOf( map[ key ], "java.util.HashMap" ) ){
                    map[ key ] = newHashMap( ensureBooleanCasting( map[ key ] ) );
                } else if( isArray( map[ key ] ) ){
                    map[ key ].each( function( item, index ){
                        if( isStruct( item ) && !isInstanceOf( item, "java.util.HashMap" ) ){
                            map[ key ][ index ] = newHashMap( ensureBooleanCasting( item ) );
                        }
                    } );
                }
                
            }
            
        }

        return map;
    }

    /**
    * Workaround for Adobe 2018 metadata mutation bug with GSON: https://tracker.adobe.com/#/view/CF-4206423
    * @deprecated   As soon as the bug above is fixed
    **/
    any function ensureBooleanCasting( required any memento ){
        if( isArray( memento ) ){
            memento.each( function( item ){ ensureBooleanCasting( item ); } );
        } else if( isStruct( memento ) ){
            memento.keyArray().each( function( key ){
                if( !isNull( memento[ key ] ) && !isNumeric( memento[ key ] ) && isBoolean( memento[ key ] ) ){
                    memento[ key ] = javacast( "boolean", memento[ key ] );
                } else if( !isSimpleValue( memento[ key ] ) ){
                    ensureBooleanCasting( memento[ key ] );
                }
            } );
        }
        return memento;
    }
}