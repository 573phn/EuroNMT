#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/train-job-%j.log
#SBATCH --time=3-00:00:00
#SBATCH --mem=64GB
#SBATCH --partition=gpu
#SBATCH --gres=gpu:v100:1
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=g.j.s.sportel@rug.nl

# Print arguments
echo "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'
ERROR=$(cat <<-END
  train.sh: Incorrect usage.
  Correct usage options are:
  - train.sh [fr|nl] [rnn|transformer]
END
)

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Make environment variable to use GPUs
export CUDA_VISIBLE_DEVICES=0

# Train model
if [[ "$1" =~ ^(fr|nl)$ ]] && [[ "$2" == "rnn" ]]; then
  onmt_train -data "${DATADIR}"/data/en-"${1}"/ppd \
             -save_model "${DATADIR}"/data/en-"${1}"/trained_model_"${2}" \
             -save_checkpoint_steps 50000 \
             -world_size 1 \
             -gpu_ranks 0 \
             -global_attention mlp \
             -layers 3 \
             -optim adam \
             -learning_rate 0.001 \
             -label_smoothing 0.1 \
             -rnn_size 512 \
             -batch_size 128 \
             -early_stopping 5 \
             -train_steps 2000000

elif [[ "$1" =~ ^(fr|nl)$ ]] && [[ "$2" == "transformer" ]]; then
  onmt_train -data "${DATADIR}"/data/en-"${1}"/ppd \
             -save_model "${DATADIR}"/data/en-"${1}"/trained_model_"${2}" \
             -layers 6 \
             -rnn_size 512 \
             -word_vec_size 512 \
             -transformer_ff 2048 \
             -heads 8 \
             -encoder_type transformer \
             -decoder_type transformer \
             -position_encoding \
             -max_generator_batches 2 \
             -dropout 0.1 \
             -batch_size 128 \
             -batch_type sents \
             -normalization sents \
             -accum_count 2 \
             -optim adam \
             -adam_beta2 0.998 \
             -decay_method noam \
             -warmup_steps 40 \
             -learning_rate 2 \
             -max_grad_norm 0 \
             -param_init 0 \
             -param_init_glorot \
             -label_smoothing 0.1 \
             -save_checkpoint_steps 100000 \
             -world_size 1 \
             -gpu_ranks 0 \
             -early_stopping 5 \
             -train_steps 2000000

else
  echo "${ERROR}"
  exit
fi
