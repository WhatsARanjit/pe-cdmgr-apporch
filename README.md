# pe-cdmgr-apporch [![Build Status](https://travis-ci.org/WhatsARanjit/pe-cdmgr-apporch.svg?branch=2016.1)](https://travis-ci.org/WhatsARanjit/pe-cdmgr-apporch)

#### Table of Contents
1. [Overview](#overview)
1. [Requirements](#requirements)
1. [Usage](#usage)

## Overview
A Vagrant environment with setup with advanced features of PE.

## Requirements
- PE 2017.1.x
- Vagrant >= 1.7.4
- Virtual Box >= 4.3.30r101610

## Usage
~~~
vagrant up
# wait
vagrant ssh
~~~

### Where is everything?
1. Console is available at `https://10.20.1.2:8443`.
Login with user: `admin` and password: `puppetlabs`.
1. A role named `Code Deployers` is created with
permissions to deploy code and orchestration jobs.
1. A user named `deploy` lives in the above group
with password `puppetlabs`.
1. An eternal login token for the above user lives
at `/root/.puppetlabs/token`.
