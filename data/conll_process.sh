#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/EuroNMT-%j.log
#SBATCH --time=3-00:00:00
#SBATCH --mem=2GB
#SBATCH --partition=regular

# Print arguments
echo "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Convert txt file to conll file
python3 spacy_conll_stanza --input_file "${1}" --output_file "${DATADIR}"/data/splitfolder/"${1##*/}".conll --use_stanfordnlp --is_tokenized --disable_sbd
