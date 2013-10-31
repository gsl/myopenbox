<cfscript>
// i set YourOpenbox defaults
YourOpenbox["TargetCircuit"]=application.MyOpenbox.GetCircuit(ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."));
YourOpenbox["TargetFuseAction"]=application.MyOpenbox.GetFuseAction(attributes[application.MyOpenbox.Parameters.FuseActionVariable]);
</cfscript>

<!--- i apply TargetCircuit Settings --->
<cfif StructKeyExists(YourOpenbox.TargetCircuit, "Settings")>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/settings.#LCase(YourOpenbox.TargetCircuit.Name)#.cfm">
</cfif>

<cfset YourOpenbox["Settings"]=Duplicate(application.MyOpenbox.Settings)>