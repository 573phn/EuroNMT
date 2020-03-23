#!/usr/bin/env python3
# Converts lines with single sentences to conll format
# https://pypi.org/project/spacy-conll/

import pandas as pd
import numpy as np
import stanfordnlp, spacy
from nltk.tokenize import word_tokenize
from spacy_conll import ConllFormatter
from spacy_stanfordnlp import StanfordNLPLanguage

import stanza
from spacy_stanza import StanzaLanguage


#st1_nlp = stanfordnlp.Pipeline(lang='en', tokenize_pretokenized=True)
st1_nlp = stanza.Pipeline(lang='en', tokenize_pretokenized=True)
#st2_nlp = StanfordNLPLanguage(st1_nlp)
st2_nlp = StanzaLanguage(st1_nlp)
conllformatter = ConllFormatter(st2_nlp)
st2_nlp.add_pipe(conllformatter, last=True)

sp_en = spacy.load('en_core_web_lg')
print(sp_en.pipe_names)


data = pd.read_csv('en-corp.txt', sep="\t", header=None)
data.columns = ["en"]
print(data)

"""conll = []
for row in data['en']:
    conll.append(st2_nlp(" ".join([w.text for w in sp_en(row, disable=['tagger', 'parser', 'ner'])]))._.conll_str)
data['en_conll'] = conll


#data['en_conll'] = data.apply(fill_conll_col, axis=1)

#data['en_conll'] = ''
#data.loc(en_conll=[st2_nlp(" ".join([w.text for w in sp_en(x, disable=['tagger', 'parser', 'ner'])]))._.conll_str for x in data['en']])
#data['en_conll'] = st2_nlp(" ".join([w.text for w in sp_en(str(data['en']).rstrip(), disable=['tagger', 'parser', 'ner'])]))._.conll_str
print(data)

for cell in data['en_conll']:
    print(cell)"""

with open('en-corp.txt') as sentsin:
    for line in sentsin:
        print(line)
        
        """print('nltk')
        nltk_line = " ".join(word_tokenize(line))
        print(nltk_line)
        doc = st2_nlp(nltk_line)
        print(f'{doc._.conll_str}\n')"""
        
        print('spacy_line')
        spacy_line = " ".join([w.text for w in sp_en(line.rstrip())])
        print('doc')
        doc = st2_nlp(spacy_line)
        print('conll_str')
        #print(f'{doc._.conll_str}\n')"""
        


"""
with open('en-corp.txt') as sentsin, open('en-corp.conll', 'w') as sentsout:
    for line in sentsin:
        line = " ".join(word_tokenize(line))
        doc = nlp(line)
        sentsout.write(f'{doc._.conll_str}\n')
"""
