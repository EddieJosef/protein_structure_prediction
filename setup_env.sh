#!/bin/bash

# Step 1: Check for the YAML file
if [ -f "snake_env.yml" ]; then
    echo "Found snake_env.yml. Creating the 'snake' environment..."
else
    echo "Error: snake_env.yml not found. Please provide the environment file."
    exit 1
fi

# Step 2: Set the Modeller license key
echo "Setting up Modeller license key..."
export KEY_MODELLER="MODELIRANJE"

# Step 3: Create the environment from the YAML file
echo "Creating the 'snake' environment from snake_env.yml..."
conda env create -f snake_env.yml

# Step 4: Activate the environment
echo "Activating the 'snake' environment..."
source ~/miniconda3/etc/profile.d/conda.sh  # Ensure Conda is initialized
conda activate snake

# Step 5: Verify Installation
echo "Verifying the installed environment..."
conda list -n snake

# Step 6: Verify Modeller installation
echo "Verifying Modeller installation..."
python -c "import modeller; print('Modeller version:', modeller.__version__)"

echo "Setup complete! Use 'conda activate snake' to activate the environment."
