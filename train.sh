#!/bin/bash
#SBATCH --job-name=EuroNMT
#SBATCH --output=slurm/train-job-%j.log
#SBATCH --time=3-00:00:00
#SBATCH --mem=64GB
#SBATCH --partition=gpu
#SBATCH --gres=gpu:v100:1
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=g.j.s.sportel@rug.nl

# To resume training from unfinished job, add following to model config and
# adjust step number:
# -train_from "${DATADIR}"/data/en-"${1}"/trained_model_"${2}"_step_600000.pt

# Print arguments
echo "${@}"

# Set variables
DATADIR='/data/'"${USER}"'/EuroNMT'
ERROR=$(cat <<-END
  train.sh: Incorrect usage.
  Correct usage options are:
  - train.sh [fr|nl] [rnn|transformer] [en|en_vso|en_sov|...]
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
  onmt_train -data "${DATADIR}"/data/"${3}"-"${1}"/ppd \
             -save_model "${DATADIR}"/data/"${3}"-"${1}"/trained_model_"${2}" \
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
             -train_steps 2000000 \
             -keep_checkpoint 5

elif [[ "$1" =~ ^(fr|nl)$ ]] && [[ "$2" == "transformer" ]]; then
  onmt_train -data "${DATADIR}"/data/"${3}"-"${1}"/ppd \
             -save_model "${DATADIR}"/data/"${3}"-"${1}"/trained_model_"${2}" \
             -layers 6                      `# Default 2      - Google 6` \
             -rnn_size 512                  `# Default 500    - Google 512` \
             -word_vec_size 512             `# Default 500    - Google 512` \
             -transformer_ff 2048           `# Default 2048   - Google 2048` \
             -heads 8                       `# Default 8      - Google 8` \
             -encoder_type transformer      `# Default rnn    - Google transformer` \
             -decoder_type transformer      `# Default rnn    - Google transformer` \
             -position_encoding             `# Default False  - Google True` \
             -max_generator_batches 2       `# Default 32     - Google 2` \
             -dropout 0.1                   `# Default 0.3    - Google 0.1` \
             -batch_size 128                `# Default 64     - Google 4096` \
             -batch_type sents              `# Default sents  - Google tokens` \
             -normalization sents           `# Default sents  - Google tokens` \
             -accum_count 2                 `# Default 1      - Google 2` \
             -optim adam                    `# Default sgd    - Google adam` \
             -adam_beta2 0.998              `# Default 0.999  - Google 0.998` \
             -decay_method noam             `# Default none   - Google noam` \
             -learning_rate 2               `# Default 1      - Google 2` \
             -max_grad_norm 0               `# Default 5      - Google 0` \
             -param_init 0                  `# Default 0.1    - Google 0` \
             -param_init_glorot             `# Default False  - Google True` \
             -label_smoothing 0.1           `# Default 0      - Google 0.1` \
             -train_steps 2000000           `# Default 100000 - Google 200000` \
             -warmup_steps 80000            `# Default 4000   - Google 8000` \
             -valid_steps 10000             `# Default 10000  - Google 10000` \
             -save_checkpoint_steps 100000  `# Default 5000   - Google 10000` \
             -world_size 1                  `# Default 1      - Google 4` \
             -gpu_ranks 0                   `# Default []     - Google 0 1 2 3` \
             -keep_checkpoint 5             `# Default -1     - Google -1` \
             -early_stopping 5              `# Default 0      - Google 0`

else
  echo "${ERROR}"
  exit
fi
