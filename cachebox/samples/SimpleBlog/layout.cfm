<cfoutput>
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<base href="http://#cgi.server_name##getDirectoryFromPath(cgi.script_name)#"/>
			<link rel="stylesheet" href="includes/master.css" type="text/css">
			<title>#rc.pageTitle#</title>
		</head>
		<body>
			<div class="header">#renderView('head')#</div>
			
			<div class="content">#renderView()#</div>
			
			<div class="footer">#renderView('footer')#</div>
		</body>
	</html>
</cfoutput>
