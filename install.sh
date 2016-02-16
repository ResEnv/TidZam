#sudo apt-get update
sudo apt-get install nodejs streamripper octave octave-audio   octave-control  octave-general  octave-signal sox vorbis-tools mplayer

mkdir data tmp
mkdir data/classifiers data/database data/dataset data/processed_records data/stream data/training
coffee --compile --output dist src
