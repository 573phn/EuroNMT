#!/bin/bash
#SBATCH --job-name=make-control
#SBATCH --output=slurm/make-control-%j.log
#SBATCH --time=3-00:00:00
#SBATCH --mem=10GB
#SBATCH --partition=regular

# Print arguments
echo "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'
RAVFOGELDIR='/home/'"${USER}"'/rnn_typology/datasets_creation/data'

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Prepare data
python3 make_control_data.py

# Convert txt file to conll file
python3 spacy_conll_stanza --input_file "${DATADIR}"/data/control/en.txt --output_file "${DATADIR}"/data/control/en.conll --use_stanfordnlp --is_tokenized --disable_sbd

# After conll files have been merged, the resulting file needs to be zipped for use with Ravfogel code
sleep 5
zip "${RAVFOGELDIR}"/control-penn-ud.zip "${DATADIR}"/data/control/en.conll
