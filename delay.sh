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
DATADIR='/data/'"${USER}"'/EuroNMT'
RAVFOGELDIR='/data/'"${USER}"'/rnn_typology'
WOS='en en_vso en_sov en_vos en_random en_vso60rest8 en_vso30rest14 en_vos60rest8 en_vos30rest14'
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

elif [[ "$1" == "conll" ]]; then
  # Merge splitted conll files into one conll file
  for file in "${DATADIR}"/data/splitfolder/split*.conll; do (cat "${file}"; echo); done | head -n -1 > "${DATADIR}"/data/en.conll

  # After conll files have been merged, the resulting file needs to be zipped for use with Ravfogel code
  zip "${RAVFOGELDIR}"/dev-penn-ud.zip "${DATADIR}"/data/en.conll

else
  echo "${ERROR}"
  exit
fi
