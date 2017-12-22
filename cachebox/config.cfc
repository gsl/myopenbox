<cfcomponent extends="defaultconfig">
	<cfset instance.pollingURL = "http://" & cgi.HTTP_Host & Reverse(ListRest(Reverse(cgi.Script_Name), '/')) & "/monitor.cfm" />
	<!--- <cfset instance.preferred.cluster = "redis" /> --->
	<!--- <cfset instance.preferred = getStruct( cluster = "memcached", server = "memcached", application = "memcached" ) /> --->
	<cffunction name="updateMonitoringTask" access="private" output="false"></cffunction>
</cfcomponent>