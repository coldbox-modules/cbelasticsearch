---
description: Get started installing CBElasticsearch
---

# Installation

Via CommandBox:

```bash
install cbelasticsearch
```

## Requirements

* Coldbox >= v4.5
* Elasticsearch  >= v5.0
* Lucee >= v4.5 or Adobe Coldfusion >= v11

{% hint style="danger" %}
_Note:  Most of the REST-based methods will work on Elasticsearch versions older than v5.0.  A notable exception is the multi-delete methods, which use the [delete by query](https://www.elastic.co/guide/en/elasticsearch/reference/5.4/docs-delete-by-query.html) functionality of ES5.  As such, Cachebox and Logbox functionality would be limited._
{% endhint %}