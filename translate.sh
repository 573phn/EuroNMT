#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/translate-job-%j.log
#SBATCH --time=24:00:00
#SBATCH --mem=64GB
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
  - translate.sh [fr|nl] [rnn|transformer]
END
)

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Make environment variable to use GPUs
export CUDA_VISIBLE_DEVICES=0

if [[ "$1" =~ ^(fr|nl)$ ]] && [[ "$2" == "rnn" ]]; then
    onmt_translate -model "${DATADIR}"/data/en-"${1}"/trained_model_"${2}"_step_100000.pt \
                   -src "${HOMEDIR}"/data/en-"${1}"/src_test.txt \
                   -output "${DATADIR}"/data/en-"${1}"/out_test_"${2}".txt \
                   -gpu 0

elif [[ "$1" =~ ^(fr|nl)$ ]] && [[ "$2" == "transformer" ]]; then
    onmt_translate -model "${DATADIR}"/data/en-"${1}"/trained_model_"${2}"_step_100000.pt \
                   -src "${HOMEDIR}"/data/en-"${1}"/src_test.txt \
                   -output "${DATADIR}"/data/en-"${1}"/out_test_"${2}".txt \
                   -gpu 0

else
  echo "${ERROR}"
  exit
fi
