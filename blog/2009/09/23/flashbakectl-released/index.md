---
title: flashbakectl released
date: 2009-09-23
description: flashbakectl is a handy little script that starts and stops Flashbake by loading and unloading plist files.
categories: 
  - flashbake
  - git
  - writing
---


Adding to my apparent [series of Flashbake addons](http://www.andrewheiss.com/blog/2009/08/18/itunes-plugin-for-flashbake/ "iTunes plugin for Flashbake  &#8211;   AndrewHeiss.com"), I've just released [`flashbakectl`](http://github.com/andrewheiss/flashbakectl "andrewheiss's flashbakectl at master - GitHub").

Normally to run [Flashbake](https://github.com/cmdln/flashbake "Home - flashbake - GitHub") consistently you need to set up a cron job. While OS X is built on Unix and has cron, Apple recommends using `launchd` and property list (plist) files to run system agents and daemons. `flashbakectl` is a handy little script that loads and unloads a plist for you. 

Before working on your project, run `flashbakectl -l` to load the plist and start the daemon, which will commit your unsaved changes every 15 minutes (or whatever you set it to). When you're done for the day, run `flashbakectl -u` to stop the daemon, saving your computer from unnecessarily running Flashbake *ad infinitum*.

`flashbakectl` only works on Mac OS X. [You can get it at GitHub](http://github.com/andrewheiss/flashbakectl "andrewheiss's flashbakectl at master - GitHub"). Enjoy!
