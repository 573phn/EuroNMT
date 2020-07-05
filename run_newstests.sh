#!/bin/bash

for WO in en en_random en_sov en_vos en_svo en_vso en_vso60rest8 en_vso30rest14 en_vos60rest8 en_vos30rest14; do
  sbatch newstest_translate.sh "${WO}"
done
