component singleton {

    function getPartial( mapping ) {
        return mapping.object( "user", function( mapping ) {
            mapping.integer( "age" );
            mapping.object( "name", function( mapping ) {
                mapping.text( "first" );
                mapping.text( "last" );
            } );
        } );
    }

}
