#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/full-experiment-job-%j.log
#SBATCH --time=1:00
#SBATCH --mem=1MB
#SBATCH --partition=short

# Print arguments
echo "${@}"

# for LANGSET in en-fr-baseline en-fr-vos en-fr-vso; do
  # Preprocess corpora
  # sbatch preprocess.sh "${LANGSET}"
# done
sbatch preprocess.sh fr

# Wait until all preprocess jobs are done, then start train jobs
sbatch delay.sh train
