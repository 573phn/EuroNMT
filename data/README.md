Files are listed in the order in which they should be run:

1. `make_baseline_corpus.sh`
   - Converts Europarl corpora to Pandas DataFrames and merges them on the column with English sentences.
   - Lowercases and tokenizes the foreign sentences and only tokenizes the English sentences.
   - Saves an `en.txt` file which will be used to create an `en.conll` file.
   - Converts English column to lowercase so it is both tokenized and lowercased like the rest.
   - Saves a Pandas DataFrame as a feather file which will be used to create files for OpenNMT.

2. `make_conll_file.sh`
   - Splits `en.txt` into multiple files, then starts `conll_process.sh` which converts each of those files to conll format.
   - Starts `combine_conll_files.sh` which merges those conll files into one `en.conll` file.
   - The resulting file is then zipped for use with the Ravfogel code.

3. Use the generated zip file with the Ravfogel code for reordering and/or adding cases

4. `py2json_to_py3ftr.sh`
   - Merges json files with reordered English (as created by Ravfogel code) with DataFrame feather file (`merged_dfs.ftr`) that contains baseline English, French and Dutch sentences.
   - Output is written to new DataFrame feather file (`new_merged_dfs.ftr`).

5. `make_opennmt_files.sh`
   - Loads Pandas DataFrame from feather file.
   - Adds an extra column `en_shuffled` in which all tokens (including punctuation) are randomly shuffled.
   - Creates directories with OpenNMT files (train/test/val for src and tgt) for all English word orders and foreign languages in the DataFrame.

6. Use the files in the parent directory to preprocess, train and test the data and models.
