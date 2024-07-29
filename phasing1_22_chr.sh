#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define essential variables
PLINK_PREFIX="your_data"  # Base name of your PLINK files (without extensions)
VCF_OUTPUT="your_data.vcf"
PHASED_OUTPUT_DIR="phased_output"
SHAPEIT4_VERSION="shapeit4.2.2"
GENETIC_MAP_FILE="genetic_map_hg19_withX.txt"
MERGED_PHASED_FILE="your_data_phased_all.vcf.gz"

# Create directory to store phased outputs
mkdir -p $PHASED_OUTPUT_DIR

# Step 1: Convert PLINK files to VCF format
echo "Converting PLINK files to VCF format..."
plink --bfile $PLINK_PREFIX --recode vcf --out $VCF_OUTPUT

# Step 2: Download and set up SHAPEIT4
echo "Downloading and setting up SHAPEIT4..."
wget -q https://jmarchini.org/shapeit4/${SHAPEIT4_VERSION}.tar.gz
tar -xzf ${SHAPEIT4_VERSION}.tar.gz
cd $SHAPEIT4_VERSION
make
cd ..

# Step 3: Download the genetic map file
echo "Downloading the genetic map file..."
wget -q https://github.com/odelaneau/shapeit4/raw/master/maps/$GENETIC_MAP_FILE

# Step 4: Phase each chromosome individually using SHAPEIT4
echo "Phasing data for each chromosome..."
for chr in {1..22} X; do
    echo "Phasing chromosome $chr..."
    ./$SHAPEIT4_VERSION/bin/shapeit4 --input $VCF_OUTPUT --map $GENETIC_MAP_FILE --region $chr --output $PHASED_OUTPUT_DIR/your_data_phased_chr${chr}.vcf.gz
done

# Step 5: Concatenate all phased chromosomes into a single VCF file
echo "Concatenating phased chromosome VCF files..."
bcftools concat -Oz -o $MERGED_PHASED_FILE $PHASED_OUTPUT_DIR/your_data_phased_chr{1..22}.vcf.gz $PHASED_OUTPUT_DIR/your_data_phased_chrX.vcf.gz
bcftools index $MERGED_PHASED_FILE

echo "Phasing complete. Merged phased VCF file: $MERGED_PHASED_FILE"
