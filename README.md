# Scaife Viewer Search Indexer

search indexer infrastructure for Scaife Viewer

This repository contains the container image definition and configuration for the search indexer. Logstash is used to pull ElasticSearch documents from Google Pub/Sub and upsert them in the search indices.

This repository is part of the [Scaife Viewer](https://scaife-viewer.org) project, an open-source ecosystem for building rich online reading environments.

## Setup

Before running the search indexer you will need to create a IAM service account and a Pub/Sub topic. The following instructions assumes you've set `CLOUDSDK_CORE_PROJECT` and
`SCAIFE_INSTANCE`:

    mkdir keys
    gcloud iam service-accounts create "search-indexer-${SCAIFE_INSTANCE}" \
        --display-name "Search Indexer ${SCAIFE_INSTANCE}"
    gcloud iam service-accounts keys create "keys/search-indexer-${SCAIFE_INSTANCE}-key.json" \
        --iam-account "search-indexer-${SCAIFE_INSTANCE}@${CLOUDSDK_CORE_PROJECT}.iam.gserviceaccount.com"
    gcloud projects add-iam-policy-binding "${CLOUDSDK_CORE_PROJECT}" \
        --member "serviceAccount:search-indexer-${SCAIFE_INSTANCE}@${CLOUDSDK_CORE_PROJECT}.iam.gserviceaccount.com" \
        --role roles/pubsub.editor
    gcloud pubsub topics create "search-indexer-${SCAIFE_INSTANCE}-documents"

The naming above assumes the GCP project you are creating the resources under is specific to the Scaife Viewer. Please adjust them as you see fit.

The service account key created above is used as a deployment artifact. There are too many
ways to enumerate how to get it to the running indexer. For now, this is left up as an
excerise for the reader.

## Indexing

To index the corpus you will need the following up and running:

* ElasticSearch
* Logstash (provided by this repo)
* Container image available for Scaife Viewer

Indexing is an extremely CPU and memory intensive process. After many trial and error run throughs, the best and fastest way to process the corpus is using a very large VM machine type. The indexer in SV can scale to as many cores as you throw at it.

### High-Level Overview

The full index process is broken into a couple phases for large scale indexing:

#### Phase One

* provision VM for scaife-viewer `cloud-indexer`
* import corpus repos to RAM disk (enabling `CTS_RESOLVER=local`)
* kick off `cloud-indexer`
  * all leaf URNs are calculated from available repos (e.g.
    `urn:cts:greekLit:tlg0016.tlg001.perseus-grc2:1.1.1`)
  * process all URNs across all available machine CPU cores generating
    ElasticSearch documents
  * push documents to Pub/Sub topic
* tear down the VM once `cloud-indexer` has completed

This phase can be configured to directly push to ElasticSearch. This works well for local development.

#### Phase Two

Logstash (provided in this repo) is configured to subscribe to the Pub/Sub topic. It pulls documents and indexes them in ElasticSearch.

### Practical Example

    gcloud beta compute instances create-with-container scaife-indexer \
        --zone us-central1-c \
        --machine-type n1-standard-96 \
        --min-cpu-platform "Intel Skylake" \
        --container-image gcr.io/scaife-viewer/scaife-viewer:ebfe836fa23ea66f17d64b9c82f65d90f00f65af \
        --container-env "CTS_LOCAL_DATA_PATH=/var/lib/nautilus/data","CTS_API_ENDPOINT=https://scaife-cts-dev.eldarion.com/api/cts","GCP_PROJECT=${CLOUDSDK_CORE_PROJECT}","SCAIFE_INSTANCE=dev" \
        --container-command "bin/cloud-indexer" \
        --container-mount-tmpfs mount-path=/var/lib/nautilus/data \
        --container-restart-policy=on-failure
    # view last ten logs from container
    gcloud --format=json logging read "resource.type=global AND jsonPayload.container.name=/scaife-indexer-step-indexer AND logName=projects/${CLOUDSDK_CORE_PROJECT}/logs/gcplogs-docker-driver" --limit 100 | jq -r '.[].jsonPayload.data' | tail -r
    # once completed, delete the VM
    gcloud compute instances delete scaife-indexer
