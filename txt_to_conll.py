#!/usr/bin/env python3
# Converts lines with single sentences to conll format
# https://pypi.org/project/spacy-conll/

import stanfordnlp
from nltk.tokenize import word_tokenize
from spacy_conll import ConllFormatter
from spacy_stanfordnlp import StanfordNLPLanguage

snlp = stanfordnlp.Pipeline(lang='en', tokenize_pretokenized=True)
nlp = StanfordNLPLanguage(snlp)
conllformatter = ConllFormatter(nlp)
nlp.add_pipe(conllformatter, last=True)

with open('en-corp.txt') as sentsin, open('en-corp.conll', 'w') as sentsout:
    for line in sentsin:
        line = " ".join(word_tokenize(line))
        doc = nlp(line)
        sentsout.write(f'{doc._.conll_str}\n')
