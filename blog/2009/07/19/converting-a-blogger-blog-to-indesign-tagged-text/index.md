---
title: Import a Blogger Blog to InDesign with Perl
date: 2009-07-19
description: This Perl script lets you take a backed-up Blogger XML file and convert it to an InDesign Tagged Text file for book layout.
categories: 
  - blogger xml
  - indesign
  - indesign tagged text
  - perl
---


Our family has a fairly sizable [blog](http://www.heissatopia.com "Heissatopia") that we (actually, mostly my wife, Nancy) have kept updated for several years. Since it contains so much family history we wanted an easy way to preserve it in print form, just in case Blogger gets the boot from Google some day (not that that will ever really happen…).

Since we're both hobbyist graphic designers—I taught a couple print layout and design classes as an undergrad at BYU and have made several books at [Lulu.com](http://www.lulu.com "Lulu.com")—we decided to layout and print each year of our blog, to keep for posterity.

A couple years ago Nancy attempted this with our smaller [Jordan blog](http://andrewheiss.blogspot.com "Adventures in Jordan") for a print publishing class she took at BYU. We spent the bulk of our time manually copying and pasting each post and the subsequent comments into a huge Word document. She then ran a long series of find/replaces to clean up the messy, inconsistent typography, and then finally placed it into Quark (that evil program). Through a series of unfortunate events, Quark crashed repeatedly and corrupted her file multiple times—she was lucky to get her first draft turned in for her final project (she got an A, though. Phew!).

I knew there had to be a faster, more efficient way to wrangle all the blog text, but this was back in 2006, before Blogger had an open API or options to backup a blog. Primitive, dark days indeed :).

However, last year, Blogger introduced a fantastic new option—the ability to backup and export your entire blog, comments and all. Blogger spits out an Atom-formatted XML file that you can use to recreate your blog later on (or possibly import onto other platforms, like WordPress, I think). This was the key to simplifying the daunting task of collecting the text for our blog books. All we needed was a way to mangle the text in the XML file to create an InDesign-ready file.

So, I whipped up a semi-complicated Perl script that can parse an Atom-formatted XML file from Blogger and create a text file using InDesign Tagged Text to preapply paragraph and character styles. It also cleans up the typographic elements of the text, adding em and en dashes, removing empty paragraphs, etc. Additionally, it can add hidden index entries for each tag, essentially creating a barebones index for your book. And it only takes 10ish seconds to run on a large blog. It's not perfect and could stand some good optimization, but it works.

Additionally, since InDesign tagged text works with, well, text, it won't place your images for you. Instead it will insert the location of the image (the `src=whatever.jpg` of the `img` tags) in between curly braces `{ }`. You'll then need to manually place all the images later, deleting the braced text.

In the future, the script could be changed to output XML, which does let you include pictures, but you'd have to have all your images on your hard drive already. The script could go and download all the linked images, but it's not really a good idea to place low resolution, web-optimized images in a print document. In our case we have high-res copies of all the pictures on the blog stored on an external hard drive, so we just have to go and find and place the images we want. It takes more time, but it makes better quality documents in the end.

Also, links are preserved as footnotes—all `href="whatever.html"`s show up as the footnote text.

### How to use the script

First, download the script and its supporting files from [Github](http://github.com/andrewheiss/Blogger-XML-to-InDesign/tree/master "andrewheiss's Blogger-XML-to-InDesign at master - GitHub"). If you're using Mac OS or Linux, make sure the main script file, `format_for_id.pl` is executable—type `chmod +x format_for_id.pl` at the terminal.

Next, make sure you have Perl installed on your system. If you are using Linux or Mac OS X, you're good to go. If you're using Windows, download and install [Strawberry Perl for Windows](http://strawberryperl.com/ "Strawberry Perl"). You can also use [ActivePerl](http://www.activestate.com/activeperl/ "ActivePerl"), but installing modules is a little more difficult.

The script uses several additional [CPAN modules](http://en.wikipedia.org/wiki/Cpan "CPAN - Wikipedia, the free encyclopedia") that you'll need to install. You'll need to use the CPAN shell to do so.

* On Windows with Strawberry Perl: open the packaged CPAN client in the Start Menu folder
* On Windows with ActivePerl: Good luck. There is a large repository of specially compiled CPAN modules for ActiveState, and reportedly there is a kind of CPAN shell, but I haven't gotten either to work too well. Stick with Strawberry Perl. It's better :)
* On Mac OS X: type `perl -MCPAN -e shell` at a terminal window
* On Linux: type `sudo cpan` at a terminal window

(If it's your first time running the CPAN shell you'll be asked to configure the installation environment. Choose the option to automatically configure everything.)

Once everything is set up and you see the `cpan>` shell prompt, type `install Package::Name` (eg. `install Date::Format`) for each of the dependent CPAN packages listed at the beginning of `format_for_id.pl`.

Log in to your [Blogger Dashboard](http://www.blogger.com/home "Blogger.com") and export your blog as an XML file by going to Settings &gt; Basic &gt; Export blog. Place the XML file in the script folder.

Open `config.cfg` with a text editor and change the settings as needed. Set the input file to your newly downloaded XML file, choose the year you want to extract, set an output file, and set the file header, either &lt;`UNICODE-MAC`&gt; or &lt;`UNICODE-WIN`&gt;, depending on what platform you use InDesign on.

For now, leave all the style tags as they are so you can place the text into the example InDesign file and see how everything works. You can change them later and rerun the script

Finally, using the terminal or command prompt, navigate to the folder with the script and and run it by typing `perl format_for_id.pl`. If everything goes well you should have an output file at the location you specified, full of InDesign tags.

Open up `Example.indd` in InDesign CS3 or above and place the generated text file. All the text should come in perfectly with all the needed paragraph and character styles applied. Bravo!

### Advanced usage

Obviously you'll want to make some changes to the format of the output text. You might not want the post URL right after the tag—you might want it at the end, or not want it at all. With a little knowledge of Perl, you can edit the main script directly, mostly the `combineSortClean()` sub near the end of the script, to change the order of the output elements.

You can also disable tag indexing and allow the tags to be output with a paragraph style. Just comment and uncomment the appropriate sections in the code. The same goes for the author-specific character styles—comment and uncomment the needed lines in the script.

You can rename the styles and use your own—just make sure the styles exist in your InDesign document before you place the output file. InDesign will throw away any tags that don't already exist in the document.

I made the script for our specific blog, so it doesn't take every possible paragraph or character style into account. If you want additional functionality, you'll have to add it. Feel free to fork the project off of GitHub and add to/improve it. That's why it's open source :)

If you have any questions, ask in the comments. Report any issues at the [project GitHub page](http://github.com/andrewheiss/Blogger-XML-to-InDesign/issues "Issues - andrewheiss/Blogger-XML-to-InDesign - GitHub"). I'll try to respond quickly—I generally do, as evidenced by my [pdftk-php project](/blog/2007/10/06/populating-a-livecycle-pdf-with-php-and-mysql/ "Populating a LiveCycle PDF with PHP and MySQL  –   AndrewHeiss.com") :)

Good luck!
