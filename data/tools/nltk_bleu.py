#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''
sent bleu using nltk
Modified version of: https://github.com/cshanbo/Smooth_BLEU
'''
from nltk.translate.bleu_score import SmoothingFunction, corpus_bleu
import nltk
import argparse

def bleu_calculation(reference='', translation='', weights='0.25 0.25 0.25 0.25'):
    weight = [float(v) for v in weights.split()]
    with open(translation, 'r') as trans, open(reference, 'r') as ref:
        ref_list = [[rl.strip().split()] for rl in ref]
        tran_list = [tl.strip().split() for tl in trans]
        # https://www.nltk.org/api/nltk.translate.html#module-nltk.translate.bleu_score
        chencherry = SmoothingFunction()
        print(corpus_bleu(ref_list, tran_list, weight, smoothing_function=chencherry.method3))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Arguments for calculating BLEU')
    parser.add_argument('-r', '--reference', type=str, required=True, 
                         help="reference file")
    parser.add_argument('-t', '--translation', type=str, required=True, 
                         help="translation file")
    parser.add_argument('-w', '--weights', type=str, required=False, 
                         default='0.25 0.25 0.25 0.25',
                         help="weights for n-grams (default: %(default)s)")

    args = parser.parse_args()
    bleu_calculation(reference=args.reference,
                     translation=args.translation,
                     weights=args.weights)
