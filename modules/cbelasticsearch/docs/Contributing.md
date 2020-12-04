Contributing
=============

Follow these steps to get started hacking on CBElasticsearch.

1. Clone the module - `git clone git@github.com:coldbox-modules/cbox-elasticsearch.git`
2. Install dependencies - `box install`
3. Start a new Elasticsearch instance via docker - `docker run -d -p "9200:9200" -e 'discovery.type=single-node' elasticsearch:7.6.2`
4. Start the cbelasticsearch server - `box start`
5. Run tests - `box testbox run`