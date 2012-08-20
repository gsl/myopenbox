<cfcomponent extends="defaultconfig">
	<cfset instance.pollingURL = "http://" & cgi.HTTP_Host & Reverse(ListRest(Reverse(cgi.Script_Name), '/')) & "/monitor.cfm" />
</cfcomponent>