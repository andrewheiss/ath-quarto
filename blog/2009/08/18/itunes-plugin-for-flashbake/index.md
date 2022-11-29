---
title: iTunes plugin for Flashbake
date: 2009-08-18
description: Flashbake-iTunes is a plugin for Flashbake that allows you to include information for the current track in the periodic git commit message.
categories: 
  - flashbake
  - git
  - writing
---


[Flashbake](https://github.com/cmdln/flashbake "Home - flashbake - GitHub") is a fantastic script [for nerdy writers](http://lifehacker.com/5232049/flashbake-automates-version-control-for-nerdy-writers "Flashbake Automates Version Control for (Nerdy) Writers - Downloads - Lifehacker") (like me) that periodically commits changes to a Git repository and can optionally append various metadata to the commit message, allowing you to [annotate the entire creative process](http://www.boingboing.net/2009/02/13/flashbake-free-versi.html "Flashbake: Free version-control for writers using git - Boing Boing").

Flashbake includes several plugins for adding recent tweets, weather, the current time zone, and other random information. There's even a plugin for the Banshee music player for Linux. There's nothing for iTunes, however, which is unfortunate since I'm always listening to something when I write or code.

So I hacked together a little plugin for Flashbake that uses AppleScript to get the current track information from iTunes and add it to the commit message. It's admittedly a "frankenscript" and only works on Mac OS X (since it relies on AppleScript), but it works great. 

[You can get it at GitHub](http://github.com/andrewheiss/Flashbake-iTunes/ "andrewheiss's Flashbake-iTunes at master - GitHub"). Enjoy!
