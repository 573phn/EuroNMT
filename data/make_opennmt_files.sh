#!/bin/bash
#SBATCH --job-name=make_opennmt_files
#SBATCH --output=slurm/make_opennmt_files-%j.log
#SBATCH --time=1-00:00:00
#SBATCH --mem=64GB
#SBATCH --partition=regular

# Print arguments
echo "make_opennmt_files.sh" "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Prepare data
python3 make_opennmt_files.py
