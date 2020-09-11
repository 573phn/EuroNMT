#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/full-experiment-job-%j.log
#SBATCH --time=1:00
#SBATCH --mem=1MB
#SBATCH --partition=short

# Print arguments
echo "${@}"

# Set variables
WOS='en en_random en_sov en_vos en_vos30rest14 en_vos60rest8 en_vso en_vso30rest14 en_vso60rest8 en_svo en_randomna-aseed5 en_randomna-dseed5 en_randomnoneseed10 en_shuffle'

for WO in ${WOS}; do
  sbatch preprocess.sh fr "${WO}"
done

# Wait until all preprocess jobs are done, then start train jobs
sbatch delay.sh train
