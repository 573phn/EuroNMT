#!/bin/bash

# Set variables
WOS='en en_random en_sov en_svo en_vos30rest14 en_vos60rest8 en_vos en_vso30rest14 en_vso60rest8 en_vso en_randomna-aseed5 en_randomna-dseed5 en_randomnoneseed10'

for WO in ${WOS}; do
  sbatch preprocess.sh fr "${WO}"
done

# Wait until all preprocess jobs are done, then start train jobs
sbatch delay.sh train
