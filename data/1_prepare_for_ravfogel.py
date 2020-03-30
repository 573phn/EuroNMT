#!/usr/bin/env python3
import sys
import spacy
import pandas as pd
import glob
import os
from shutil import copyfile
from spacy_conll import ConllFormatter

import stanza
from spacy_stanza import StanzaLanguage

# Load Stanza (formerly StanfordNLP) and Spacy)
snlp = stanza.Pipeline(lang='en', processors={'ner': 'ontonotes'},
                       package='ewt', tokenize_pretokenized=True)
nlp = StanzaLanguage(snlp)
# nlp.to_disk("/data/s3212599/EuroNMT")
conllformatter = ConllFormatter(nlp)
nlp.add_pipe(conllformatter, last=True)
sp_en = spacy.load('en_core_web_lg')
sp_fr = spacy.load('fr_core_news_md')
sp_nl = spacy.load('nl_core_news_sm')
chunk_size = 50000


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
        for col in [col for col in df.columns if col != 'en' and col != 'en_conll']:
            with open(f'en-{col}/{col}.txt', 'w') as foreign_file,\
                 open(f'en-{col}/en.txt', 'w') as english_file:
                foreign_file.write(df[col].to_csv(header=False, index=False))
                english_file.write(df['en'].to_csv(header=False, index=False))
               
    elif output == 'tsv':
        for col in [col for col in df.columns if col != 'en' and col != 'en_conll']:
            with open(f'en-{col}/par_corp.tsv', 'w') as out_file:
                english_col = df['en'].to_csv(header=False, index=False)
                foreign_col = df[col].to_csv(header=False, index=False)
                out_file.write(f'{english_col}\t{foreign_col}')

    else:
        raise ValueError(f"Output argument must be 'lang' or 'tsv', not "
                         f"'{output}'.")


def do_something_with(row):
    return nlp(" ".join([w.text for w in sp_en(row, disable=['tagger', 'parser', 'ner'])]))._.conll_str


def chunks(lst, n):
    """ Yield successive n-sized chunks from lst.
        https://stackoverflow.com/a/312464 """
    for i in range(0, len(lst), n):
        yield lst[i:i + n]


def make_files(df, resume_num=0):
    print('range to process', range(resume_num, len(df.index)))
    for chunk in chunks(range(resume_num, len(df.index)), chunk_size):
        print('processing', chunk)
        # Process each DataFrame row in chunk and save result to chunk_list
        chunk_list = []
        for row in chunk:
            chunk_list.append(do_something_with(df.at[row, 'en']))
        # Convert chunk_list to DataFrame
        chunk_df = pd.DataFrame(chunk_list)
        # Start chunk DataFrame index from first value in range
        chunk_df.index += chunk[0]
        # Save chunk to file
        chunk_df.to_hdf(f'chunks/{chunk[-1]}.h5', key='chunk_df')


def tokenize_lowercase_french(sent):
    return " ".join([w.text for w in sp_fr(sent, disable=['tagger', 'parser', 'ner'])]).lower()


def tokenize_lowercase_dutch(sent):
    return " ".join([w.text for w in sp_nl(sent, disable=['tagger', 'parser', 'ner'])]).lower()
    
    
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

            # Sorting to make sure the rows are always in the same order
            # Reorder DataFrame columns
            merged_dfs.sort_index(axis=1, inplace=True)
            # Sort DataFrame
            merged_dfs.sort_values(by=sorted(['en'] + [col for col in merged_dfs.columns if col != 'en']), inplace=True)
            # Reset DataFrame index
            merged_dfs.index = range(len(merged_dfs.index))

            # TODO: Add saving code
            # Check which chunks have already been done and resume from last one
            existing_files = glob.glob('/home/s3212599/EuroNMT/data/chunks/*.h5')
            existing_files = [int(os.path.splitext(os.path.basename(ef))[0])
                              for ef in existing_files]
            print('existing files', existing_files)

            print('df chunks', list(chunks(range(len(merged_dfs.index)), chunk_size)))
            chunk_ends = [chunk[-1] for chunk in
                          list(chunks(range(len(merged_dfs.index)), chunk_size))]
            print('chunk_ends', chunk_ends)

            if existing_files:
                if max(existing_files) == max(chunk_ends):
                    # all files already made, no action required
                    print('all files have already been made')

                else:
                    # resume
                    print('resume from ', max(existing_files) + 1)
                    resume_num = max(existing_files) + 1
                    make_files(merged_dfs, resume_num)
            else:
                # start
                print('start')
                make_files(merged_dfs)

            # Combine all chunks
            all_files = sorted(glob.glob('/home/s3212599/EuroNMT/data/chunks/*.h5'))
            combined_chunks = pd.concat([pd.read_hdf(f) for f in all_files])
            combined_chunks.to_hdf('combined_chunks.h5', key='combined_chunks')

            print('saved DataFrame:')
            combined_save = pd.read_hdf('combined_chunks.h5')
            print(combined_save)

            # Add column from saved DataFrame to original DataFrame
            merged_dfs['en_conll'] = combined_save[0]
            print(merged_dfs)

            print('CoNLL column:')
            print(merged_dfs['en_conll'])
            print('--------')

            # Prepare folders
            foreign_langs = [col for col in merged_dfs.columns if
                             col != 'en' and col != 'en_conll']
            for col in foreign_langs:
                if not os.path.exists(f'en-{col}'):
                    os.makedirs(f'en-{col}')

            # Save file to first language
            with open(f'en-{foreign_langs[0]}/en.conll', 'w') as sentsout:
                sentsout.write(merged_dfs['en_conll'].to_csv(header=False, index=False))

            # Copy created file to folders of other languages
            if len(foreign_langs) > 1:
                for lang in foreign_langs[1:]:
                    copyfile(f'en-{foreign_langs[0]}/en.conll', f'en-{lang}/en.conll')

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
