#!/bin/bash

###################################################################
#
#    A script to split multi-chain PDB files into separate files
#    Names are extracted between '>' and '|'
#
###################################################################

id="$1"

# Step 0: Validate input file
if ! grep -Eq '^>[^[:space:]]{4}_[0-9]+' "$id"; then
    echo "Skipping '$id': Not a valid PDB-formatted file (4CHAR_1 format required)."
    exit 0
fi

# Step 1: Split the input file by '>'
csplit -s "$id" '/>/' '{*}' || { echo "Error: csplit failed."; exit 1; }

# Step 2: Remove the first empty chunk
rm -f xx00

# Step 3: Generate clean names from headers
ls xx* > origlist
grep ">" xx* | sed -E 's/^.*>([^|[:space:]]+).*/\1/' > namelist  # Extract clean names without : or > 

# Step 4: Create a rename list and clean intermediate files
paste origlist namelist | tr [:blank:] "," > renamelist
rm origlist namelist

# Step 5: Rename split files to clean extracted names
while IFS=',' read orig target; do
    sanitized_name=$(echo "$target" | tr -d '[:space:]')  # Remove spaces
    mv "$orig" "${sanitized_name}.fasta" || { echo "Error renaming $orig to $sanitized_name.fasta"; exit 1; }
done < renamelist

# Step 6: Remove the original input file
echo "Removing the original file: $id"
rm -f "$id"

# Step 7: Clean up the rename list
rm renamelist

echo "Splitting completed successfully for $id."
