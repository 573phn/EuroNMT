#!/usr/bin/env python3
import sys
import pandas as pd
import spacy
from getpass import getuser
from random import shuffle, seed
import numpy as np


def clean(lang):
    """
    Takes as input ISO 2 letter language code, opens Europarl corpus files and
    returns set with tuples containing sentence in English and foreign
    language.
    """
    try:
        # Open Europarl files
        with open(f'/data/{getuser()}/EuroNMT/data/{lang}-en/europarl-v7.{lang}-en.{lang}') as foreign, \
             open(f'/data/{getuser()}/EuroNMT/data/{lang}-en/europarl-v7.{lang}-en.en') as english:

            # Prepare empty lists to fill with corpus sentences
            foreign_new = []
            english_new = []

            # Loop through both corpus files synchronously
            for fline, eline in zip(foreign, english):
                # Check if both sentences contain at least 1 letter
                if fline.lower().islower() and eline.lower().islower():
                    # If so, remove superfluous spaces and add to list
                    foreign_new.append(' '.join(fline.split()))
                    english_new.append(' '.join(eline.split()))

            # Place English and foreign sentence in tuple and remove duplicates
            combo = set(tuple(zip(foreign_new, english_new)))
            return combo

    except FileNotFoundError as fnf:
        print(f"Error: One or more corpus files for '{lang}-en' not found:\n"
              f"{fnf}")
        sys.exit(1)


def make_dataframe(lang_set, lang_name):
    """
    Takes as input a set with tuples and turns it into a pandas DataFrame.
    """
    return pd.DataFrame(lang_set, columns=[lang_name, 'en'])


def merge_2dfs(df1, df2):
    """
    Takes as input two pandas DataFrames and performs an inner merge on the
    'en' column.
    """
    df1 = df1.drop_duplicates(subset='en')
    df2 = df2.drop_duplicates(subset='en')
    return pd.merge(df1, df2, on='en', validate='one_to_one')


def tokenize_lowercase(tl_sent, tl_lang):
    if tl_lang == 'en':
        return " ".join([w.text for w in sp_en(tl_sent,
                                               disable=['tagger', 'parser',
                                                        'ner'])]).lower()
    if tl_lang == 'fr':
        return " ".join([w.text for w in sp_fr(tl_sent,
                                               disable=['tagger', 'parser',
                                                        'ner'])]).lower()
    if tl_lang == 'nl':
        return " ".join([w.text for w in sp_nl(tl_sent,
                                               disable=['tagger', 'parser',
                                                        'ner'])]).lower()


langs = {'fr', 'nl'}
corp_dict = dict()
corp_dfs = []

for lang in langs:
    print(f"Cleaning '{lang}-en' corpus")
    corp_dict[lang] = clean(lang)

print('--------')
for dict_lang in corp_dict.keys():
    print(f"Turning '{dict_lang}-en' corpus into DataFrame")
    df = make_dataframe(corp_dict[dict_lang], dict_lang)
    corp_dfs.append(df)
    print(f"Shape of '{dict_lang}-en' DataFrame: {df.shape}")

print('Merging DataFrames')
merged_dfs = None
for df_index in range(len(corp_dfs) - 1):
    if df_index == 0:
        merged_dfs = merge_2dfs(corp_dfs[0], corp_dfs[1])
        print(f'Shape after merging {df_index + 2} DataFrames: '
              f'{merged_dfs.shape}')
    else:
        merged_dfs = merge_2dfs(merged_dfs, corp_dfs[df_index + 1])
        print(f'Shape after merging {df_index + 2} DataFrames: '
              f'{merged_dfs.shape}')

print('Merged DataFrame:')
print(merged_dfs)

print('--------')
print('Sorting DataFrames to make sure the rows are always in the same order')
# Reorder DataFrame columns
merged_dfs.sort_index(axis=1, inplace=True)
# Sort DataFrame
merged_dfs.sort_values(
    by=sorted(['en'] + [col for col in merged_dfs.columns if col != 'en']),
    inplace=True)
# Reset DataFrame index
merged_dfs.index = range(len(merged_dfs.index))

print('Sorted DataFrame:')
print(merged_dfs)

# Reordering should be done here. Ravfogel code takes care of tokenization and
# lowercasing the English side.

print('--------')
print('Loading language models')
sp_en = spacy.load('en_core_web_sm')
sp_fr = spacy.load('fr_core_news_sm')
# sp_nl = spacy.load('nl_core_news_sm')

# for lang in merged_dfs.columns:
for lang in {'en', 'fr'}: # Limiting to 'fr' only for testing purposes
    print(f"Tokenizing and lowercasing '{lang}' DataFrame column")
    merged_dfs[lang] = [tokenize_lowercase(sent, lang) for sent in
                        merged_dfs[lang]]

print('Tokenized and lowercased DataFrame:')
print(merged_dfs)

# Set langs to only one language for testing purposes
langs = {'fr'}

print('--------')
for lang in langs:
    print(f"Creating OpenNMT files for 'en-{lang}' corpus")
    # Get 'en' column plus 1 foreign language column
    corpus_df = merged_dfs.filter(['en', lang], axis=1)
    # Randomize order of rows
    corpus_df = corpus_df.sample(frac=1, random_state=1).reset_index(drop=True)
    
    # Split n/5k/5k
    split_1 = -10000
    split_2 = -5000

    print(f'Total lines in corpus: {len(corpus_df)}')
    with open(f'/home/{getuser()}/EuroNMT/data/en-{lang}/src_train.txt', 'w') as src_train, \
         open(f'/home/{getuser()}/EuroNMT/data/en-{lang}/tgt_train.txt', 'w') as tgt_train:
        print(f"Creating training files ({len(corpus_df['en'].iloc[:split_1])} lines)")
        src_train.write(corpus_df['en'].iloc[:split_1].str.cat(sep='\n'))
        tgt_train.write(corpus_df[lang].iloc[:split_1].str.cat(sep='\n'))

    with open(f'/home/{getuser()}/EuroNMT/data/en-{lang}/src_val.txt', 'w') as src_val, \
         open(f'/home/{getuser()}/EuroNMT/data/en-{lang}/tgt_val.txt', 'w') as tgt_val:
        print(f"Creating validation files ({len(corpus_df['en'].iloc[split_1:split_2])} lines)")
        src_val.write(corpus_df['en'].iloc[split_1:split_2].str.cat(sep='\n'))
        tgt_val.write(corpus_df[lang].iloc[split_1:split_2].str.cat(sep='\n'))
        
    with open(f'/home/{getuser()}/EuroNMT/data/en-{lang}/src_test.txt', 'w') as src_test, \
         open(f'/home/{getuser()}/EuroNMT/data/en-{lang}/tgt_test.txt', 'w') as tgt_test:
        print(f"Creating test files ({len(corpus_df['en'].iloc[split_2:])} lines)")
        src_test.write(corpus_df['en'].iloc[split_2:].str.cat(sep='\n'))
        tgt_test.write(corpus_df[lang].iloc[split_2:].str.cat(sep='\n'))

    print('--------')