#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/translate-job-%j.log
#SBATCH --time=00:05:00
#SBATCH --mem=4GB
#SBATCH --partition=gpu
#SBATCH --gres=gpu:v100:1
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=g.j.s.sportel@rug.nl

# Print arguments
echo "${@}"

# Set variables
HOMEDIR='/home/'"${USER}"'/EuroNMT'
DATADIR='/data/'"${USER}"'/EuroNMT'
ERROR=$(cat <<-END
  translate.sh: Incorrect usage.
  Correct usage options are:
  - translate.sh [fr|nl] [rnn|transformer] [en|en_vso|en_sov|...]
END
)
BPE=true

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Make environment variable to use GPUs
export CUDA_VISIBLE_DEVICES=0

if [[ "$1" =~ ^(fr|nl)$ ]] && [[ "$2" =~ ^(rnn|transformer)$ ]]; then
  # Get highest step number
  if [[ "$3" == "en" ]]; then
    HIGHESTSTEP=$(ls -f "${DATADIR}"/data/"${3}"-"${1}"/trained_model_"${2}"_step_*.pt | cut -d_ -f5 | sort -n | tail -1)
  else
    HIGHESTSTEP=$(ls -f "${DATADIR}"/data/"${3}"-"${1}"/trained_model_"${2}"_step_*.pt | cut -d_ -f6 | sort -n | tail -1)
  fi
  
  if [[ "$BPE" = true ]]; then
    onmt_translate -model "${DATADIR}"/data/"${3}"-"${1}"/trained_model_"${2}"_step_"${HIGHESTSTEP}" \
                   -src "${DATADIR}"/data/"${3}"-"${1}"/src_test.bpe \
                   -output "${DATADIR}"/data/"${3}"-"${1}"/out_test_"${2}".bpe \
                   -gpu 0
    
    cat "${DATADIR}"/data/"${3}"-"${1}"/out_test_"${2}".bpe | sed -E 's/(@@ )|(@@ ?$)//g' > "${DATADIR}"/data/"${3}"-"${1}"/out_test_"${2}".txt
    
  elif [[ "$BPE" = false ]]; then
    onmt_translate -model "${DATADIR}"/data/"${3}"-"${1}"/trained_model_"${2}"_step_"${HIGHESTSTEP}" \
                   -src "${HOMEDIR}"/data/"${3}"-"${1}"/src_test.txt \
                   -output "${DATADIR}"/data/"${3}"-"${1}"/out_test_"${2}".txt \
                   -gpu 0

  fi
  
  echo "multi-bleu-detok:"
  "${HOMEDIR}"/data/tools/multi-bleu-detok.perl "${HOMEDIR}"/data/"${3}"-"${1}"/src_test.txt < "${DATADIR}"/data/"${3}"-"${1}"/out_test_"${2}".txt
  
  echo ""
  
  echo "multi-bleu:"
  "${HOMEDIR}"/data/tools/multi-bleu.perl "${HOMEDIR}"/data/"${3}"-"${1}"/src_test.txt < "${DATADIR}"/data/"${3}"-"${1}"/out_test_"${2}".txt
  
  echo ""
  
  echo "nltk_bleu:"
  python "${HOMEDIR}"/data/tools/nltk_bleu.py -r "${HOMEDIR}"/data/"${3}"-"${1}"/tgt_test.txt -t "${DATADIR}"/data/"${3}"-"${1}"/out_test_"${2}".txt
  
   
else
  echo "${ERROR}"
  exit
fi
