component{
	
	variables.logStashSchema = {
        "_index" : "logstash-2016.10.11",
        "_type" : "log",
        "_id" : "AVe14gMjYMkU36o_eVtO",
        "_score" : 2.6390574,
        "_source" : {
          "request" : "/?flav=rss20",
          "agent" : "\"-\"",
          "geoip" : {
            "timezone" : "America/New_York",
            "ip" : "108.174.55.234",
            "latitude" : 42.9864,
            "continent_code" : "NA",
            "city_name" : "Buffalo",
            "country_code2" : "US",
            "country_name" : "United States",
            "dma_code" : 514,
            "country_code3" : "US",
            "region_name" : "New York",
            "location" : [
              -78.7279,
              42.9864
            ],
            "postal_code" : "14221",
            "longitude" : -78.7279,
            "region_code" : "NY"
          },
          "offset" : 21471,
          "auth" : "-",
          "ident" : "-",
          "input_type" : "log",
          "verb" : "GET",
          "source" : "/path/to/file/logstash-tutorial.log",
          "message" : "108.174.55.234 - - [04/Jan/2015:05:27:45 +0000] \"GET /?flav=rss20 HTTP/1.1\" 200 29941 \"-\" \"-\"",
          "type" : "log",
          "tags" : [
            "beats_input_codec_plain_applied"
          ],
          "referrer" : "\"-\"",
          "@timestamp" : "2016-10-11T22:34:25.318Z",
          "response" : "200",
          "bytes" : "29941",
          "clientip" : "108.174.55.234",
          "@version" : "1",
          "beat" : {
            "hostname" : "My-MacBook-Pro.local",
            "name" : "My-MacBook-Pro.local"
          },
          "host" : "My-MacBook-Pro.local",
          "httpversion" : "1.1",
          "timestamp" : "04/Jan/2015:05:27:45 +0000"
        }
      }

}