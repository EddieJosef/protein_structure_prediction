import argparse
from modeller import *

# Set up argument parser for command-line arguments
parser = argparse.ArgumentParser(description="Automate MODELLER alignment between template and target sequences.")
parser.add_argument("--template", required=True, help="Path to the template.txt")
parser.add_argument("--target", required=True, help="Path to the target alignment file (e.g., TvLDH.ali).")

#
def get_pdb_id_from_file(file_path):
    with open(file_path, "r") as file:
        line = file.readline().strip()  # Read the first line
        pdb_id = line[:4]       # Extract first 4 letters 
        chain = line[4]
        return pdb_id, chain
# Parse arguments
args = parser.parse_args()
template_name, chain_id = get_pdb_id_from_file(args.template)
target_file = args.target
target = target_file.replace(".ali", "")
output_prefix = target + "-" + f"{template_name}{chain_id}"
print(f"template_name: {template_name}")

# Extract template name without extension

# Start MODELLER alignment
env = Environ()
aln = Alignment(env)

# Load the template structure and specify the chain to use
mdl = Model(env, file=template_name, model_segment=(f'FIRST:{chain_id}', f'LAST:{chain_id}'))
aln.append_model(mdl, align_codes=f"{template_name}{chain_id}", atom_files=f"{template_name}.pdb")

# Append the target alignment
aln.append(file=target_file, align_codes=target)

# Perform alignment
aln.align2d(max_gap_length=50)

# Write the alignment outputs
aln.write(file=f"{output_prefix}.ali", alignment_format='PIR')
aln.write(file=f"{output_prefix}.pap", alignment_format='PAP')

print(f"Alignment completed. Output files: {output_prefix}.ali, {output_prefix}.pap")
