#!/bin/bash
#SBATCH --job-name=py2json_to_py3ftr
#SBATCH --output=slurm/py2json_to_py3ftr-%j.log
#SBATCH --time=1-00:00:00
#SBATCH --mem=64GB
#SBATCH --partition=regular

# Print arguments
echo "py2json_to_py3ftr.sh" "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Prepare data
python3 py2json_to_py3ftr.py
