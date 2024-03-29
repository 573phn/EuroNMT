#!/bin/bash

# Load Python module
module load Python/3.7.4-GCCcore-8.3.0

# Set data location
DATADIR='/data/'"${USER}"'/EuroNMT'
HOMEDIR='/home/'"${USER}"'/EuroNMT'

# Prepare data directories
for CORPLANG in fr nl; do
  for WO in en en_vso en_sov; do
    mkdir -p "${DATADIR}"/data/"${WO}"-"${CORPLANG}"
    mkdir -p "${HOMEDIR}"/data/"${WO}"-"${CORPLANG}"
  done
done

# Change to EuroNMT/data dir
cd "${DATADIR}"/data

# Get Europarl corpora
for CORPLANG in fr nl; do
  # Don't download if corpus has been downloaded before
  if [[ -f "${CORPLANG}"-en/europarl-v7."${CORPLANG}"-en.en ]] && [[ -f "${CORPLANG}"-en/europarl-v7."${CORPLANG}"-en."${CORPLANG}" ]]; then :
  else
    # If corpus not present: download, unzip, remove zip file
    wget http://www.statmt.org/europarl/v7/"${CORPLANG}"-en.tgz
    mkdir "${CORPLANG}"-en
    tar -xzf "${CORPLANG}"-en.tgz -C "${CORPLANG}"-en
    rm "${CORPLANG}"-en.tgz
  fi
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
pip install tqdm==4.30.0 spacy==2.2.3 pandas==1.0.3 spacy_conll==1.2.0 spacy-stanza==0.2.1 OpenNMT-py==1.1.1 nltk==3.5 tables==3.6.1 pyarrow==0.17.1 torch==1.4.0

# Download pretrained spacy models
python3 -m spacy download en_core_web_sm-2.2.5
python3 -m spacy download fr_core_news_sm-2.2.5
python3 -m spacy download nl_core_news_sm-2.2.5

# https://stanfordnlp.github.io/stanfordnlp/models.html#human-languages-supported-by-stanfordnlp
# https://stanfordnlp.github.io/stanfordnlp/performance.html#system-performance-in-conll-2018-shared-task
python3 -c "import stanza; stanza.download('en')"

# Prepare baseline corpus
sbatch "${HOMEDIR}"/data/make_baseline_corpus.sh

# Make newstest dir and cd there
#mkdir -p "${DATADIR}"/newstest
#cd "${DATADIR}"/newstest

# Get WMT devfile, extract needed files and remove zip file
#wget http://www.statmt.org/wmt14/dev.tgz
#wget http://www.statmt.org/wmt11/normalize-punctuation.perl
#for LANG in fr en; do
#  for YEAR in 2012 2013; do
#    tar --extract --file=dev.tgz -C dev/newstest"${YEAR}"."${LANG}"
#    # normalize ascii punctuation
#    cat dev/newstest"${YEAR}"."${LANG}" | perl normalize-punctuation.perl -l "${LANG}" > dev/newstest"${YEAR}"_normalized."${LANG}"
#  done
#done

#python3 "${HOMEDIR}"/data/newstest_preprocesser.py
