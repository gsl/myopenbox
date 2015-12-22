<cfset Logs = application.MyOpenbox.Logs />

<cfoutput>

<table width="100%" border="1" cellpadding="10" cellspacing="10">
<tr>
<td width="50%" valign="top">
	<ul>
	<cfloop list="#ListSort(StructKeyList(Logs), 'textnocase')#" index="log">
		<li><a href="#udfs.link("logs", "log=#log#")#">#log#</a></li>
	</cfloop>
	</ul>
</td>
<td valign="top">
	<cfif StructKeyExists(url, "log") AND StructKeyExists(Logs, url.log)>
	<cfdump var="#Logs[url.log]#" label="#GetCurrentTemplatePath()#" />
	</cfif>
</td>
</tr>
</table>

</cfoutput>