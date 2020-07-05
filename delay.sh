#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/delay-%j.log
#SBATCH --time=5:00
#SBATCH --mem=10MB
#SBATCH --partition=short
#SBATCH --dependency=singleton

# Print arguments
echo "delay.sh" "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'
WOS='en en_random en_sov en_svo en_vos30rest14 en_vos60rest8 en_vos en_vso30rest14 en_vso60rest8 en_vso en_randomna-aseed5 en_randomna-dseed5 en_randomnoneseed10'
ERROR=$(cat <<-END
  delay.sh: Incorrect usage.
  Correct usage options are:
  - delay.sh train
  - delay.sh translate [transformer|rnn] [en|en_vso|en_sov|...]
  - delay.sh conll
END
)

if [[ "$1" == "train" ]]; then
  for LANG in fr; do
    for WO in ${WOS}; do
      # Train RNN
      sbatch --job-name=EuroNMT-rnn-"${WO}" train.sh "${LANG}" rnn "${WO}"
      # Wait until train job is done, then start translation job
      sbatch --job-name=EuroNMT-rnn-"${WO}" delay.sh translate rnn "${WO}"
    
      # Train Transformer
      sbatch --job-name=EuroNMT-transformer-"${WO}" train.sh "${LANG}" transformer "${WO}"
      # # Wait until train job is done, then start translation job
      sbatch --job-name=EuroNMT-transformer-"${WO}" delay.sh translate transformer "${WO}"
    done
  done

elif [[ "$1" == "translate" ]] && [[ "$2" =~ ^(transformer|rnn)$ ]]; then
  for LANG in fr; do
    # Translate RNN/Transformer
    sbatch translate.sh "${LANG}" "${2}" "${3}"
  done

else
  echo "${ERROR}"
  exit
fi
