#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/combine_conll_files-%j.log
#SBATCH --time=5:00
#SBATCH --mem=10MB
#SBATCH --partition=short
#SBATCH --dependency=singleton

# Print arguments
echo "combine_conll_files.sh" "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'
RAVFOGELDIR='/data/'"${USER}"'/rnn_typology'

# Merge splitted conll files into one conll file
for file in "${DATADIR}"/data/splitfolder/split*.conll; do (cat "${file}"; echo); done | head -n -1 > "${DATADIR}"/data/en.conll

# After conll files have been merged, the resulting file needs to be zipped for use with Ravfogel code
zip "${RAVFOGELDIR}"/dev-penn-ud.zip "${DATADIR}"/data/en.conll
