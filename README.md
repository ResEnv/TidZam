# TidZam

TidZam is a web-based software interested in wildlife sound recongition (birg, frog, etc) from raw live audio stream. A multi-channel OGG stream is presented to a pull of classifiers based on Stacked Auto-Encoder with feature self-extraction based on Restricted Boltzman Machine. The input multi-channel stream is provided by an icecast platform and transformed into spectrogram samples (50 Hz to 15 Khz over 500 ms) overlapped by factor of 0.5 to avoid to miss cut samples. They are presented to a pull of binary classifiers which are triggered if their learnt signal is matched (animal call, mechanical noise, etc). Each input sample acrosses a Pass Band Filter depending of each classifier to determine a Region of Interest to analyze. This step reduces the complexity of classifier task  thanks to a focus on the frequency range of the signal. Finally a decision function determines if the classifier outputs are consistent over the time window of 1.25 secondes (4 samples). If none of the classifiers is triggered, the signal is considered unknown and it is stored in the record database until its identification by experts.
![alt tag](http://duhart-clement.fr/imgs/tidzam-overview.png)
	Based on the Web interface, experts listen unknown signals in order to associate them to a category or create a new one. For example if a new kind of sound is registered like plane noise, the expert can create a new dataset to create a new classifier. By the same way, a classifier could be improoved by adding new samples. Learning process is composed of two main steps. Firstly the system builds a training program in order to generate efficient training and evaluation datasets which are transmitted to the deeplearning stack to create or improove a classifier. The classifiers are autonomous and therefore can be loaded and unloaded online.
	
* Play Online: http://tidzam.media.mit.edu/client/index.html/

# Demo
[![ScreenShot](http://duhart-clement.fr/imgs/demo.png)](https://youtu.be/XT93JgFPfqA)
Play Online: http://tidmarsh.duhart-clement.fr/client/index.html


# Installation

```
npm install
```

# Compilation

```
npm run compile
```

# Starting
```
npm start
```



