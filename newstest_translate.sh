#!/bin/bash
#SBATCH --job-name=newstest_translate
#SBATCH --output=slurm/newstest_translate-job-%j.log
#SBATCH --time=1-00:00:00
#SBATCH --mem=10GB
#SBATCH --partition=regular

# Usage: newstest_translate.sh [en|en_vso|en_sov|...]

# Print arguments
echo "newstest_translate.sh" "${@}"

# Set variables
HOMEDIR='/home/'"${USER}"'/EuroNMT'
DATADIR='/data/'"${USER}"'/EuroNMT'
BPE=true
WO="${1}"

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Make environment variable to use GPUs
#export CUDA_VISIBLE_DEVICES=0

for YEAR in 2012 2013; do
  for MODEL in rnn transformer; do
    if [[ "$WO" == "en" ]]; then
      HIGHESTSTEP=$(ls -f "${DATADIR}"/data/"${WO}"-fr/trained_model_"${MODEL}"_step_*.pt | cut -d_ -f5 | sort -n | tail -1)
    else
      HIGHESTSTEP=$(ls -f "${DATADIR}"/data/"${WO}"-fr/trained_model_"${MODEL}"_step_*.pt | cut -d_ -f6 | sort -n | tail -1)
    fi
    
    if [[ "$BPE" = true ]]; then
      python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/"${WO}"-fr/src_codes.bpe < "${DATADIR}"/newstest/dev/processed_newstest"${YEAR}".en > "${DATADIR}"/newstest/dev/bpe_processed_newstest"${YEAR}".en
      
      onmt_translate -model "${DATADIR}"/data/"${WO}"-fr/trained_model_"${MODEL}"_step_"${HIGHESTSTEP}" \
                     -src "${DATADIR}"/newstest/dev/bpe_processed_newstest"${YEAR}".en \
                     -output "${DATADIR}"/newstest/dev/out_bpe_processed_newstest"${YEAR}".fr
  
      cat "${DATADIR}"/newstest/dev/out_bpe_processed_newstest"${YEAR}".fr | sed -E 's/(@@ )|(@@ ?$)//g' > "${DATADIR}"/newstest/dev/out_processed_newstest"${YEAR}".fr
    
    elif [[ "$BPE" = false ]]; then
      onmt_translate -model "${DATADIR}"/data/"${WO}"-fr/trained_model_"${MODEL}"_step_"${HIGHESTSTEP}" \
                     -src "${DATADIR}"/newstest/dev/processed_newstest"${YEAR}".en \
                     -output "${DATADIR}"/newstest/dev/out_processed_newstest"${YEAR}".fr
    fi
    
    echo "${YEAR}" "${MODEL}" $(python "${HOMEDIR}"/data/tools/nltk_bleu.py -r "${DATADIR}"/newstest/dev/processed_newstest"${YEAR}".en -t "${DATADIR}"/newstest/dev/out_processed_newstest"${YEAR}".fr)
  done  
done
