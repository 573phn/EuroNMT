#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/preprocess-job-%j.log
#SBATCH --time=1:00:00
#SBATCH --mem=16GB
#SBATCH --partition=regular
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=g.j.s.sportel@rug.nl

# Print arguments
echo "${@}"

# Set variables
HOMEDIR='/home/'"${USER}"'/EuroNMT'
DATADIR='/data/'"${USER}"'/EuroNMT'
ERROR=$(cat <<-END
  preprocess.sh: Incorrect usage.
  Correct usage options are:
  - preprocess.sh [fr|nl]
END
)

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Preprocess data
if [[ "$1" =~ ^(fr|nl)$ ]]; then
  python "${HOMEDIR}"/data/tools/learn_bpe.py -s 32000 < "${HOMEDIR}"/data/en-"${1}"/src_train.txt > "${DATADIR}"/data/en-"${1}"/src_codes.bpe
  python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/en-"${1}"/src_codes.bpe < "${HOMEDIR}"/data/en-"${1}"/src_train.txt > "${DATADIR}"/data/en-"${1}"/src_train.bpe
  python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/en-"${1}"/src_codes.bpe < "${HOMEDIR}"/data/en-"${1}"/src_val.txt > "${DATADIR}"/data/en-"${1}"/src_val.bpe
  python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/en-"${1}"/src_codes.bpe < "${HOMEDIR}"/data/en-"${1}"/src_test.txt > "${DATADIR}"/data/en-"${1}"/src_test.bpe

  python "${HOMEDIR}"/data/tools/learn_bpe.py -s 32000 < "${HOMEDIR}"/data/en-"${1}"/tgt_train.txt > "${DATADIR}"/data/en-"${1}"/tgt_codes.bpe
  python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/en-"${1}"/tgt_codes.bpe < "${HOMEDIR}"/data/en-"${1}"/tgt_train.txt > "${DATADIR}"/data/en-"${1}"/tgt_train.bpe
  python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/en-"${1}"/tgt_codes.bpe < "${HOMEDIR}"/data/en-"${1}"/tgt_val.txt > "${DATADIR}"/data/en-"${1}"/tgt_val.bpe
  # python "${HOMEDIR}"/data/tools/apply_bpe.py -c "${DATADIR}"/data/en-"${1}"/tgt_codes.bpe < "${HOMEDIR}"/data/en-"${1}"/tgt_test.txt > "${DATADIR}"/data/en-"${1}"/tgt_test.bpe

  onmt_preprocess -train_src "${DATADIR}"/data/en-"${1}"/src_train.bpe \
                  -train_tgt "${DATADIR}"/data/en-"${1}"/tgt_train.bpe \
                  -valid_src "${DATADIR}"/data/en-"${1}"/src_val.bpe \
                  -valid_tgt "${DATADIR}"/data/en-"${1}"/tgt_val.bpe \
                  -save_data "${DATADIR}"/data/en-"${1}"/ppd
else
  echo "${ERROR}"
  exit
fi
