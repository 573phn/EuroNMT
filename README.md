# EuroNMT
Usage instructions:
1. Run `./setup.sh` to make directories, download corpora, create virtual environment, install Python packages and download language models
2. Run one of the following:
  * `sbatch full-experiment.sh`: To preprocess, train and translate data
  * `sbatch preprocess.sh [fr|nl] [en|en_vso|en_sov|...]`: To preprocess the French or Dutch corpus, includes adding BPE
  * `sbatch train.sh [fr|nl] [rnn|transformer] [en|en_vso|en_sov|...]`: To train the French or Dutch corpus using RNN or Transformer (requires preprocessing first)
  * `sbatch translate.sh [fr|nl] [rnn|transformer] [en|en_vso|en_sov|...]`: To translate the French or Dutch corpus using the trained RNN or Transformer model (requires preprocessing and training first) This also calculates the BLEU scores

Terminal output of running the Peregrine scripts is stored in the `/home/$USER/EuroNMT/slurm` directory.
Output files from OpenNMT, such as trained models and translated sentences are stored in the `/data/$USER/EuroNMT` directory.
