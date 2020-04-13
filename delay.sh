#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/delay-job-%j.log
#SBATCH --time=1:00
#SBATCH --mem=1MB
#SBATCH --partition=short
#SBATCH --dependency=singleton

# Print arguments
echo "${@}"

# Set variables
ERROR=$(cat <<-END
  delay.sh: Incorrect usage.
  Correct usage options are:
  - delay.sh [train|translate]
END
)

if [[ "$1" == "train" ]]; then
  for LANG in fr; do
    # Train RNN
    sbatch train.sh "${LANG}" rnn
    # Train Transformer
    sbatch train.sh "${LANG}" transformer
  done

  # Wait until all train jobs are done, then start translation jobs
  sbatch delay.sh translate

elif [[ "$1" == "translate" ]]; then
  for LANG in fr; do
    # Translate RNN
    sbatch translate.sh "${LANG}" rnn
    # Translate Transformer
    sbatch translate.sh "${LANG}" transformer
  done

else
  echo "${ERROR}"
  exit
fi
