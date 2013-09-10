assemblotron
============

Automated optimal *de-novo* assembly.

Assemblotron rapidly discovers the optimal settings for an assembler or assembly pipeline and performs the best possible assembly using the tools available.

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

### Roadmap

| Class                    | Code   | Tests   | Docs   |
| ------------             | :----: | ------: | -----: |
| BadReadMappings          | DONE   | -       | -      |
| ReciprocalBestAnnotation | DONE   | -       | -      |
| UnexpressedTranscripts   | DONE   | -       | -      |
| CLI                      | -      | -       | -      |

| Assembler       | Definition | Constructor | Tests |
| --------        | :---:      | :----:      | :---: |
| SoapDenovoTrans | DONE       | DONE        | DONE  |
| VelvetOases     | -          | -           | -     |
| ABYSS           | -          | -           | -     |
| SGA             | -          | -           | -     |
| ReadJoiner      | -          | -           | -     |


* ~ 6/27 tasks completed, ~22% done overall
* planned alpha release date (v0.1.0a): 17th September 2013
* planned beta release date (v0.1.0b): 24th September 2013

## Expectations for imminent versions

* **v0.1.0**: allow optimisation of SoapDenovoTrans, VelvetOases
* **v0.2.0**: add Abyss, SGA and ReadJoiner
* **v0.3.0**: allow optimising pipelines