#!/usr/bin/env python3
import sys
import pandas as pd


def clean(lang):
    """
    Takes as input ISO 2 letter language code, opens Europarl corpus files and
    returns set with tuples containing sentence in English and foreign
    language.
    """
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


def save_to_file(df, output='lang'):
    """
    Takes a pandas DataFrame as input and writes its columns to one or multiple
    files. Output options are:

    'lang': Creates a file for each language with the sentences of that
            language.
    'tsv':  Creates a file for each foreign language which contains the
            sentences of that language as well as the English translation,
            separated by a tab.
    """
    if output == 'lang':
        for col in df.columns:
            with open(f'new/euronmt-{col}.txt', 'w') as out_file:
                out_file.write(df[col].to_csv(header=False, index=False))
    elif output == 'tsv':
        for col in [col for col in df.columns if col != 'en']:
            with open(f'new/en-{col}.tsv', 'w') as out_file:
                english_col = df['en'].to_csv(header=False, index=False)
                foreign_col = df[col].to_csv(header=False, index=False)
                out_file.write(f'{english_col}\t{foreign_col}')
    else:
        raise ValueError(f"Output argument must be 'lang' or 'tsv', not "
                         f"'{output}'.")


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
                print(f"Shape of '{dict_lang}-en' DataFrame: {df.shape}")

            merged_dfs = None
            for df_index in range(len(corp_dfs) - 1):
                if df_index == 0:
                    merged_dfs = merge_2dfs(corp_dfs[0], corp_dfs[1])
                    print(f'Shape after merging {df_index+2} DataFrames: '
                          f'{merged_dfs.shape}')
                else:
                    merged_dfs = merge_2dfs(merged_dfs, corp_dfs[df_index + 1])
                    print(f'Shape after merging {df_index+2} DataFrames: '
                          f'{merged_dfs.shape}')

            print('Merged DataFrame:')
            print(merged_dfs)
            print('--------')
            duplicates_check = merged_dfs[merged_dfs.duplicated(['en'])]
            if duplicates_check.empty:
                print("No duplicates found in 'en' column")
            else:
                print(f"DataFrame contains following duplicates in 'en' column"
                      f":\n{duplicates_check}")
                print('DataFrame after removing duplicates:')
                print(merged_dfs.drop_duplicates(subset='en'))

            # Save output to file(s), output argument should be 'lang' or 'tsv'
            save_to_file(df=merged_dfs, output='lang')

        else:
            print(f'Incorrect argument(s) used, valid arguments are '
                  f'{list(corp_langs)}. You used: {argv[1:]}')

    else:
        print(f'Incorrect number of arguments used, 2 or more arguments are '
              f'required. You used {len(argv)-1}: {argv[1:]}')


if __name__ == '__main__':
    main()
