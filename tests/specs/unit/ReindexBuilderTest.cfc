component extends="coldbox.system.testing.BaseTestCase"{
    function beforeAll(){

        this.loadColdbox=true;

        setup();

        variables.model = getWirebox().getInstance( "Document@cbElasticSearch" );

        variables.testIndexName = lcase("cbElasticSearch-DocumentTests");

        variables.model.getClient().deleteIndex( variables.testIndexName );

        var indexSettings = {
                                "mappings":{
                                    "testdocs":{
                                        "_all"       : { "enabled": false },
                                        "properties" : {
                                            "title"      : {"type" : "text"},
                                            "createdTime": {
                                                "type"  : "date",
                                                "format": "date_time_no_millis"
                                            }
                                        }
                                    }
                                }
                            };

    getWirebox().getInstance( "IndexBuilder@cbElasticsearch" ).new(
                                            name=variables.testIndexName,
                                            properties=indexSettings
                                        ).save();

    }

    function afterAll(){

        variables.model.getClient().deleteIndex( variables.testIndexName );

        super.afterAll();
    }

    function run(){
        describe( "Performs cbElasticsearch ReindexBuilder tests", function(){
            
        } );
    }
}