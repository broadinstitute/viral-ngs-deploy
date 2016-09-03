#!/bin/bash
set -e

if [ ! -d $GATK_PATH ]; then
  if [ -z "$BUNDLE_SECRET" ]; then
    echo "ERROR: GATK is missing, but secret key is not set for auto-download."
    exit 1

  else
    echo "Fetching encrypted GATK bundle for Travis"
    pwd
    wget https://storage.googleapis.com/sabeti-public/software_testing/GenomeAnalysisTK-3.6.tar.gz.enc
    openssl aes-256-cbc -d -k "$BUNDLE_SECRET" -in GenomeAnalysisTK-3.6.tar.gz.enc -out GenomeAnalysisTK-3.6.tar.gz
    md5sum GenomeAnalysisTK-3.6.tar.gz
    tar -xzpvf GenomeAnalysisTK-3.6.tar.gz -C "$CACHE_DIR"

  fi
fi