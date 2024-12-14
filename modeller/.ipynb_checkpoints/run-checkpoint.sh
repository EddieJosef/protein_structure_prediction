#!/bin/bash

###################################################################
#
#    A script to split an input file (if needed) and process all 
#    resulting .fasta files using the MODELLER pipeline.
#
###################################################################

# Step 0: Input validation
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"

# Step 1: Pass the input file to split.sh
echo "Checking and splitting input file: $input_file"
if ! bash split.sh "$input_file"; then
    echo "Error: Failed to process input file with split.sh"
    exit 1
fi

# Step 2: Scan the directory for all .fasta files
fasta_files=$(ls *.fasta 2>/dev/null)
if [ -z "$fasta_files" ]; then
    echo "No FASTA files found after splitting. Exiting..."
    exit 1
fi

echo "FASTA files to be processed:"
echo "$fasta_files"

# Step 3: Check and download the database pdb_95.pir if it doesn't exist
echo "Checking for pdb_95.pir database..."
if [ ! -f "pdb_95.pir" ]; then
    echo "Downloading the pdb_95.pir database..."
    wget -q https://salilab.org/modeller/downloads/pdb_95.pir.gz -O pdb_95.pir.gz
    gunzip -f pdb_95.pir.gz || { echo "Error: Failed to download or unzip pdb_95.pir.gz"; exit 1; }
else
    echo "Database pdb_95.pir already exists. Skipping download."
fi
# Check if SCWRL4 is already installed
if [ ! -x "scwrl4/Scwrl4" ]; then
    echo "SCWRL4 not found or not executable. Attempting installation..."
    if ! bash install_rotamer.sh; then
        echo "Error: Failed to install or set up SCWRL4."
        exit 1
    fi
else
    echo "SCWRL4 is already installed."
fi


# Step 4: Loop through each .fasta file and process it
for fasta_file in $fasta_files; do
    echo "---------------------------------------------"
    echo "Processing file: $fasta_file"

    # Validate input file
    if [ ! -f "$fasta_file" ]; then
        echo "Error: File '$fasta_file' not found."
        exit 1
    fi

    # Extract base name of the input FASTA file (without extension)
    base_name=$(basename "$fasta_file" .fasta)
    echo "Base name: $base_name"

    # Step 5: Convert the input FASTA to MODELLER .ali format
    echo "Converting FASTA to .ali format..."
    if ! bash convert_fasta.sh "$fasta_file"; then
        echo "Error: convert_fasta.sh failed for $fasta_file. Skipping..."
        continue
    fi

    # Step 6: Build profile using the converted alignment file
    echo "Building profile..."
    if ! python3 build_profile.py --input "${base_name}.ali" > build_profile.log; then
        echo "Error: build_profile.py failed for ${base_name}.ali. Skipping..."
        continue
    fi

    # Step 7: Rank templates based on build_profile output
    echo "Analyzing profile and ranking templates..."
    if [ ! -f "build_profile.prf" ]; then
        echo "Error: build_profile.prf not found for $fasta_file."
        continue
    fi

    cat build_profile.prf | grep -v "^#" | awk '{print $1 "\t" $2 "\t" $11}' | awk '!$3==0' | sort -k3nr > log_file.log

    # Step 8: Choose the best-ranked template
    best_template=$(awk 'NR==1 {print $2}' log_file.log)
    if [ -z "$best_template" ]; then
        echo "Error: No template found in log_file.log for $fasta_file."
        continue
    fi

    echo "Best template chosen: $best_template"
    echo "$best_template" > template.txt

    # Step 9: Download PDB file for the best template
    echo "Downloading PDB file for the best template..."
    if ! python3 download.py -p template.txt; then
        echo "Error: download.py failed."
        continue
    fi

    # Step 10: Clean the template structure
    echo "Cleaning the template structure..."
    if ! python3 fix_template.py -p template.txt > analysis_report_template.txt; then
        echo "Error: fix_template.py failed for $fasta_file. Skipping..."
        continue
    fi

    # Step 11: Align the target sequence with the template
    echo "Aligning target sequence with the template..."
    if ! python3 align2d.py --template template.txt --target "${base_name}.ali" > align2d.log; then
        echo "Error: align2d.py failed for $fasta_file. Skipping..."
        continue
    fi

    # Step 12: Run MODELLER automodel to build the final structure
    echo "Running MODELLER automodel..."
    if ! python3 modeller_automodel.py --alignmentname "${base_name}-${best_template}.ali" > modeller_automodel.log; then
        echo "Error: modeller_automodel.py failed for $fasta_file. Skipping..."
        continue
    fi

    # Step 13: Select the best model based on DOPE and GA341 scores
    echo "Selecting the best model based on GA341 and DOPE scores..."
    best_model=$(grep -v "Filename" modeller_automodel.log | grep -v "^-" \
        | awk '$4 == 1.00000 {print $1, $3}' | sort -k2,2n | head -n 1 | awk '{print $1}')

    if [ -n "$best_model" ]; then
        echo "Best model selected: $best_model"

        # Step 14: Perform rotamer sampling
        echo "Performing rotamer sampling for $base_name..."
        if ! scwrl4/Scwrl4 -i "$best_model" -o "${base_name}_final.pdb" > rotamer_sampling.log; then
            echo "Error: SCWRL4 failed during rotamer sampling for $fasta_file."
            continue
        fi
        echo "Rotamer sampling completed successfully for $best_model."
    else
        echo "Error: No valid models found with GA341 score = 1.00000."
        continue
    fi

    # Step 15: Organize output files
    echo "Organizing output files into ${base_name}/ directory..."
    mkdir -p "${base_name}"
    find . -maxdepth 1 -type f ! \( -name "*.fasta" -o -name "*.success" \
        -o -name "align2d.py" -o -name "build_profile.py" -o -name "convert_fasta.sh" \
        -o -name "download.py" -o -name "fix_template.py" -o -name "install_rotamer.sh" \
        -o -name "modeller_automodel.py" -o -name "split.sh" -o -name "pdb_95.pir" -o -name "run.sh" \) \
        -exec mv '{}' "${base_name}/" \;

    echo "Output files moved to ${base_name}/"
    echo "Pipeline completed successfully for $fasta_file."
done

echo "All files processed successfully!"
touch "${input_file}_processed.success"
# Final Step: Delete all .fasta files
echo "Deleting all .fasta files in the current directory..."
find . -maxdepth 1 -type f -name "*.fasta" -exec rm -f {} \;
echo "All .fasta files deleted."

echo "Execution complete."
