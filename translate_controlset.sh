#!/bin/bash
#SBATCH --job-name=translate-control
#SBATCH --output=slurm/translate-control-job-%j.log
#SBATCH --time=00:30:00
#SBATCH --mem=4GB
#SBATCH --partition=gpu
#SBATCH --gres=gpu:v100:1

# Print arguments
echo "${@}"

# Set variables
HOMEDIR='/home/'"${USER}"'/EuroNMT'
DATADIR='/data/'"${USER}"'/EuroNMT'
ERROR=$(cat <<-END
  translate_controlset.sh: Incorrect usage.
  Correct usage options are:
  - translate_controlset.sh fr [rnn|transformer] [en|en_vso|en_sov|...] [en|en_vso|en_sov|...]
                                                  ^^-- name of model     ^^-- name of control data
END
)

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Make environment variable to use GPUs
export CUDA_VISIBLE_DEVICES=0

# Apply BPE
python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/"${3}"-"${1}"/src_codes.bpe < "${HOMEDIR}"/data/control/"${4}".txt > "${DATADIR}"/data/control/"${4}".bpe

if [[ "$1" == "fr" ]] && [[ "$2" =~ ^(rnn|transformer)$ ]]; then
  # Get highest step number
  if [[ "$3" == "en" ]]; then
    HIGHESTSTEP=$(ls -f "${DATADIR}"/data/"${3}"-"${1}"/trained_model_"${2}"_step_*.pt | cut -d_ -f5 | sort -n | tail -1)
  else
    HIGHESTSTEP=$(ls -f "${DATADIR}"/data/"${3}"-"${1}"/trained_model_"${2}"_step_*.pt | cut -d_ -f6 | sort -n | tail -1)
  fi
  
  onmt_translate -model "${DATADIR}"/data/"${3}"-"${1}"/trained_model_"${2}"_step_"${HIGHESTSTEP}" \
                 -src "${DATADIR}"/data/control/"${4}".bpe \
                 -output "${DATADIR}"/data/control/"${4}"_out.bpe \
                 -gpu 0
    
  cat "${DATADIR}"/data/control/"${4}"_out.bpe | sed -E 's/(@@ )|(@@ ?$)//g' > "${DATADIR}"/data/control/"${4}"_out.txt
  
  echo "nltk_bleu:"
  python "${HOMEDIR}"/data/tools/nltk_bleu.py -r "${HOMEDIR}"/data/control/"${1}".txt -t "${DATADIR}"/data/control/"${4}"_out.txt
  
   
else
  echo "${ERROR}"
  exit
fi
