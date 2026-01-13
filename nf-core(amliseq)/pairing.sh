#!/bin/bash
set -e

# 1. Configuration
GCS_INPUT_PATH="gs://data-metagenomics-petproject-2025/HMP_mock_dataset_raw_data"
GCS_OUTPUT_PATH="gs://workdir-metagenomics-petproject-2025/HMP_pairing/"
LOCAL_CSV="HMP_pairing.csv"

echo "Scanning files in: $GCS_INPUT_PATH"
echo "sampleID,forwardReads,reverseReads" > "$LOCAL_CSV"

# 2. Loop to scan files (Robust Method)
for FILE in $(gsutil ls "${GCS_INPUT_PATH}/"); do
    
    # Filter: Only process files containing "_R1_"
    if [[ "$FILE" != *"_R1_"* ]]; then
        continue
    fi

    R1_FULL_PATH="$FILE"
    
    # Generate R2 path
    R2_FULL_PATH="${R1_FULL_PATH/_R1_/_R2_}"

    # Extract Sample ID
    FILENAME=$(basename "$R1_FULL_PATH")
    SAMPLE_ID=$(echo "$FILENAME" | sed 's/_S[0-9]\+.*//')

    # Write to local CSV
    echo "${SAMPLE_ID},${R1_FULL_PATH},${R2_FULL_PATH}" >> "$LOCAL_CSV"
    
    echo " -> Added sample: $SAMPLE_ID"

done

# 3. Upload to Cloud
echo "Uploading samplesheet to Cloud..."
gsutil cp "$LOCAL_CSV" "$GCS_OUTPUT_PATH"

# 4. CLEANUP (Delete the file from the local disk)
echo "Removing local temporary file..."
rm "$LOCAL_CSV"

echo "Done! The CSV is saved on the Cloud and removed from this machine."
