#sudo apt-get update
sudo apt-get install nodejs octave octave-audio   octave-control  octave-general  octave-signal sox vorbis-tools mplayer qarecord ffmpeg
mkdir data tmp
mkdir data/classifiers data/database data/dataset data/processed_records data/stream data/training
cp Nothing/* data/classifiers
cp Nothing/Nothing.dat data/dataset
coffee --compile --output dist src
