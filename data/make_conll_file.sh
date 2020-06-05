#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/make_conll_file-%j.log
#SBATCH --time=5:00
#SBATCH --mem=10MB
#SBATCH --partition=short

# Print arguments
echo "make_conll_file.sh" "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Split data to multiple files for parallel processing
split -d -l 200000 "${DATADIR}"/data/en.txt "${DATADIR}"/data/splitfolder/split --additional-suffix=.txt

# Submit a job for each created file
for file in "${DATADIR}"/data/splitfolder/split*.txt; do
  sbatch conll_process.sh "${file}"
done

# Wait until previously started jobs are done, then merge resulting conll files
sbatch combine_conll_files.sh
