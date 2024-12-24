import argparse
import os
from Bio.PDB import PDBList

# Function to extract PDB ID from a given file
def get_pdb_id_from_file(file_path):
    with open(file_path, "r") as file:
        line = file.readline().strip()  # Read the first line
        pdb_id = line[:4]       # Extract first 4 letters and convert to uppercase
        return pdb_id

# Main function
def main():
    # Argument parser to accept -p argument
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", required=True, help="Path to the template file containing the PDB ID.")
    args = parser.parse_args()

    # Extract PDB ID
    pdb_file_path = args.p
    pdb_id = get_pdb_id_from_file(pdb_file_path)
    print(f"PDB ID extracted: {pdb_id}")

    # Download PDB file
    pdb_list = PDBList()
    print(f"Downloading PDB file for {pdb_id}...")
    pdb_file = pdb_list.retrieve_pdb_file(pdb_id, file_format="pdb", pdir=".")

    # Rename file to have a .pdb extension
    new_pdb_name = f"{pdb_id}_tobefixed.pdb"
    os.rename(pdb_file, new_pdb_name)
    print(f"PDB file renamed to {new_pdb_name}")

if __name__ == "__main__":
    main()
