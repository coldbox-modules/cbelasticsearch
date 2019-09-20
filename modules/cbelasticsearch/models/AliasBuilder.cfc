component accessors="true" {

    property name="type";
    property name="indexName";
    property name="aliasName";

    function add( required string indexName, required string aliasName ) {
        arguments.type = "add";
        return new( argumentCollection = arguments );
    }

    function remove( required string indexName, required string aliasName ) {
        arguments.type = "remove";
        return new( argumentCollection = arguments );
    }

    function new(
        required string type,
        required string indexName,
        required string aliasName
    ) {
        setType( arguments.type );
        setIndexName( arguments.indexName );
        setAliasName( arguments.aliasName );
        return this;
    }

}
