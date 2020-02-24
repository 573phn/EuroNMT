#!/usr/bin/env python3
import sys
import pandas as pd


def clean(lang):
    """ Takes as input ISO 2 letter language code, opens Europarl corpus
        files and returns set with tuples containing sentence in English
        and foreign language. """
    try:
        # Open Europarl files
        with open(f'{lang}-en/europarl-v7.{lang}-en.{lang}') as foreign, \
             open(f'{lang}-en/europarl-v7.{lang}-en.en') as english:

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
        print(f'Error: One or more corpus files for {lang}-en not found:\n'
              f'{fnf}')
        sys.exit(1)


def compare(l1_set, l2_set, l1_name, l2_name):
    """ Takes as input two sets with tuples and two 639-1 language codes and
        returns pandas dataframe that only contains English sentences which
        are present in both foreign corpora. """
    # Convert each language to dataframe
    df1 = pd.DataFrame(l1_set, columns=[l1_name, 'en'])
    df2 = pd.DataFrame(l2_set, columns=[l2_name, 'en'])

    # Merge dataframes on column 'en'
    merged = df1.merge(df2, left_on='en', right_on='en',
                       how='outer', suffixes=('_lang1', '_lang2'))

    # Remove rows with NAs from merged dataframe and reset index
    in_both = merged.dropna().reset_index(drop=True)
    return in_both


def make_dataframe(lang_set, lang_name):
    """ Takes as input a set with tuples and turns it into a pandas DataFrame.
        """
    return pd.DataFrame(lang_set, columns=[lang_name, 'en'])


def merge_2dfs(df1, df2):
    """ Takes as input two pandas DataFrames and performs an inner merge on the
        'en' column. """
    df1 = df1.drop_duplicates(subset='en')
    df2 = df2.drop_duplicates(subset='en')
    return pd.merge(df1, df2, on='en', validate='one_to_one')


def write_new_files(l1_set, l2_set, l1_name, l2_name):
    with open(f'{l1_name}-en/europarl-v7.{l1_name}-en.{l1_name}.new', 'w') as l1_fnew, \
         open(f'{l1_name}-en/europarl-v7.{l1_name}-en.en.new', 'w') as l1_enew:
        for foreign, english in l1_set:
            l1_fnew.write(foreign)
            l1_enew.write(english)

    with open(f'{l2_name}-en/europarl-v7.{l2_name}-en.{l2_name}.new', 'w') as l2_fnew, \
         open(f'{l2_name}-en/europarl-v7.{l2_name}-en.en.new', 'w') as l2_enew:
        for foreign, english in l2_set:
            l2_fnew.write(foreign)
            l2_enew.write(english)


def main():
    corp_langs = {'bg', 'cs', 'da', 'de', 'el', 'es', 'et', 'fi', 'fr', 'hu',
                  'it', 'lt', 'lv', 'nl', 'pl', 'pt', 'ro', 'sk', 'sl', 'sv'}
    corp_dict = dict()
    corp_dfs = []

    argv = [arg.lower() for arg in sys.argv]

    if len(set(argv)) > 2:
        if set(argv[1:]).issubset(corp_langs):
            for lang in argv[1:]:
                corp_dict[lang] = clean(lang)

            # zip(a, a[1:])
            for dict_lang in corp_dict.keys():
                df = make_dataframe(corp_dict[dict_lang], dict_lang)
                corp_dfs.append(df)
                print(f'Shape of {dict_lang} DataFrame: {df.shape}')

            merged_dfs = None
            for df_index in range(len(corp_dfs) - 1):
                if df_index == 0:
                    merged_dfs = merge_2dfs(corp_dfs[0], corp_dfs[1])
                    print(f'Shape after merging {df_index+2} DataFrames: {merged_dfs.shape}')
                else:
                    merged_dfs = merge_2dfs(merged_dfs, corp_dfs[df_index + 1])
                    print(f'Shape after merging {df_index+2} DataFrames: {merged_dfs.shape}')

            print('Merged DataFrame:')
            print(merged_dfs)
            print('--------')
            duplicates_check = merged_dfs[merged_dfs.duplicated(['en'])]
            if duplicates_check.empty:
                print('No duplicates found in \'en\' column')
            else:
                print('DataFrame contains following duplicates in \'en\' column:\n{duplicates_check}')
                print('DataFrame after removing duplicates:')
                print(merged_dfs.drop_duplicates(subset='en'))

            """
            pd.set_option('display.max_colwidth', -1)
            for num in range(3):
                for lang in ('en', 'nl', 'de', 'fr'):
                    print(merged_dfs.loc[[num], [lang]])
                print()
            """

            # Start debugger
            # import pdb
            # pdb.set_trace()
        else:
            print(f'Incorrect argument(s) used, valid arguments are '
                  f'{list(corp_langs)}. You used: {argv[1:]}')

    else:
        print(f'Incorrect number of arguments used, 2 or more arguments are '
              f'required. You used {len(argv)-1}: {argv[1:]}')


if __name__ == '__main__':
    main()
