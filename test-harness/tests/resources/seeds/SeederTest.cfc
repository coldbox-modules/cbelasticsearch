component{
    function run( searchClient, mockData ){
        searchClient.getIndices();
        mockData.mock(
            $num = 5
        );
    }
}