# Using Amazon S3 and Blogger for family history 

The easiest way to share large scans of family history journals is through the internet, using a combination of Amazon S3 (for storage) and Blogger (to display and present the files). Getting the system set up is relatively easy; once it's set up it's even easier to use.

# Amazon S3

Besides selling everything in the world, Amazon offers a ton of web services: cloud computing, database management, content delivery networks, and other nerdy development things. One of their best and most convenient offerings is S3, or Simple Storage Service—essentially a giant hard drive in the cloud. Storage costs are minimal ([$0.095 per GB](http://aws.amazon.com/s3/pricing/)), so you can store a ton of stuff safely online.

To get started, go to [http://aws.amazon.com/s3/](http://aws.amazon.com/s3/) and create a free account. 

![Create a new account](https://www.evernote.com/shard/s1/sh/da7b64d2-16be-40d5-ac0a-3e5741eb1e2a/4d321153e2209ece349c2afdad22a2a8/deep/0/Amazon%20S3,%20Cloud%20Computing%20Storage%20for%20Files,%20Images,%20Videos.png)

Log in with your Amazon account and follow the instructions. Eventually you'll come to your Amazon Web Services console at [https://console.aws.amazon.com/console/home](https://console.aws.amazon.com/console/home), where you can access the dashboard for S3

![S3 on the AWS console](https://www.evernote.com/shard/s1/sh/93199e45-6db9-46ba-93fa-abd7519a7182/677137a4cd468d4a8a625b05e3959c52/deep/0/AWS%20Management%20Console%20Home%20and%20Amazon%20and%20Blogger.md%20and%20Windows%208%20%5BRunning%5D.png)

S3 lets you create an unlimited number of "buckets" for storage. Buckets aren't quite like folders—they're more like actual hard drives. As you can see in the screenshot below, I have buckets for a bunch of different things, like blog files (where we upload our Christmas newsletter), and other stuff. You can create as many buckets as you want at no cost—you're only charged for storage space. So for this you'd probably want just one bucket for all the family history stuff you're doing, with multiple folders inside that bucket. Click on "Create Bucket" to create a bucket (obviously).

![Create a new bucket](https://www.evernote.com/shard/s1/sh/a3f0ee8d-6889-41aa-8325-459e4f51263f/b159fe4e5f39add46257b94a3b43ae8a/deep/0/S3%20Management%20Console.png)

Give your bucket a unique name ('familyhistory' didn't work for me) and click "Create." You don't need to worry about the "Set Up Logging" thing.

![New bucket dialog](https://www.evernote.com/shard/s1/sh/ae21190c-76b4-43b8-a94d-cb1a2533d93d/0a7807b4face0a31c70a048452775ccc/deep/0/S3%20Management%20Console.png)

You should now have a new bucket in your bucket list (pseudo pun!). 

![New bucket in the list](https://www.evernote.com/shard/s1/sh/f9e3a235-31eb-48f2-a113-8217b141e1da/a4d7e8cf9dea2518d9ec0da16269e113/deep/0/S3%20Management%20Console.png)

Click on the new bucket to see its contents. Nothing's there! Click on "Create Folder" to, um, create a folder.

![Create a new folder](https://www.evernote.com/shard/s1/sh/f58d7685-f358-45c4-89e8-f5e6ebff0afd/43b2c695132666169a86cd9569659791/deep/0/S3%20Management%20Console.png)

By default, the folders that you create will be private and only accessible by you (since lots of companies use S3 to store user data). You'll need to make any new folders publicly accessible by right clicking on them and choosing "Make Public":

![Make that folder public](https://www.evernote.com/shard/s1/sh/227814ed-8b2a-41a3-8012-49f0b0ea4ff2/59f2b434a266fb45572598f8c06b045e/deep/0/S3%20Management%20Console.png)

Now anything you put in that folder will have a publicly accessible URL. Magic.

That's it! You've set up S3! Now you need to put stuff in those folders.


# Add files to S3

Now that you've set up S3, you have everything you need to upload files and share their URLs. There are two general ways to add files to your S3 bucket: (1) using the S3 website and (2) using a 3rd-party program. Both are really easy to do, and both let you quickly get publicly accessible and shareable URLs.

## Use the S3 website

Log into the your S3 console at [https://console.aws.amazon.com/s3/](https://console.aws.amazon.com/s3/). Open the bucket and folder you want to upload to. Then click "Upload":

![Upload file to S3](https://www.evernote.com/shard/s1/sh/69cea7d9-5b53-4b7e-b222-9e1cebbca9b7/347b8af7d56dcd24d32f01478244cfc5/deep/0/S3%20Management%20Console.png)

Click "Add Files" to select the files on your computer that you want to upload, then click "Start Upload." Alternatively, you can click the "Enable Enhanced Uploader (BETA)" link to upload whole folders. I've never done this, but it probably works.

![Upload dialog](https://www.evernote.com/shard/s1/sh/a05d4278-4675-4837-8b00-115f48d3d416/02e8608088589bb42d31295a708d3061/deep/0/S3%20Management%20Console.png)

You can then look in the folder to see a list of the files you've uploaded. If you click on one of the files, you'll get a screen of summary information, including a publicly accessible URL. 

![File properties](https://www.evernote.com/shard/s1/sh/ce8ae7a8-2288-4fcc-9ae7-ec9f55129212/7df83e1d0a8af05b2c5cb0be3d4d4069/deep/0/S3%20Management%20Console%20and%20Messages.png)

Copy that, paste it in a browser tab, and the file will download. Send that link to anyone and they can download it. Paste that link into a blog post and people can click it and download the file. Magic.


## Use a 3rd-party program

Rather than use the S3 website, I find it easier to use a different program that lets you drag and drop files from your computer to the S3 server and quickly get their URLs. The best (and free-est) program is called [Cyberduck](http://cyberduck.ch/). Go to [http://cyberduck.ch/](http://cyberduck.ch/) and download the Windows version and install it on your computer.

![Download Cyberduck](https://www.evernote.com/shard/s1/sh/e5c575e2-e84c-48a7-a420-cf5d944bcfcf/f8dd031ea60fbd77f06a92dd83d9c632/deep/0/Windows%208%20%5BRunning%5D.png)

Once it's installed, you can use Cyberduck to connect to S3. The best way to do this is to save your connection information inside Cyberduck as a bookmark. Click on Bookmark > New Bookmark to create one.

![Create new bookmark](https://www.evernote.com/shard/s1/sh/6ee1a9b9-ca8f-4faa-9d9c-5e23adadfd5a/be6722250f2430dab14fcddf05234bcc/deep/0/Windows%208%20%5BRunning%5D.png)

In the new bookmark dialog box, change the "FTP (File Transfer Protocol)" to "S3 (Amazon Simple Storage Service)"

![Select S3 from the list](https://www.evernote.com/shard/s1/sh/fdced94f-0280-4588-8e81-07703c30791b/b4826792417ebc83d3393823142db3c2/deep/0/Windows%208%20%5BRunning%5D.png)

Give the bookmark whatever nickname you want. Leave the server information as is. You can find your access key ID at the S3 website. Click on your name in the top right corner and select "Security Credentials" from the menu.

![Security credentials](https://www.evernote.com/shard/s1/sh/a5bf2b52-1f89-4fb8-bd36-94360c9c42ca/2a0e145f43af22baaef35e69d08dc61d/deep/0/S3%20Management%20Console.png)

If you get some warning or message about AWS Identity and Access Management, ignore it and click "Continue to Security Credentials".

Click on Access Keys and click on "Create New Root Key" to generate a new access key ID and secret access key. Copy these and save them somewhere safe.

![New credentials](https://www.evernote.com/shard/s1/sh/219e7e2b-a7dc-434a-bab2-28401470abf3/01c8c3ce1caa0918abf8bc8b08e64145/deep/0/IAM%20Management%20Console.png)

Paste the access key ID into the Cyberduck bookmark and then close the bookmark editing dialog (for some reason it won't let you enter the password until you try to connect to the server). 

![Finish the bookmark](https://www.evernote.com/shard/s1/sh/090f3c78-1969-48a6-bf47-801f7cb77d8a/6721614d42ed8da84db5fdbf09b0e004/deep/0/Windows%208%20%5BRunning%5D.png)

Once the bookmark dialog is closed, you'll see the bookmark in the list of bookmarks. Double click on it to connect. Since this is your first time connecting, it'll ask for your password. Paste in the huge crazy long secret access key, make sure "Save password" is checked, and click "Login"

![Log in](https://www.evernote.com/shard/s1/sh/f0124947-3d24-4b67-bb6c-0ac248fc9e08/05c126fd5779bb132df2f5e1fb83020d/deep/0/Windows%208%20%5BRunning%5D.png)

You'll see a list of your buckets, just like on the website. Double click on the bucket you created to open it and see the folders. 

To upload stuff, just drag files from your computer into folders in Cyberduck. You can even drag entire folders.

Getting a URL for a file in Cyberduck is super easy. Right click on a file, go to "Copy URL" and choose "HTTP URL" (all the others are for other things you don't need)

![Copy the file's URL](https://www.evernote.com/shard/s1/sh/53bc0c89-6f35-460b-961a-3c85d267a8dd/acee76d8b1415759576770dd2d93666c/deep/0/Windows%208%20%5BRunning%5D.png)

Sometimes when you reopen Cyberduck, it'll try to open the last folder it was in. If you want to get back to the list of bookmarks, click on the little bookmark icon near the top:

![Bookmark icon](https://www.evernote.com/shard/s1/sh/ab21d88b-13ad-4c54-b7d6-659c83133259/b4db3a552fa72040783965855779fc1c/deep/0/Windows%208%20%5BRunning%5D.png)

**There's only one caveat!** Folders in S3 are private by default. If you drag a folder from your computer into the main root of the bucket (i.e. not into a folder you've already set as public), it'll be private. You can either (1) log into the S3 website and right click on the folder to make it public, or (2) upload stuff to an already public folder. An easy way around this would be to create one main folder for uploaded stuff within your bucket and upload all other files and folders there—then anything you upload will automatically be public as well.


# Putting it all together

Now that you've done the hard steps of setting this up, here's how you can use everything in the future.

## Using Cyberduck

1. Open Cyberduck.
2. Double click on the S3 connection in the bookmark list.
3. Navigate to the folder where you want to upload stuff.
4. Drag files from your computer into Cyberduck.
5. Right click on the files to get their public URLs.
6. Do something with those URLs.

## Using the S3 website

1. Log into S3 at [https://console.aws.amazon.com/s3/](https://console.aws.amazon.com/s3/)
2. Navigate to the folder where you want to upload stuff.
3. Upload files.
4. Click on the files and find their URLs in the file properties screen.
5. Do something with those URLs.

## Distribute the URLs

Once your files are in the cloud on S3, all you need to do is get their URLs and distribute them somehow.

Ideally you could then make some curated blog posts in Blogger, like this:

> Joseph Stacey Murdock was born in X in Y. He had Z kids. Blah blah. He left several personal journals. The first (http://the-url-for-the-first-journal) was found in 1893 and talks about stuff. The second (http://the-url-for-the-second-journal) was found later and talks about other stuff. These are cool.

Alternatively, if someone in your family wants a specific journal or scan, you can open Cyberduck, find the file, copy the URL and send it to them (rather than tracking down the specific blog post).

That's all!