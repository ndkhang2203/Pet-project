#!/bin/bash
set -e

# --- 1. CONFIGURATION ---
BUCKET="gs://workdir-metagenomics-petproject-2025"
INPUT_CSV_GCS="${BUCKET}/HMP_pairing/HMP_pairing.csv"
OUTPUT_METADATA="pp_metadata.tsv" 
GCS_DESTINATION="${BUCKET}/HMP_pairing/"

echo "--- 1. Download pairing file ---"
gsutil cp "$INPUT_CSV_GCS" local_pairing_temp.csv

echo "--- 2. Create metadata file (TSV) ---"
echo -e "sampleID\tgroup\tsequencing_run" > "$OUTPUT_METADATA"

# --- 3. FILL DATA (UPDATED FOR 12 SAMPLES) ---
# We read the first column (sampleID) from the CSV
tail -n +2 local_pairing_temp.csv | cut -d',' -f1 | while read -r SAMPLE_ID; do
    
    # Logic to assign Group based on Sample ID prefix
    if [[ "$SAMPLE_ID" == Human* ]]; then
        GROUP="Human"
    elif [[ "$SAMPLE_ID" == Mock* ]]; then
        GROUP="Mock"
    elif [[ "$SAMPLE_ID" == Mouse* ]]; then
        GROUP="Mouse"
    elif [[ "$SAMPLE_ID" == Soil* ]]; then
        GROUP="Soil"
    else
        GROUP="Other"
    fi

    RUN="Run1"

    # Use \t (tab) between variables
    echo -e "${SAMPLE_ID}\t${GROUP}\t${RUN}" >> "$OUTPUT_METADATA"
    echo " -> Added: $SAMPLE_ID (Group: $GROUP)"
done

# --- 4. UPLOAD ---
echo "--- 3. Upload to Cloud ---"
gsutil cp "$OUTPUT_METADATA" "$GCS_DESTINATION"
rm local_pairing_temp.csv "$OUTPUT_METADATA"

echo "Done! New file saved at: ${GCS_DESTINATION}${OUTPUT_METADATA}"
