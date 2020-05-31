# `make_baseline_corpus.py/.sh`
Converts Europarl corpora to Pandas DataFrames and merges them on the column with English sentences.
Lowercases and tokenizes the foreign sentences and only tokenizes the English sentences.
Saves an `en.txt` file which will be used to create an `en.conll` file.
Saves a Pandas DataFrame as a feather file which will be used to create files for OpenNMT.

# `make_opennmt_files.py/.sh`
Loads Pandas DataFrame from feather file.
Converts 'en' column to lowercase.
Creates directories with OpenNMT files (train/test/val for src and tgt) for all English word orders and foreign languages in the DataFrame.

# `make_conll_file.sh`
Splits `en.txt` into multiple files, then starts `conll_process.sh` which converts each of those files to conll format.
Starts delay job which merges those conll files into one `en.conll` file.
The resulting file can be zipped and used by the Ravfogel code.

# `conll_process.sh`
See `make_conll_file.sh`, converts txt files with sentences to conll files with sentences in conll format.

# `py2json_to_py3ftr.py`
Merges json files with reordered English (as created by Ravfogel code) with DataFrame feather file (`merged_dfs.ftr`) that contains baseline English, French and Dutch sentences.
