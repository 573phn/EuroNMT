#!/usr/bin/env python3
import pickle
import spacy
import random
from getpass import getuser


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


langs = {'fr', 'en'}
corp_dict = dict()

# Tokenize and lowercase FR, only do only tokenization for EN
for lang in langs:
    with open(f'/data/{getuser()}/EuroNMT/data/control/control-test-europarl.{lang}') as infile:
        if lang == 'fr':
            sp_fr = spacy.load('fr_core_news_sm')
        if lang == 'en':
            sp_en = spacy.load('en_core_web_sm')
        corp_dict[lang] = [tokenize_lowercase(line.strip(), lang) for line in infile]


# Make en.txt which will be used to created en.conll later on
with open(f'/data/{getuser()}/EuroNMT/data/control/en.txt', 'w+') as out_en:
    out_en.write("\n".join([x for x in corp_dict['en']]))

# lowercase en data
corp_dict['en'] = [v.lower() for v in corp_dict['en']]

with open(f'/home/{getuser()}/EuroNMT/data/control/en_baseline.txt', 'w+') as out_baseline:
    out_baseline.write("\n".join([x for x in corp_dict['en']]))
    
with open(f'/home/{getuser()}/EuroNMT/data/control/en_shuffle5.txt', 'w+') as out_shuffle5:
    random.seed(5)
    out_shuffle5.write('\n'.join([' '.join(random.sample(words, len(words))) for words in [sent.split() for sent in corp_dict['en']]]))
    
with open(f'/home/{getuser()}/EuroNMT/data/control/en_shuffle10.txt', 'w+') as out_shuffle10:
    random.seed(10)
    out_shuffle10.write('\n'.join([' '.join(random.sample(words, len(words))) for words in [sent.split() for sent in corp_dict['en']]]))

with open(f'/home/{getuser()}/EuroNMT/data/control/fr.txt', 'w+') as out_fr:
    out_fr.write("\n".join([x for x in corp_dict['fr']]))

with open(f'/data/{getuser()}/EuroNMT/data/control/control-test-europarl.pkl', 'wb') as handle:
    pickle.dump(corp_dict, handle, protocol=pickle.HIGHEST_PROTOCOL)
