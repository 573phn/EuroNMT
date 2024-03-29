#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/preprocess-job-%j.log
#SBATCH --time=8:00:00
#SBATCH --mem=32GB
#SBATCH --partition=regular

# Print arguments
echo "${@}"

# Set variables
HOMEDIR='/home/'"${USER}"'/EuroNMT'
DATADIR='/data/'"${USER}"'/EuroNMT'
ERROR=$(cat <<-END
  preprocess.sh: Incorrect usage.
  Correct usage options are:
  - preprocess.sh [fr|nl] [en|en_vso|en_sov|...]
END
)
BPE=true

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Create dir if it doesn't already exist
mkdir -p "${DATADIR}"/data/"${2}"-"${1}"

# Preprocess data
if [[ "$1" =~ ^(fr|nl)$ ]]; then
  if [[ "$BPE" = true ]]; then
    python "${HOMEDIR}"/data/tools/learn_bpe.py -s 32000 < "${HOMEDIR}"/data/"${2}"-"${1}"/src_train.txt > "${DATADIR}"/data/"${2}"-"${1}"/src_codes.bpe
    python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/"${2}"-"${1}"/src_codes.bpe < "${HOMEDIR}"/data/"${2}"-"${1}"/src_train.txt > "${DATADIR}"/data/"${2}"-"${1}"/src_train.bpe
    python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/"${2}"-"${1}"/src_codes.bpe < "${HOMEDIR}"/data/"${2}"-"${1}"/src_val.txt > "${DATADIR}"/data/"${2}"-"${1}"/src_val.bpe
    python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/"${2}"-"${1}"/src_codes.bpe < "${HOMEDIR}"/data/"${2}"-"${1}"/src_test.txt > "${DATADIR}"/data/"${2}"-"${1}"/src_test.bpe

    python "${HOMEDIR}"/data/tools/learn_bpe.py -s 32000 < "${HOMEDIR}"/data/"${2}"-"${1}"/tgt_train.txt > "${DATADIR}"/data/"${2}"-"${1}"/tgt_codes.bpe
    python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/"${2}"-"${1}"/tgt_codes.bpe < "${HOMEDIR}"/data/"${2}"-"${1}"/tgt_train.txt > "${DATADIR}"/data/"${2}"-"${1}"/tgt_train.bpe
    python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/"${2}"-"${1}"/tgt_codes.bpe < "${HOMEDIR}"/data/"${2}"-"${1}"/tgt_val.txt > "${DATADIR}"/data/"${2}"-"${1}"/tgt_val.bpe
    # python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/"${2}"-"${1}"/tgt_codes.bpe < "${HOMEDIR}"/data/"${2}"-"${1}"/tgt_test.txt > "${DATADIR}"/data/"${2}"-"${1}"/tgt_test.bpe

    onmt_preprocess -train_src "${DATADIR}"/data/"${2}"-"${1}"/src_train.bpe \
                    -train_tgt "${DATADIR}"/data/"${2}"-"${1}"/tgt_train.bpe \
                    -valid_src "${DATADIR}"/data/"${2}"-"${1}"/src_val.bpe \
                    -valid_tgt "${DATADIR}"/data/"${2}"-"${1}"/tgt_val.bpe \
                    -save_data "${DATADIR}"/data/"${2}"-"${1}"/ppd

  elif [[ "$BPE" = false ]]; then
    onmt_preprocess -train_src "${HOMEDIR}"/data/"${2}"-"${1}"/src_train.txt \
                    -train_tgt "${HOMEDIR}"/data/"${2}"-"${1}"/tgt_train.txt \
                    -valid_src "${HOMEDIR}"/data/"${2}"-"${1}"/src_val.txt \
                    -valid_tgt "${HOMEDIR}"/data/"${2}"-"${1}"/tgt_val.txt \
                    -save_data "${DATADIR}"/data/"${2}"-"${1}"/ppd
  fi
else
  echo "${ERROR}"
  exit
fi
