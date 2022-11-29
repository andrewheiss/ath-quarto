<HTML>
<HEAD>
  <TITLE>HTTP POST Dump</TITLE>
</HEAD>
<BODY>
<h1>HTTP POST Dump</h1>
This page will show you what you just submitted through HTTP POST. It's adapted from <a href="http://blogs.adobe.com/stevex/">Steve Tibbett's</a> HTTP Request Dump.
<h2>Submitted Variables</h2>
<pre>
<?PHP
echo $content_type;
DumpArray("REQUEST",$_REQUEST);
?>
</pre>

<h2>Raw POST Body</h2>

<pre>
<?PHP
$body = file_get_contents("php://input");
echo strlen($body);
echo " bytes: <br>";
?>
<span style="background-color: #e0e0f0">
<?PHP
while (strlen($body)>60) {
  echo substr($body, 0, 60);
  echo "\n";
  $body = substr($body, 60);
}
echo $body;
?>
</span>
</pre>

</BODY>
</HTML>
<?PHP

# Function DumpArray 
##########################################################
function DumpArray($ArrayName,&$Array) {

foreach ($Array as $Key=>$Value){
    echo "$Key: $Value\n";
  } # End of foreach ($GLOBALS as $Key=>$Value)
} # End of function DumpArray 
#################################################


function emu_getallheaders() {
foreach($_SERVER as $h=>$v)
if(ereg('HTTP_(.+)',$h,$hp))
  $headers[$hp[1]]=$v;
  $headers["CONTENT_TYPE"]=$_SERVER["CONTENT_TYPE"];
  return $headers;
}
	
?>