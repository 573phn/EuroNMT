#!/bin/bash

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Set data location
DATADIR='/data/'"${USER}"'/EuroNMT'
HOMEDIR='/home/'"${USER}"'/EuroNMT'

# Prepare /data directories
mkdir -p "${DATADIR}"/data/en-fr
mkdir -p "${DATADIR}"/data/en-nl

# Change to EuroNMT/data dir
cd "${DATADIR}"/data

# Download and unpack parallel corpora
for CORPLANG in fr nl; do
  wget http://www.statmt.org/europarl/v7/"${CORPLANG}"-en.tgz
  mkdir "${CORPLANG}"-en
  tar -xzf "${CORPLANG}"-en.tgz -C "${CORPLANG}"-en
done

# Change back to EuroNMT dir
cd "${HOMEDIR}"

# Create virtual environment
python3 -m venv "${DATADIR}"/env

# Activate virtual environment
source "${DATADIR}"/env/bin/activate

# Upgrade pip (inside virtual environment)
pip install --upgrade pip==20.0.2
pip install --upgrade setuptools==46.1.3

# Install required packages (inside virtual environment)
pip install tqdm==4.30.0 spacy==2.2.3 pandas==1.0.3 spacy_conll==1.2.0 spacy-stanza==0.2.1 OpenNMT-py==1.1.1

# Download pretrained statistical model for English
python3 -m spacy download en_core_web_sm
python3 -m spacy download fr_core_news_sm
python3 -m spacy download nl_core_news_sm

# https://stanfordnlp.github.io/stanfordnlp/models.html#human-languages-supported-by-stanfordnlp
# https://stanfordnlp.github.io/stanfordnlp/performance.html#system-performance-in-conll-2018-shared-task
python3 -c "import stanza; stanza.download('en', processors={'ner': 'ontonotes'}, package='ewt')"
