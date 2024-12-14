#!/bin/bash

# Input FASTA file
fasta_file="$1"

# Validate input
if [ -z "$fasta_file" ] || [ ! -f "$fasta_file" ]; then
    echo "Usage: $0 input.fasta"
    exit 1
fi

# Extract base name without extension
base_name=$(basename "$fasta_file" .fasta)

# Generate .ali file directly in the current directory
echo ">P1;${base_name}" > "${base_name}.ali"
echo "sequence:${base_name}:::::::0.00: 0.00" >> "${base_name}.ali"
awk 'NR > 1' "$fasta_file" | tr -d '\n' >> "${base_name}.ali"
echo "*" >> "${base_name}.ali"

# Confirm successful generation
echo "${base_name}"
