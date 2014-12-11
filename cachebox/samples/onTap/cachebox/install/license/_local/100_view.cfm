<cffile action="read" file="#request.fs.getPath('license.txt','C')#" variable="license">

<cf_html parent="#pluginmanager.view.main#"><cfoutput>
	<div xmlns:tap="xml.tapogee.com">
		<pre style="overflow:auto; padding: 5px; height:400px; width: 600px; background-color:white; color:black; border: solid black 1px;">#htmleditformat(license)#</pre>
		<div style="text-align:center; width: 600px;">
			<form method="get" action="#htmleditformat(request.tapi.getURL('','C'))#" tap:features="false" style="display:inline;">
				<input type="hidden" name="netaction" value="#plugin.getValue('source')#/install/configure" />
				<button type="submit" style="margin:5px;">agree</button>
			</form>
			<form method="get" action="http://on.tapogee.com" tap:features="false" target="_top" style="display:inline;">
				<button type="submit" style="margin:5px;">disagree</button>
			</form>
		</div>
	</div>
</cfoutput></cf_html>