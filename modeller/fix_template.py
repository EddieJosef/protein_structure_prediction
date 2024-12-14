from pdbfixer import PDBFixer
from openmm.app import PDBFile
import argparse
import os

# Function to extract PDB ID from a given file
def get_pdb_id_from_file(file_path):
    with open(file_path, "r") as file:
        line = file.readline().strip()  # Read the first line
        pdb_id = line[:4]       # Extract first 4 letters and convert to uppercase
        return pdb_id

# Argument parser to accept -p argument
parser = argparse.ArgumentParser()
parser.add_argument("-p", required=True, help="Path to the template file containing the PDB ID.")
args = parser.parse_args()

# Extract PDB ID
pdb_file_path = args.p
pdb_id = get_pdb_id_from_file(pdb_file_path)
# Load the PDB file
input_pdb = f'{pdb_id}_tobefixed.pdb'  # Replace with your input template file
output_pdb = f'{pdb_id}.pdb'

print(f"Loading PDB file: {input_pdb}")
fixer = PDBFixer(filename=input_pdb)

# Log issues and fixes step-by-step
print("\n--- Structure Cleaning Process ---")

# 1. Detect and log missing residues
print("Step 1: Finding Missing Residues...")
initial_residues = len(list(fixer.topology.residues()))
fixer.findMissingResidues()
new_residues = len(list(fixer.topology.residues()))
if new_residues > initial_residues:
    print(f" - Added {new_residues - initial_residues} missing residues.")
else:
    print(" - No missing residues found.")

# 2. Replace non-standard residues
print("\nStep 2: Replacing Non-standard Residues...")
fixer.findNonstandardResidues()
if fixer.nonstandardResidues:
    print(f" - Found {len(fixer.nonstandardResidues)} non-standard residues:")
    for res in fixer.nonstandardResidues:
        print(f"   - Residue: {res.name}, Chain: {res.chain.id}, ID: {res.id}")
    print(" - Replacing non-standard residues with standard residues...")
else:
    print(" - No non-standard residues found.")

# 3. Detect and log missing atoms
print("\nStep 3: Finding Missing Atoms...")
initial_atoms = sum(1 for atom in fixer.topology.atoms())
fixer.findMissingAtoms()
fixer.addMissingAtoms()
final_atoms = sum(1 for atom in fixer.topology.atoms())
if final_atoms > initial_atoms:
    print(f" - Added {final_atoms - initial_atoms} missing atoms.")
else:
    print(" - No missing atoms found.")

# 4. Add hydrogens
print("\nStep 4: Adding Missing Hydrogens...")
fixer.addMissingHydrogens()
print(" - Added hydrogens to the structure at neutral pH.")

# Save the cleaned structure
print("\nSaving the cleaned structure...")
with open(output_pdb, 'w') as f:
    PDBFile.writeFile(fixer.topology, fixer.positions, f)

print(f"\nTemplate structure cleaned successfully: {output_pdb}")
