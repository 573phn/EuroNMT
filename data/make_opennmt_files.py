#!/usr/bin/env python3
import pandas as pd
from getpass import getuser
from pathlib import Path

langs = {'fr', 'nl'}

merged_dfs = pd.read_feather(f'/data/{getuser()}/EuroNMT/data/merged_dfs.ftr')
word_orders = [col for col in merged_dfs.columns if col not in langs]

print('--------')
for lang in langs:
    for wo in word_orders:
        # Make directory if it does not exist yet
        Path(f'/home/{getuser()}/EuroNMT/data/{wo}-{lang}').mkdir(parents=True, exist_ok=True)
        
        print(f"Creating OpenNMT files for '{wo}-{lang}' corpus")
        # Get src column column plus 1 tgt column
        corpus_df = merged_dfs.filter([wo, lang], axis=1)
        # Randomize order of rows, random state is the seed that's being used
        corpus_df = corpus_df.sample(frac=1, random_state=1).reset_index(drop=True)
        
        # Split n/5k/5k
        split_1 = -10000
        split_2 = -5000

        print(f'Total lines in corpus: {len(corpus_df)}')
        with open(f'/home/{getuser()}/EuroNMT/data/{wo}-{lang}/src_train.txt', 'w') as src_train, \
             open(f'/home/{getuser()}/EuroNMT/data/{wo}-{lang}/tgt_train.txt', 'w') as tgt_train:
            print(f"Creating training files ({len(corpus_df[wo].iloc[:split_1])} lines)")
            src_train.write(corpus_df[wo].iloc[:split_1].str.cat(sep='\n'))
            tgt_train.write(corpus_df[lang].iloc[:split_1].str.cat(sep='\n'))

        with open(f'/home/{getuser()}/EuroNMT/data/{wo}-{lang}/src_val.txt', 'w') as src_val, \
             open(f'/home/{getuser()}/EuroNMT/data/{wo}-{lang}/tgt_val.txt', 'w') as tgt_val:
            print(f"Creating validation files ({len(corpus_df[wo].iloc[split_1:split_2])} lines)")
            src_val.write(corpus_df[wo].iloc[split_1:split_2].str.cat(sep='\n'))
            tgt_val.write(corpus_df[lang].iloc[split_1:split_2].str.cat(sep='\n'))
            
        with open(f'/home/{getuser()}/EuroNMT/data/{wo}-{lang}/src_test.txt', 'w') as src_test, \
             open(f'/home/{getuser()}/EuroNMT/data/{wo}-{lang}/tgt_test.txt', 'w') as tgt_test:
            print(f"Creating test files ({len(corpus_df[wo].iloc[split_2:])} lines)")
            src_test.write(corpus_df[wo].iloc[split_2:].str.cat(sep='\n'))
            tgt_test.write(corpus_df[lang].iloc[split_2:].str.cat(sep='\n'))

        print('--------')
