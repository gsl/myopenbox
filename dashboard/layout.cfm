<!DOCTYPE html>
<html>
<head>
	<meta charset=utf-8 />
	<title>MyOpenbox Dashboard</title>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/SyntaxHighlighter/3.0.83/scripts/shCore.min.js"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/SyntaxHighlighter/3.0.83/scripts/shBrushColdFusion.min.js"></script>
	
	<link href="https://cdnjs.cloudflare.com/ajax/libs/SyntaxHighlighter/3.0.83/styles/shCore.min.css" rel="stylesheet" type="text/css" />
	<link href="https://cdnjs.cloudflare.com/ajax/libs/SyntaxHighlighter/3.0.83/styles/shThemeDefault.min.css" rel="stylesheet" type="text/css" />
</head>
<body>

<cfoutput>#request.Content#</cfoutput>

<!-- Finally, to actually run the highlighter, you need to include this JS on your page -->
<script type="text/javascript">
SyntaxHighlighter.all();
</script>

</body>
</html>