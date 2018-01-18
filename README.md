# Scaife Viewer Search Indexer

This repository contains the container image definition and configuration for the search indexer. Logstash is used to pull ElasticSearch documents from Google Pub/Sub and upsert them in the search indices.

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
        --role roles/pubsub.subscriber
    gcloud pubsub topics create "search-indexer-${SCAIFE_INSTANCE}-documents"

The naming above assumes the GCP project you are creating the resources under is specific to the Scaife Viewer. Please adjust them as you see fit.

The service account key created above is used as a deployment artifact. There are too many
ways to enumerate how to get it to the running indexer. For now, this is left up as an
excerise for the reader.
