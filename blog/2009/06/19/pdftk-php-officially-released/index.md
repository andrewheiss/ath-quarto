---
title: pdftk-php Officially Released
date: 2009-06-19
description: After almost two years, I've officially developed and released pdftk-php--a script that lets you inject form data into a PDF with PHP.
tags: 
  - pdf
  - pdftk
  - pdftk-php
  - php
  - release
---


Wow. It's been almost two years since I wrote [a little tutorial][tut] on how to use LiveCycle, PHP, and MySQL together to make a web application that served dynamic PDF forms. Since then it has become the number one page on this site. I still get a substantial number of comments a week here on the blog and via e-mail—many of those comments are stuck in my inbox, sent to me before I rebuilt my site on WordPress and enabled commenting.

Unfortunately, though, I wrote that tutorial as my first foray into the world of PHP/MySQL web development and had little idea of what I was really doing. Since then, however, I've done a fair amount of real-world web design and development, and even implemented this pdftk form system into a live, public-facing [application][mmlab].

In the interim, I've refined my system and released it as an open source PHP class, named [`pdftk-php`][pdftk-php]. The project is hosted at [GitHub][github], a brilliant hosting service for collaborative projects, which uses Git, the best version control software I've ever used. Anyone can check out, or clone, the project, make any edits to the core set of classes, and merge those with the main project branch—it is now a true community project. If you don't want to contribute, you can still [download it from GitHub][download] as a `.zip` or `.tar` file.

Included in the project is a (hopefully) extensively documented example application that you can set up on your own server.

I'm working on writing a new step-by-step tutorial on how to set everything up, akin to the old one. In theory, the new `pdftk-php` should work with PDFs created in any program, not just LiveCycle. In the meantime, download `pdftk-php`, try it out, and report any bugs here on the blog or [directly at GitHub][issues] (where I hope to keep everything related to `pdftk-php` from now on). Fork the project and contribute if you feel like it, too!

Thanks and good luck!

[tut]: /blog/2007/10/06/populating-a-livecycle-pdf-with-php-and-mysql/ "Populating a LiveCycle PDF with PHP and MySQL"
[mmlab]: http://mmlab.lib.byu.edu "HBLL Multimedia Lab"
[github]: http://github.com "GitHub"
[pdftk-php]: http://github.com/andrewheiss/pdftk-php/ "pdftk-php on GitHub"
[download]: http://github.com/andrewheiss/pdftk-php/downloads "Download pdftk-php at GitHub"
[issues]: http://github.com/andrewheiss/pdftk-php/issues "Report an issue at GitHub"
