---
title: True side-by-side page numbers in InDesign
date: 2013-03-15
description: Automatically create side-by-side page numbers for parallel texts or spread numbers in InDesign. 
categories: 
  - arabic
  - graphic design
---


The books I make for the Middle East Texts Initiative contain side-by-side English-Arabic translations of old Arabic, Hebrew, and Latin texts. InDesign can generally handle the side-by-side parallel stories and text frames, but it cannot properly number the pages. After all the front matter and introductory text, the English translation starts on a verso page (left) with page 1, followed by a page of Arabic on the recto (right), also on page 1. The next verso is page 2.

InDesign doesn't include a way to insert automatic spread numbers instead of page numbers, which means there's no easy way to have automatic parallel, same-numbered pages. For years users have come up with kludgy solutions, like:

* Making a list of page numbers in Excel and placing that list in a threaded text box on every master page (kind of like [this](http://indesignsecrets.com/making-numbered-tickets.php))
* [Placing a document of empty lines](http://indesignsecrets.com/create-spread-numbers.php) to take advantage of InDesign's automatic paragraph numbering
* [Making a special text variable](http://indesignsecrets.com/create-spread-numbers.php#comment-497592) for each page ([automated version](http://benmilander.com/content/number-spreads-free-script))

These methods all work, but with one big caveat—they don't deal with any of the *actual* page numbers. If you try to build an automatic table of contents after using any of these methods, you'll get page numbers, not the spread numbers. Similarly, the exported PDF will show page numbers instead of spread numbers.

The only real way to get true side-by-side numbering is to create new sections for each page. Right click on one of your pages, start a section at page 1. Right click on the next page, start a section at page 1 with some prefix (so there aren't duplicate pages). Right click on the next page, start a section at page 2. And so on for the all the side-by-side pages.

Crazy tedious. But totally automatable with a script. [Find said script at GitHub](https://github.com/andrewheiss/Side-by-side-page-numbers-in-InDesign).
