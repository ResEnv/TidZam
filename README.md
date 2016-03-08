# TidZam

TidZam is a web-based software interested in living form (birg, frog, etc) geo-localization from multi-sourced live audio  captures from TidMarsh Environment. A multi-channel OGG stream is presented to a recongition engine based on Reinforced Deep Belief Networks (RDBM). Its 2-binary classifiers denoted Knowledge Units (KUs) are trained from multi-sourced realtime  captures for audio context learning.

* Semantic learning is trained on a particular kind of sound like bird calls, human voice, clicks, etc in order to geo-localized them in multi-channel audio stream. According to the policy of the training dataset generation, the sound can be more or less specialized according to the others (KUs). A good idea is the learning of  Nothing (KU) in order to detect new unknown sounds.

* Context learning is trained by aggregated multi-sourced live audio captures in order to learn global  variables of the audio environment. Self-fealturing extraction by Restricted Boltzman Machine (RBM) is used to reduce drastically input dimension. Several neural architectures can be selected for (KU) such as (RBM), Convolutional Neural Network (CNN) and Stacked Auto-Encoder (SAE).

Other Interests in Click Echo Recognition in human echo-localization.

# Installation

```
npm tidzam
```

# Starting
```
npm start
```
# Demo
[![ScreenShot](http://duhart-clement.fr/imgs/demo.png)](https://youtu.be/XT93JgFPfqA)
Play Online: http://tidmarsh.duhart-clement.fr/client/index.html
