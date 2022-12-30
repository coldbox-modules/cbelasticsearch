component {
    
    function up( searchClient ) {
        searchClient.getIndices();
    }

    function down( searchClient ) {
        
    }

}
