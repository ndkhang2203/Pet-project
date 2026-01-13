#!/bin/bash
set -e

# --- 1. CONFIGURATION ---

# Your Bucket Name
BUCKET="gs://workdir-metagenomics-petproject-2025"

# INPUT: Read directly from Bucket
INPUT_CSV="${BUCKET}/HMP_pairing/HMP_pairing.csv"

# METADATA: Read directly from Bucket (File created in previous step)
METADATA_FILE="${BUCKET}/HMP_pairing/pp_metadata.tsv"

# WORK DIR: Keep temp files on Cloud (Required for Batch)
CLOUD_WORKDIR="${BUCKET}/temp_work"

# OUTPUT: Save DIRECTLY to Cloud Bucket
# (This ensures no data touches your local disk)
CLOUD_OUTDIR="${BUCKET}/results_ampliseq_pp"

echo "Starting Nextflow Analysis on Google Batch..."
echo "Reading Input from: $INPUT_CSV"
echo "Reading Metadata from: $METADATA_FILE"
echo "Writing Temp files to: $CLOUD_WORKDIR"
echo "Saving Final Results to: $CLOUD_OUTDIR"

# --- 2. EXECUTION ---

nextflow run nf-core/ampliseq -r 2.11.0 \
  -resume \
  --input "$INPUT_CSV" \
  --metadata "$METADATA_FILE" \
  --outdir "$CLOUD_OUTDIR" \
  -w "$CLOUD_WORKDIR" \
  -profile gbatch \
  --FW_primer "GTGYCAGCMGCCGCGGTAA" \
  --RV_primer "GGACTACNVGGGTWTCTAAT" \
  --skip_cutadapt \
  --trunclenf 180 \
  --trunclenr 180 \
  --max_ee 3 \
  --trunc_qmin 2 \
  --skip_dada_addspecies \
  --dada_ref_taxonomy silva

echo "Done! Analysis finished. Results are stored in: $CLOUD_OUTDIR"
