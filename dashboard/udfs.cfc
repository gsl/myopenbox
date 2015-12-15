<cfcomponent output="no">

<cffunction name="link" output="no">
	<cfargument name="action" default="" />
	<cfargument name="qs" default="" />
	
	<cfset var variables.url = "index.cfm" />
	<cfset var variables.auth = url.auth />
	<cfset var variables.qs = arguments.qs />
	<cfif url.auth EQ application.MyOpenbox.Parameters.FWReparse>
		<cfset variables.auth = hash(url.auth) />
	</cfif>
	
	<cfset variables.qs = ListAppend(variables.qs, "action=#arguments.action#", "&") />
	<cfset variables.qs = ListAppend(variables.qs, "auth=#variables.auth#", "&") />
	<cfset variables.url = variables.url & "?" & variables.qs />
	<cfreturn variables.url />
</cffunction>

<cffunction name="h">
	<cfargument name="text" />
	<cfreturn HTMLEditFormat(Trim(arguments.text)) />
</cffunction>

</cfcomponent>