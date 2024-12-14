import glob
import os

# Dynamically find the first FASTA file and set 'sample' name
FASTA_FILES = glob.glob("input/*.fasta")

# Rule 'all' specifies the final output
rule all:
    input:
        expand("modeller/{SAMPLE_NAME}.fasta_processed.success", SAMPLE_NAME=[os.path.splitext(fasta)[0] for fasta in FASTA_FILES])

# Rule to install ColabFold
rule install_colabfold:
    output:
        "localcolabfold/colabfold-conda/bin/colabfold_batch"
    shell:
        """
        # Install ColabFold if it's not installed
        if [ ! -f {output} ]; then
            wget https://raw.githubusercontent.com/YoshitakaMo/localcolabfold/main/install_colabbatch_linux.sh
            bash install_colabbatch_linux.sh
        else
            echo "ColabFold already installed"
        fi
        """

# Rule to run ColabFold prediction
rule run_alphafold_prediction:
    input:
        fasta="input/{SAMPLE_NAME}.fasta",  # Use the SAMPLE_NAME wildcard to reference FASTA files
        colabfold="localcolabfold/colabfold-conda/bin/colabfold_batch",
    output:
        log="colab_fold_output/{SAMPLE_NAME}/log.txt"  # Output log file per sample
    resources: 
       gpu=2
    shell:
        """
        export PATH="/workspace/localcolabfold/colabfold-conda/bin:$PATH"
        mkdir -p colab_fold_output/{wildcards.SAMPLE_NAME}  # Create a directory for each sample
        colabfold_batch \
         --num-recycle 3 \
         --num-ensemble 2 \
         --amber \
         --pair-mode paired \
         --stop-at-score 95 \
         --msa-mode mmseqs2_uniref_env \
         --templates \
         {input.fasta} ./colab_fold/{wildcards.SAMPLE_NAME}
        """

# Rule: Run modeller script
rule run_modeller:
    input:
        log="colab_fold_output/{SAMPLE_NAME}/log.txt",
        fasta="input/{SAMPLE_NAME}.fasta"  # FASTA file for the sample
    output:
       processed_file="modeller/{SAMPLE_NAME}.fasta_processed.success"
    resources: 
       gpu=2
    shell:
        """
        echo "{input.log} generated. Initiating modeller for {input.fasta}"
        mv {input.fasta} ./modeller
        cd modeller
        bash run.sh {input.fasta}
        # Create the output directory and move result folders
        mkdir -p ../workspace/modeller_output
        find . -maxdepth 1 -type d -not -path "." -not -path "./workspace" -exec mv {} ../workspace/modeller_output/ \\;

        echo "Pipeline completed and results moved to workspace/modeller_output"
        """