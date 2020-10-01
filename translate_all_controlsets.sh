#!/bin/bash

for MODEL_TYPE in rnn transformer; do
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en en_baseline
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_random en_randomnoneseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_randomna-aseed5 en_randomna-aseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_randomna-dseed5 en_randomna-dseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_randomnoneseed10 en_randomnoneseed10
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_shuffle en_shuffle5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_sov en_sovnoneseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_svo en_svononeseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_vos en_vosnoneseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_vos30rest14 en_vos30rest14noneseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_vos60rest8 en_vos60rest8noneseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_vso en_vsononeseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_vso30rest14 en_vso30rest14noneseed5
    sbatch translate_controlset.sh fr "${MODEL_TYPE}" en_vso60rest8 en_vso60rest8noneseed5
done
