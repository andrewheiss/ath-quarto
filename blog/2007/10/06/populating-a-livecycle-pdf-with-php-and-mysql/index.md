---
title: Populating a LiveCycle PDF with PHP and MySQL
date: 2007-10-06
description: Tutorial explaining how to populate a LiveCycle PDF form using PHP and MySQL.
categories: 
  - mysql
  - pdftk
  - php
  - sh
  - sql
  - text
---

::: {.callout-warning}
This tutorial is officially defunct. It is only here for archival purposes. The main script has been consolidated into one PHP class—<a href="http://www.andrewheiss.com/blog/2009/06/19/pdftk-php-officially-released/">pdftk-php</a>. Please see <a href="http://www.andrewheiss.com/blog/2009/07/29/installing-pdftk-php/">the updated tutorial</a>.
:::

I work in the Harold B. Lee Library Multimedia Lab where we check out digital video and still cameras, tripods, external hard drives, digital voice recorders, and let people use $8,000 Quad Core Intel Macs. Expensive stuff…

To insure a “you break it, you pay for it” system, we require all patrons to fill out a loan agreement that we then keep on file. We've been using this system for several years and now have more than a thousand forms—all completely unorganized and out of date. We have no way of knowing if a patron has graduated. We have no way of seeing if a patron has filled out a form previously.

So, I volunteered to fix the problem and move the entire loan agreement system to an online database. I had dabbled in LiveCycle and PHP but had never touched MySQL. So I decided to figure it all out.

I'm assuming you already have a server set up with PHP and  MySQL. If not, you can download [WAMP](http://www.wampserver.com/en/) or [MAMP](http://www.mamp.info/en/mamp.html) and set up a local server on your computer for testing.

I'm also assuming you have some knowledge of HTML and PHP. If not, search for some PHP tutorials on Google and get a foundation there.

#### Adobe LiveCycle

Adobe's LiveCycle PDF Form software works great creating fillable PDF forms and then gathering the form data electronically. Collecting the data is relatively easy since LiveCycle uses semi-open file formats for data storage. For example, if you have an e-mail submit button in your LiveCycle form, a specially formatted XML file will be e-mailed to whatever address you set in the button properties. LiveCycle can then input that XML and repopulate an empty form.

Adobe even sells the LiveCycle Enterprise Suite, which is basically a specialized server made for generating and repopulating PDFs from submitted data. The Enterprise Suite is extremely expensive though

#### Create form in LiveCycle

Unfortunately LiveCycle Designer does not work like the rest of the Adobe CS3 products. I spend most of my time in InDesign, and from a typographic point of view, Designer is pathetic and a little difficult to work with.

Creating the form is relatively straightforward, regardless of the limitations. Drag text boxes and image boxes from the Library panel to add static text and images. Drag text input boxes from the Library to make fillable fields. Actually laying out and designing the form is not the scope of this tutorial, so I won't go any further with that.

#### Data Bindings

What concerns us most is data submission and population with form fields, so we need to set up our fields to work. If you click on a text field, you should have three tabs in the Object panel (if you don't have an Object panel, go to Window &gt; Object).

The Field tab lets you set some basic properties for the field, like whether or not the field can have multiple lines, the line length, the display pattern for phone numbers or other number patterns, the caption, and a plethora of other things. The Value tab allows you to do some scripting for validation of your fields. I tried getting this to work, but since I'm not a programmer at all and don't really know Javascript, I gave up.

The Binding tab is the most important for our purposes. By default your field will have a basic name like `TextField1`. You should change the names of all your fields to a more canonical naming system, like FirstName, LastName, EMail, etc. You can also change the data patterns and formats for text, XHTML, or dates.

#### Submit Through HTTP

For my purposes, I wanted patrons to be able to fill out this PDF from anywhere and then submit it online, regardless of e-mail accounts. To best do this, drag an HTTP Submit Button from the Standard section of your Library. For this button to do anything, you need to set a URL that will receive the data in the form of HTTP POST.

#### Begin Setting Up Your Web Application

I made several different PHP files in the process of getting this all to work. First I wanted to verify what the HTTP POST values were before I started trying to process them. I adapted this code from [Steve Tibbett](http://blogs.adobe.com/stevex/2006/06/submit_to_php.html), an actual Adobe guy.

[Download text for dump.php](dump.php.txt)

Create a file called dump.php and paste this code into it (or remove the .txt extension). Set your HTTP Submit Button URL to dump.php (in my case it was http://localhost/PDFStuff/dump.php) and preview your PDF in Designer. Submit your data and you'll see all the variables and the raw post data. *This step is  only to verify that the HTTP POST variables actually match up with your Designer field names.*

Now that we know that the HTTP POST variables are actually working, we need to save them to a database. You'll need to first set up a MySQL table or database. Since I had never done this, I followed [some tutorials here](http://www.phpeasystep.com/index.php), which were extremely helpful in understanding how to actually use MySQL.

Use PHPmyadmin and create a new PDFStuff database with a username and password and then create a table in it with the following command (or use the GUI form in PHPmyadmin to create the table—either way works):

```sql
CREATE TABLE `PDF_Loans` (
`id` int(4) NOT NULL auto_increment primary key,
`FirstName` varchar(65) NOT NULL default '',
`LastName` varchar(65) NOT NULL default '',
`EMail` varchar(65) NOT NULL default '',
) TYPE=MyISAM AUTO_INCREMENT=0 ;
```

You now have a table in your database where we can store our PDF form variables. Paste this code into a file called insert.php and change the PHP variables as necessary, both for your MySQL connection information and your HTTP POST variables (here I just use FirstName, LastName, and Email).

[Download text for insert.php](insert.php.txt)

Change the URL of the HTTP POST button to insert.php (again, in my case it's http://localhost/PDFStuff/insert.php) and try submitting some data with your PDF form. It should work.

#### Viewing Data in the Database

To actually see your submitted data, create a new php file  called view.php and paste this code in, changing it as necessary.

[Download text for view.php](view.php.txt)

This page will take all the data from your database and display it in a table. You should see one record—the one you just added. There is also a column for a link to view the PDF, although the link is blank for now. Add several more through LiveCycle to make sure it's working.

#### PDF Madness

If you've already had PHP/MySQL experience, all of that was easy. Now comes the tricky part—repopulating the PDF form from the MySQL.

To get this to work, we need to convert the MySQL data into an FDF file, or the Adobe file format for storing form data. We then need to infuse the FDF file into our empty PDF form and allow the user to download it.

Fortunately, someone else figured out the bulk of this, at [www.pdfhacks.com](http://www.pdfhacks.com/). Download [pdftk](http://www.accesspdf.com/pdftk/) and [forge_fdf.php](http://www.pdfhacks.com/forge_fdf/) place them in your main site directory. Forge\_fdf.php will take your data and transform it into an FDF file while fdftk will insert that FDF into your PDF. All you need to do is add some variables.

Before creating your variables, you need to discover the real names for all of your fields. If you made your PDF in Acrobat, the field names *should* be identical, but if you used Designer, the official code-based names will be much longer. fdftk can discover those names for you and dump them in a text file.

Place your empty PDF form in your main site folder. Open up a command prompt or terminal and run this command in the site folder, changing file names as necessary:

```sh
$ pdftk form.pdf dump_data_fields > form.pdf.fields
```

Open up the newly created form.pdf.fields file in Notepad and you'll see the automatic fdftk output, which will look something like this:

```text
FieldType: Text
FieldName: form1[0].#subform[0].#area[0].FirstName[0]
FieldNameAlt: First Name:
FieldFlags: 2
FieldJustification: Left
```

The FieldName in this case is long and hairy, but we'll need that full name for the data insertion to work.

#### Dynamic Data Insertion

Now we're ready to put all the pieces together. Make a file called viewpdf.php and paste this code in, changing as necessary:

[Download text for viewpdf.php](viewpdf.php.txt)

If you don't want the form flattened (i.e. you want to  maintain the form fields), take out the ` – flatten` command.

Notice how the long names had to go in to the `$fdf_data_strings` array.

To populate the PDF from your view.php table, you need to pass those long field names into viewpdf.php. Technically you would need to change the links in view.php to include the row id number for each row, so the PDF is generated using only the information from that row. Fortunately, we can have PHP and MySQL write all those links dynamically.

We originally set up the database so that every time you insert a record, an auto-id number would be assigned. We can reference that id number to view the PDF for that specific row entry.

You pass the id variable into the viewpdf.php file by adding `?id=1` onto the URL (for example, viewing the PDF for record number three would be `viewpdf.php?id=3`).

PHP and MySQL can automatically generate that messy link for every record in the table. Just replace `<a href="#">View PDF</a>` in view.php with `<a href="viewpdf.php?id=<?php echo $rows['id']; ?>">View PDF</a>`

Open up view.php and see your dynamically generated table. You should have dynamic links that point to `viewpdf.php?id=whatever`. If you click on one of the links, the code in viewpdf.php will be processed for that row and a PDF will be generated and flattened and downloaded.

Voila!

I was only able to get this to work with text fields, although it is possible to do this with check boxes and other form elements. You'll have to consult the fdftk documentation to see what variables need to be set for other form elements.

This is a bare bones implementation of PDF population. In real life this is implemented a lot better—i.e. I have my view.php file accessible only after logging in and all the pages are styled with CSS to look nicer.

Hopefully this all made sense. If you want to view the original tutorials I used for this, visit:

* [MacTech Tutorial](http://www.mactech.com/articles/mactech/Vol.20/20.11/FillOnlinePDFFormsUsingHTML/index.html)—Explains how to do this using an HTML submission form rather than a PDF form. This was the basis for my tutorial.
* [MacTech Example](http://accesspdf.com/html_pdf_form/)—Working example of a PDF being populated by HTML.
* [PHPeasy](http://www.phpeasystep.com/index.php)—Basic PHP/MySQL tutorials.
