<cfoutput>

<cfset path=application.MyOpenbox.Parameters.Cache.Path />
<cfif application.MyOpenbox.Parameters.Cache.PathExpandPath>
	<cfset path=ExpandPath(path) />
</cfif>

<table width="100%" style="max-width: 1000px;" border="1" cellpadding="10" cellspacing="10">
<tr>
<td width="50%" valign="top">
<h1>#path#</h1>

<cfif DirectoryExists(path)>
	<cfdirectory directory="#path#" action="list" name="dir" filter="*.cfm" sort="asc" />
	<ul>
	<cfloop query="dir">
		<li><a href="#udfs.link("cache", "file=#dir.name#")#">#dir.name# <em>(#dir.size# B)</em> @ #DateFormat(dir.DateLastModified, "yyy-mm-dd")# #TimeFormat(dir.DateLastModified, "hh:mm tt")#</a></li>
	</cfloop>
	</ul>
</cfif>
</td>
<td valign="top">
	<cfif StructKeyExists(url, "file") AND FileExists(path & url.file)>
		<h1>#url.file#</h1>
		<cffile action="read" file="#path##url.file#" variable="cachefile" />
		<code><pre>#udfs.h(cachefile)#</pre></code>
	</cfif>
</td>
</tr>
</table>

</cfoutput>