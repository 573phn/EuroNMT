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
    # Add column with uppercase text
    df1['EN_UPPER'] = df1['en'].astype(str).str.upper()
    df2['EN_UPPER'] = df2['en'].astype(str).str.upper()
    
    # drop duplicates from 'EN_UPPER' columns
    df1.drop_duplicates(subset='EN_UPPER', inplace=True)
    df2.drop_duplicates(subset='EN_UPPER', inplace=True)
    
    new_df = pd.merge(df1, df2, on='EN_UPPER')
    new_df.drop_duplicates(subset='EN_UPPER', inplace=True)
    
    new_df.rename(columns={'en_x': 'en'}, inplace=True)
    new_df.drop(['EN_UPPER', 'en_y'], axis=1, inplace=True)
    
    # return merged DataFrame
    return new_df


def tokenize_lowercase(tl_sent, tl_lang):
    if tl_lang == 'en':
        # If language is English, don't lowercase because Ravfogel will do it
        return " ".join([w.text for w in sp_en(tl_sent,
                                               disable=['tagger', 'parser',
                                                        'ner'])])
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

print(merged_dfs.columns)

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

# Tokenize and lowercase all foreign languages (NL and FR), only do only tokenization for EN
print('--------')
print('Loading language models')
sp_en = spacy.load('en_core_web_sm')
sp_fr = spacy.load('fr_core_news_sm')
sp_nl = spacy.load('nl_core_news_sm')

for lang in merged_dfs.columns:
    if lang == 'en':
        print(f"Tokenizing '{lang}' DataFrame column")
    else:
        print(f"Tokenizing and lowercasing '{lang}' DataFrame column")
    merged_dfs[lang] = [tokenize_lowercase(sent, lang) for sent in
                        merged_dfs[lang]]

print("Tokenized and lowercased DataFrame (no lowercasing for 'en' column):")
print(merged_dfs)

merged_dfs['EN_LOWER'] = merged_dfs['en'].astype(str).str.lower()
# remove duplicates from all columns
for lang in merged_dfs.columns:
    merged_dfs.drop_duplicates(subset=lang, inplace=True)
# remove EN_LOWER column
merged_dfs.drop(['EN_LOWER'], axis=1, inplace=True)

# Reset DataFrame index
merged_dfs.index = range(len(merged_dfs.index))

# Make en.txt which will be used to created en.conll later on
with open(f'/data/{getuser()}/EuroNMT/data/en.txt', 'w') as outfile:
    outfile.write("\n".join([x for x in list(merged_dfs['en'])]))

# Convert English sentences to lowercase
merged_dfs['en'] = merged_dfs['en'].str.lower()

# Save full DataFrame to file
merged_dfs.to_feather(f'/data/{getuser()}/EuroNMT/data/merged_dfs.ftr')
