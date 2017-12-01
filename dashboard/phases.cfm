<cfset Phases = application.MyOpenbox.Phases />

<cfoutput>

<table width="100%" border="1" cellpadding="10" cellspacing="10">
<tr>
<td width="34%" valign="top">
	<ul>
	<cfloop list="#ListSort(StructKeyList(Phases), 'textnocase')#" index="phase">
		<li><a href="#udfs.link("Phases", "phase=#phase#")#">#phase#</a></li>
	</cfloop>
	</ul>
</td>
<td width="33%" valign="top">
	<cfif StructKeyExists(url, "phase") AND StructKeyExists(Phases, url.phase)>
	<h1>#udfs.h(url.Phase)#</h1>
	<h2>Ciruit</h2>
	<cfloop from="1" to="#ArrayLen(Phases[url.phase])#" index="i">
		<cfset circuit=Phases[url.phase][i] />
		<cfset circuitname="" />
		<cfif StructKeyExists(circuit, "CircuitName")>
			<cfset circuitname=circuit.CircuitName />
		</cfif>
		<li><a href="#udfs.link("Phases", "phase=#phase#&index=#i#")#"><cfif Len(circuitname) GT 0>#circuitname#<cfelse>[ROOT]</cfif></a></li>
	</cfloop>
	</cfif>
</td>
<td width="33%" valign="top">
	<cfif StructKeyExists(url, "phase") AND StructKeyExists(Phases, url.phase)>
		<cfif StructKeyExists(url, "index") AND ArrayLen(Phases[url.phase]) GTE url.index>
			<h1><cfif StructKeyExists(Phases[url.phase][url.index], "CircuitName")>#Phases[url.phase][url.index].CircuitName#<cfelse>[ROOT]</cfif></h1>
			<cfdump var="#Phases[url.phase][url.index]#" />
		<cfelse>
			<cfdump var="#Phases[url.phase]#" />
		</cfif>
	</cfif>
</td>
</tr>
</table>

</cfoutput>