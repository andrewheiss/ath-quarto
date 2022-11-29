---
title: Installing pdftk-php
date: 2009-07-29
description: A detailed, updated tutorial on how to install, use, and customize pdftk-php.php, which combines the power of pdftk and PHP, allowing you to serve dynamic PDF forms from the web.
categories: 
  - html
  - pdftk
  - pdftk-php
  - php
  - sh
  - sql
  - text
---


Upon popular request, I've decided to update the original tutorial for populating a LiveCycle PDF with PHP to apply to the new release of pdftk-php. The installation instructions should be mostly clear in the readme and in the inline comments in the example included with the script; this post is merely supplemental.

## Basic usage

### Initial set up

[Download the most recent version of pdftk-php from GitHub](http://github.com/andrewheiss/pdftk-php/tree/master "andrewheiss's pdftk-php at master - GitHub") and [download and install pdftk](http://www.accesspdf.com/pdftk/ "pdftk - the pdf toolkit") on your server.

Unzip the download from GitHub and place the folder on your server. I've placed mine in a folder called `pdftk-php`.

Create a MySQL user and database and run the SQL found in `/example/database.sql` in a MySQL client (like phpMyAdmin) to create the sample database.

![Example Query in phpMyAdmin](example_query_in_phpmyadmin.png "Example query in phpMyAdmin")

Modify the information in `example/_dbConfig.php` so that the application can connect to your database.

```php
$host = "localhost";
$username = "pdftk-user";
$password = "supersecure";
$db_name = "pdftk-php";
```

Browse to the example site (in my case, http://localhost/pdftk-php/example/index.php) and add some entries to populate the database a little.

### Set up the script

Open `pdftk-php.php` and insert the full path to your working pdftk installation at the beginning part of the `passthru()` command near line 71. Here are some examples for different scenarios on server platforms:

```php
// On a typical Unix-based installation
passthru("/usr/local/bin/pdftk ...");

// On Windows, with an absolute path
passthru("c:\pdftk\pdftk.exe ...");

// On Windows, with a relative path (useful if you place pdftk.exe in the server folder structure)
passthru("../pdftk.exe ...");
```

If you're on a Unix-based server and don't know where pdftk is, type one of the following commands, which should result in the absolute path to the program:

```sh
which pdftk
# or
whereis pdftk
```

In `example/download.php` verify that the path to the required `pdftk-php.php` is correct, near line 18. In the example, `pdftk-php.php` is located a directory below the example directory. If you like to store your included files elsewhere, make sure that you modify the `require()` path here.

`pdftk-php.php` needs to be able to write to a temporary directory on your server in order to create a temporary FDF file. This directory is specified near line 58, with the `tempnam()` function.

If you are on a Windows server you should already be able to write to pretty much any directory (I think&hellip; I've never worked with IIS permissions), so you should be good to go. If you are on a Unix-based server you'll need to be more explicit with directory permissions. To make things easier, create a temporary folder on your server and give it write permissions:

```sh
cd pdftk-php
mkdir tmp
chmod 777 tmp
```

Then set the path in `tempnam()` to the new temporary folder.

```php
// If at the same level as download.php
$fdf_fn = tempnam("tmp", "fdf");

// If one directory behind download.php
$fdf_fn = tempnam("../tmp", "fdf");

// You can also use an absolute path
$fdf_fn = tempnam("/Library/WebServer/www/pdftk-php/tmp", "fdf");
```

### Set up the PDF

Create a fillable form in either Acrobat Professional or LiveCycle Designer, or use the included example PDF form. Give each field a unique and significant name so that you can work with the form more easily later on. You can modify field attributes by double clicking on the field using the Forms toolbar in Acrobat; in LiveCycle, use the Object panel.

![Acrobat Form Field Options](acrobat_form_field_options.png "Acrobat Form Field Options")

![LiveCycle Form Field Options](livecycle_form_field_options.png "LiveCycle Form Field Options")

If you are using LiveCycle, you'll need to save the final PDF as a **static** form compatible with Acrobat 7. pdftk doesn't work with dynamic forms or PDFs from later versions of Acrobat.

![LiveCycle Save Options](livecycle_save_options.png "LiveCycle Save Options")

### Connect PDF to script

`example/download.php` connects to your database, retrieves a row based on a passed GET variable, saves the data from the fetched row into variables, finally calling `pdftk-php.php`, which does the heavy lifting of creating an FDF file and injecting it into the PDF.

Starting at around line 30 the script assigns the fetched values to variables. Each of those retrieved variables needs to be paired with a form field in your PDF (near line 39). In a basic Acrobat form this is simple:

```php
$fdf_data_strings= array('firstname' => $pdf_firstname,  'lastname' => $pdf_lastname, 'email' => $pdf_email);
```

LiveCycle tends to complicate the form names slightly. You can use pdftk from the command line to retrieve the official form field names. Run this command from the directory containing your PDF file:

```sh
pdftk form.pdf dump_data_fields > form-fields.txt
```

When you open the resultant `.txt` file you should see a report of all the fields

```text
...
---
FieldType: Text
FieldName: form1[0].#subform[0].firstname[0]
FieldNameAlt: First name&#9;
FieldFlags: 0
FieldJustification: Left
---
...
```

Use those long, hairy `FieldName`s in the `$fdf_data_strings` array, like so:

```php
$fdf_data_strings= array('form1[0].#subform[0].#area[0].FirstName[0]' => $pdf_firstname, 'form1[0].#subform[0].#area[0].LastName[0]' => $pdf_lastname, 'form1[0].#subform[0].#area[0].EMail[0]' => $pdf_email, );
```

Finally, check the values of `$pdf_filename` and `$pdf_original` near lines 62 and 65.

Go to http://localhost/pdftk-php/example/view.php and click on the download links for one of entries. You should be prompted to download a PDF file, dynamically generated using `pdftk-php.php`. Success!

## Advanced customization

### Using checkboxes or radio buttons

`$fdf_data_strings` works great for text fields, but can't handle radio buttons or check boxes. For that you'll need to use the `$fdf_data_names` array near line 49.

*NB: The logic for manipulating the form data in PHP and MySQL might be a little convoluted and could easily be optimized, but it works for clear demonstration purposes.*

To demonstrate this how to do this, we'll add a checkbox to our form and extend the database. Run this query in a MySQL client to add a couple columns to our table:

```sql
ALTER TABLE `users` ADD `option1` TINYINT( 1 ) NOT NULL, ADD `option2` TINYINT( 1 ) NOT NULL ;
```

Open `/example/example.pdf` in Acrobat Professional and add two checkbox fields named `option1` and `option2`.

![Huge Checkboxes](ridiculously_huge_checkboxes_better.png "Ridiculously huge checkboxes")

We need to modify our web form and the table that displays the data, just to make sure everything is getting saved to the database correctly.

First, make a couple changes to `example/index.php` After the section near lines 104&ndash;107, add

```html
<p>
    <label for="option1">Option 1</label>
    <input type="checkbox" name="option1" value="1" id="option1" />
</p>
<p>
    <label for="option2">Option 2</label>
    <input type="checkbox" name="option2" value="1" id="option2" />
</p>
```

Then, up near the top of `example/index.php` after line 34, add this:

```php
if ($_POST['option1'] == 1) {
    $option1 = 1;
} else {
    $option1 = 0;
}

if ($_POST['option2'] == 1) {
    $option2 = 1;
} else {
    $option2 = 0;
}
```

This checks the value of the submitted checkboxes and sets the `$optionx` variables to either 1 or 0, which fit into the `TINYINT` columns in our table. You could use actual text as well and set the columns to `VARCHAR`.

Change the SQL query from

```php
$sql = "INSERT INTO users (firstname, lastname, email) VALUES ('$firstname', '$lastname', '$email')";
```

to

```php
$sql = "INSERT INTO users (firstname, lastname, email, option1, option2) VALUES ('$firstname', '$lastname', '$email', '$option1', '$option2')";
```

Go ahead and insert some dummy submissions with boxes checked and unchecked to make sure everything is working.

Optionally we need to modify `example/view.php` to show the stored values. Add the following table header cells after line 29:

```html
<!-- Already here --><th>E-mail Address</th>
   <th>Option 1</th>
   <th>Option 2</th>
<!-- Already here --><th>Download PDF</th>
```

In the `while` loop a few lines later, add this code:

```html
<!-- Already here --><td><?php echo $user["lastname"]; ?></td>
<td><?php echo ($user['option1'] == 1) ? "Yes" : "No"; ?></td>
<td><?php echo ($user['option2'] == 1) ? "Yes" : "No"; ?></td>
<!-- Already here --><td><?php echo $user["email"]; ?></td>
```

This is just PHP ternary notation, which essentially says that if the value of `optionx` is equal to one, echo "Yes," otherwise, echo "No".

Finally we need to modify `example/download.php` to handle our checkboxes. Like I said above, the `$fdf_data_names` variable handles checkbox and radio button data. In PDF forms, the two allowed values for checkboxes are "Yes" and "Off" (not really opposites, but oh well), so you'll need to set variables accordingly. Replace `$fdf_data_names = array();` near line 49, with this, which checks the values of `optionx` and sets `$pdf_optionx` to either "Yes" or "Off" and then defines the `$fdf_data_names` array appropriately:

```php
if ($data['option1'] == 1) {
    $pdf_option1 = "Yes";
} else {
    $pdf_option1 = "Off";
}

if ($data['option2'] == 1) {
    $pdf_option2 = "Yes";
} else {
    $pdf_option2 = "Off";
}

$fdf_data_names = array('option1' => $pdf_option1, 'option2' => $pdf_option2);
```

And that should do it! Visit http://localhost/pdftk-php/example/view.php and download one of the forms. The checkboxes should populate perfectly.

### Other types of form fields

Combo boxes and radio buttons act similarly to checkboxes. If you run the `dump_data_fields` command with pdftk again on a form with these more advanced options, you'll see a few differences in the results.

```text
FieldType: Text
FieldName: email
FieldFlags: 0
FieldJustification: Left
---
FieldType: Button
FieldName: option1
FieldFlags: 0
FieldValue: Yes
FieldJustification: Left
FieldStateOption: Off
FieldStateOption: Yes
---
FieldType: Choice
FieldName: favoriteColor
FieldFlags: 131072
FieldValue: blue
FieldValueDefault: red
FieldJustification: Left
```

You can see the "Yes" vs. "Off" values in our checkbox (called "Button" in PDF lingo). Drop down lists ("Choice" in PDF-speak) have multiple values, specified by you when you create the field.

![Combo box properties](combo_box_properties.png "Sample combo box properties in Acrobat")

Radio buttons are hybrids. They are considered "Buttons," like checkboxes, but can have custom values, like drop down lists.

Your final PHP script will need to take these different values into account and assign the correct values in the `$fdf_data_names` array.

## Conclusion

You can do a ton with the `pdftk-php.php` class once you get it set up initially and get past the slight learning curve. If you have any questions, feel free to ask in the comments. If you find any problems, comment here or [open an issue at the GitHub project page](http://github.com/andrewheiss/pdftk-php/issues "Issues - andrewheiss/pdftk-php - GitHub"). Additionally, you can [fork the project](http://github.com/andrewheiss/pdftk-php/tree/master "andrewheiss's pdftk-php at master - GitHub") and contribute.

Good luck!
