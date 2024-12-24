# Use the official miniconda3 image as the base
FROM continuumio/miniconda3:latest

# Use bash for subsequent RUN commands
SHELL ["/bin/bash", "-c"]


# Set working directory to /workspace
WORKDIR /workspace

# Copy the Conda environment file and other necessary project files into the image
COPY . /workspace/

# Display the content of the workspace (for debugging)
RUN ls -l /workspace

# Set Modeller license key as an environment variable
ENV KEY_MODELLER="xxxxxxxxxxx"

# Create the Conda environment from the YAML file
RUN conda env create -f ./snake_env.yml

# Set up Modeller license key
RUN sed -i "s/license = 'XXXX'/license = '${KEY_MODELLER}'/" \
    /opt/conda/envs/snake/lib/modeller-10.6/modlib/modeller/config.py

# Ensure that the Conda environment is activated by default
RUN echo "source /opt/conda/etc/profile.d/conda.sh && conda activate snake" >> ~/.bashrc

# Ensure Modeller is functional and licensed correctly
RUN conda run -n snake python -c "import modeller; print('Modeller initialized successfully')"

# Set the entrypoint to activate the 'snake' environment and run Snakemake
ENTRYPOINT ["conda", "run", "-n", "snake", "snakemake"]
CMD ["--cores", "all", "--jobs", "1"]
