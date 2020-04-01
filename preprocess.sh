#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/preprocess-job-%j.log
#SBATCH --time=5:00
#SBATCH --mem=8GB
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
  onmt_preprocess -train_src "${HOMEDIR}"/data/en-"${1}"/src_train.txt \
                  -train_tgt "${HOMEDIR}"/data/en-"${1}"/tgt_train.txt \
                  -valid_src "${HOMEDIR}"/data/en-"${1}"/src_val.txt \
                  -valid_tgt "${HOMEDIR}"/data/en-"${1}"/tgt_val.txt \
                  -save_data "${DATADIR}"/data/en-"${1}"/ppd
else
  echo "${ERROR}"
  exit
fi
