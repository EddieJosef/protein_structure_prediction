from modeller import *
from modeller.automodel import *
import argparse
import os

# Argument parser to accept alignment file
parser = argparse.ArgumentParser()
parser.add_argument("--alignmentname", required=True, help="The name of the alignment .ali file")
args = parser.parse_args()

# Extract alignment file name
alignment_name = args.alignmentname
trim_alignment_name = os.path.basename(alignment_name).replace(".ali", "")

# Parse target and template names from alignment file name
# Split by '-' instead of '_' to match the format 'P09038-4oeeA.ali'
try:
    target, template = trim_alignment_name.split("-")
except ValueError:
    raise ValueError("Alignment filename must be in the format 'target-template.ali' (e.g., P09038-4oeeA.ali)")

# Modeller environment setup
env = Environ()
a = AutoModel(env, alnfile=alignment_name,
              knowns=template, sequence=target,
              assess_methods=(assess.DOPE, assess.GA341))

# Build 5 models
a.starting_model = 1
a.ending_model = 5
a.make()

print(f"Modeling complete. Target: {target}, Template: {template}")
