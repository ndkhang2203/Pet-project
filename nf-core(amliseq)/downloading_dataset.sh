#!/bin/bash
set -e

#--- SETTING CONFIGURATION ---
BUCKET_STORING_URL="gs://data-metagenomics-petproject-2025/HMP_mock_dataset_raw_data"
TMP_DIR="mock_dataset" # Local temporatory directory
mkdir -p $TMP_DIR
cd $TMP_DIR

# DOWNLOAD HMP DATASET 
curl -L -o 130403.tar https://mothur.s3.us-east-2.amazonaws.com/data/MiSeqDevelopmentData/130403.tar

#EXTRACT
echo "=============================================="
echo " STEP 2: EXTRACTING TAR ARCHIVE"
echo "=============================================="
tar -xvf 130403.tar
rm 130403.tar

#CONVERTING ( .bz2 -> fastq -> fastq.gz )
total_files_bz2=$(ls *.bz2 | wc -l)
count_bz2=0

for f in *.bz2; do
    count_bz2=$((count_bz2 + 1))
    percent=$((100 * count_bz2 / total_files_bz2))
    echo "[$percent%] ($count_bz2/$total_files_bz2) Đang giải nén: $f"
    bunzip2 "$f"
done

echo "=============================================="
echo " STEP 4: COMPRESSING (Gzip)"
echo "=============================================="

total_files_fastq=$(ls *.fastq | wc -l)
count_fastq=0

for f in *.fastq; do
    count_fastq=$((count_fastq + 1))
    percent=$((100 * count_fastq / total_files_fastq))
    echo "[$percent%] ($count_fastq/$total_files_fastq) Đang nén sang .gz: $f"
    gzip "$f"
done

# UPLOADING .GZ FILE TO BUCKET
gsutil -m cp *.fastq.gz $BUCKET_STORING_URL

# CLEAN UP
cd ..
rm -rf $TMP_DIR

echo "DONE"



