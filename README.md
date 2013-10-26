assemblotron
============

Automated optimal *de-novo* assembly.

Transcriptome assembly takes a *long* time and a *lot* of computational resources. The software is complex, and the best settings to use depend heavily on the organism being studied.

Assemblotron solves this problem by rapidly discovering the optimal settings for an assembler or assembly pipeline and performs the best possible assembly using the tools available.

A typical Assemblotron run takes only 3-4 hours on 8 cores of a desktop PC with an i7 processor, and greatly improves the accuracy of expression quantification and gene reconstruction in de-novo transcriptome analysis (blog posts/paper with evidence to follow shortly).

## Explanation

Assemblotron takes a small subsample of the available reads and runs an assembly. The assembly is thoroughly analysed and scored using [transrate](https://github.com/Blahah/transrate). Then the optimisation system [biopsy](https://github.com/Blahah/biopsy) is used to select new assembler settings to test, and another assembly is performed. This process is repeated until an estimate for the best possible assembly is found.

Further documentation will be provided when the software enters beta.

## Development status

[![Gem Version](https://badge.fury.io/rb/assemblotron.png)][gem]
[![Build Status](https://secure.travis-ci.org/Blahah/assemblotron.png?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/Blahah/assemblotron.png?travis)][gemnasium]
[![Code Climate](https://codeclimate.com/github/Blahah/assemblotron.png)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/Blahah/assemblotron/badge.png?branch=master)][coveralls]

[gem]: https://badge.fury.io/rb/assemblotron
[travis]: https://travis-ci.org/Blahah/assemblotron
[gemnasium]: https://gemnasium.com/Blahah/assemblotron
[codeclimate]: https://codeclimate.com/github/Blahah/assemblotron
[coveralls]: https://coveralls.io/r/Blahah/assemblotron

This software is in pre-alpha development and is not yet ready for deployment. 
Please don't report issues or request documentation until we are ready for beta release (see below for estimated timeframe).

## Expectations for imminent versions

* **v0.1.0**: allow optimisation of SoapDenovoTrans, VelvetOases (due 10th November 2013)
* **v0.2.0**: add Abyss, SGA and ReadJoiner
* **v0.3.0**: allow optimising pipelines
