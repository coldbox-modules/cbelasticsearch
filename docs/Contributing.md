---
description: We're open source! Get started hacking on CBElasticsearch to add a new feature, fix the docs, or prove a regression.
---

# Contributing

Follow these steps to get started hacking on CBElasticsearch:

1. Clone the module - `git clone git@github.com:coldbox-modules/cbox-elasticsearch.git`
2. Install dependencies - `box install`
3. Start a [new Elasticsearch instance](#Running-Elasticsearch)
4. Start the cbelasticsearch server - `box start`
5. Run tests - `box testbox run`

## Running Elasticsearch

To run the test suite you need a running instance of ElasticSearch. We have provided a `docker-compose.yml` file in the root of the repo to make this easy as possible. Run `docker-compose up --build` ( omit the `--build` after the first startup ) in the root of the project and open `http://localhost:8080/tests/runner.cfm` to run the tests.

If you would prefer to set up Elasticsearch yourself, make sure you start this app with the correct environment variables set:

```ini
ELASTICSEARCH_PROTOCOL=http
ELASTICSEARCH_HOST=127.0.0.1
ELASTICSEARCH_PORT=9200
```

## Releases

To issue a new release:

1. Update (and commit) `changelog.md` with each addition, bugfix, or security issue.
   1. These should be placed under the version number heading: `## [x.y.z] - dd-mm-yyyy`. Later this will be automated to use the `## Unreleased` section.
2. Set and commit the new version number in `box.json`, following semantic versioning format.
3. Run the release script: `box recipe build/release.boxr`