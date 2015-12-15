<cfset variables.udfs = CreateObject("component", "udfs") />
<cfif StructKeyExists(application, "MyOpenbox")>
<cfinclude template="auth.cfm" />
<cfoutput>

<cfparam name="url.action" default="" />

<cftry>

<p><a href="#udfs.link("home")#">Home</a></p>

<cfswitch expression="#url.action#">
	<cfcase value="cache">
		<cfinclude template="cache.cfm" />
	</cfcase>
	<cfcase value="circuits">
		<cfinclude template="circuits.cfm" />
	</cfcase>
	<cfdefaultcase>
		<cfinclude template="default.cfm" />
	</cfdefaultcase>
</cfswitch>

<cfcatch><cfdump var="#cfcatch#" label="#GetCurrentTemplatePath()#" /><cfabort /></cfcatch>
</cftry>

</cfoutput>
<cfelse>
	<h1>MyOpenbox not initialized</h1>
</cfif>