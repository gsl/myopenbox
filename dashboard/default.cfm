<cfoutput>

<ul>
	<li><a href="#udfs.link("cache")#">Cache</a></li>
	<li><a href="#udfs.link("circuits")#">Circuits</a></li>
	<li><a href="#udfs.link("phases")#">Phases</a></li>
	<cfif StructKeyExists(application.MyOpenbox, "Logs")><li><a href="#udfs.link("logs")#">Logs</a></li></cfif>
	<li><a href="#udfs.link("dump")#">Dump</a></li>
</ul>

</cfoutput>