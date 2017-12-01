<cfset Circuits = application.MyOpenbox.Circuits />

<cfoutput>

<table width="100%" border="1" cellpadding="10" cellspacing="10">
<tr>
<td width="34%" valign="top">
	<ul>
	<cfloop list="#ListSort(StructKeyList(Circuits), 'textnocase')#" index="circuit">
		<li><a href="#udfs.link("circuits", "circuit=#circuit#")#">#circuit#</a></li>
	</cfloop>
	</ul>
</td>
<td width="33%" valign="top">
	<cfif StructKeyExists(url, "circuit") AND StructKeyExists(Circuits, url.circuit)>
	<h1>#udfs.h(url.Circuit)#</h1>
	<h2>Fuses</h2>
	<cfloop list="#ListSort(StructKeyList(Circuits[url.circuit].Fuseactions), 'textnocase')#" index="fuse">
		<li><a href="#udfs.link("circuits", "circuit=#circuit#&fuse=#fuse#")#">#fuse#</a></li>
	</cfloop>
	
	<cfif StructKeyExists(Circuits[url.circuit], "Phases")>
		<h2>Phases</h2>
		<cfloop list="#ListSort(StructKeyList(Circuits[url.circuit].Phases), 'textnocase')#" index="phase">
			<li><a href="#udfs.link("circuits", "circuit=#circuit#&phase=#phase#")#">#phase#</a></li>
		</cfloop>
	</cfif>
	</cfif>
</td>
<td width="33%" valign="top">
	<cfif StructKeyExists(url, "circuit") AND StructKeyExists(Circuits, url.circuit)>
		<cfif StructKeyExists(url, "fuse") AND StructKeyExists(Circuits[url.circuit].Fuseactions, fuse)>
			<cfdump var="#Circuits[url.circuit].Fuseactions[fuse]#" label="#GetCurrentTemplatePath()#" />
		<cfelseif StructKeyExists(url, "phase") AND StructKeyExists(Circuits[url.circuit].Phases, phase)>
			<cfdump var="#Circuits[url.circuit].Phases[phase]#" label="#GetCurrentTemplatePath()#" />
		<cfelse>
			<cfdump var="#Circuits[url.circuit]#" />
		</cfif>
	</cfif>
</td>
</tr>
</table>

</cfoutput>