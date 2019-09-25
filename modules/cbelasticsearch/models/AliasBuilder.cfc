component accessors="true" {

    property name="action";
    property name="indexName";
    property name="aliasName";

    function add( required string indexName, required string aliasName ) {
        arguments.action = "add";
        return new( argumentCollection = arguments );
    }

    function remove( required string indexName, required string aliasName ) {
        arguments.action = "remove";
        return new( argumentCollection = arguments );
    }

    function new(
        required string action,
        required string indexName,
        required string aliasName
    ) {
        setAction( arguments.action );
        setIndexName( arguments.indexName );
        setAliasName( arguments.aliasName );
        return this;
    }

}
