#!/usr/bin/env python3
import os
import spacy
from getpass import getuser
import glob

sp_en = spacy.load('en_core_web_sm')
sp_fr = spacy.load('fr_core_news_sm')

for file_path in glob.glob(f'/data/{getuser()}/EuroNMT/newstest/dev/newstest201*.*'):
    base = os.path.basename(file_path)
    
    with open(file_path) as in_file, open(f'/data/{getuser()}/EuroNMT/newstest/dev/processed_{base}', 'w') as out_file:
        if base.endswith('.en'):
            for line in in_file:
                out_file.write(' '.join([w.text for w in sp_en(line, disable=['tagger', 'parser', 'ner'])]).lower())
        elif base.endswith('.fr'):
            for line in in_file:
                out_file.write(' '.join([w.text for w in sp_fr(line, disable=['tagger', 'parser', 'ner'])]).lower())
        else:
            print(f'Invalid language. ({base})')
