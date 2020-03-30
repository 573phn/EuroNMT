#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/EuroNMT-%j.log
#SBATCH --time=30:00
#SBATCH --mem=64GB
#SBATCH --partition=regular

# Print arguments
echo "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Prepare data
# python3 -m trace --trace 1_prepare_for_ravfogel.py fr nl
python3 baseline.py
