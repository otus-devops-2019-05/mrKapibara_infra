#!/bin/bash

/usr/bin/gcloud compute instances create reddit-bake \
--boot-disk-size=10GB \
--boot-disk-type=pd-ssd \
--image-family=reddit-full \
--machine-type=g1-small \
--tags=puma \
--restart-on-failure \
--preemptible \
--zone us-central1-c
