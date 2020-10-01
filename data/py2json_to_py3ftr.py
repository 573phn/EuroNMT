#!/usr/bin/env python3
# Fix by asanakoy (https://github.com/asanakoy):
# https://github.com/pandas-dev/pandas/issues/17540#issuecomment-511075723

import pandas as pd
from pathlib import Path
from getpass import getuser
import glob


paths = glob.glob(f'/data/{getuser()}/rnn_typology/*.json.gz')
merged_dfs = pd.read_feather(f'/data/{getuser()}/EuroNMT/data/merged_dfs.ftr')

for path in paths:
    with open(path) as fp:
        json_string = fp.read()
    reordered_df = pd.read_json(json_string)
    
    if len(reordered_df.index) == len(merged_dfs.index):
        merged_dfs[Path(path).stem.split('.')[0]] = pd.read_json(json_string)
    else:
        print((f'Cannot add {Path(path).stem.split(".")[0]} because it has '
               f'{len(reordered_df.index)} rows while merged_dfs has '
               f'{len(merged_dfs.index)}. Number of rows needs to be the '
               f'same.'))

    # merged_dfs = merged_dfs.merge(reordered_df, left_index=True, right_index=True)
    

print(merged_dfs.columns)
merged_dfs.to_feather(f'/data/{getuser()}/EuroNMT/data/new_merged_dfs.ftr')
