<!--- 
	This file provides an example of how to write your config.cfc 
	to customize your CacheBox installation 
---> 

<cfcomponent output="false" extends="defaultconfig" 
hint="I provide the default settings for a CacheBox installation">
	<!--- the url to use for the cachebox scheduled task which monitors and reconfigures the service --->
	<!--- <cfset instance.pollingURL = "http://127.0.0.1/cachebox/monitor.cfm" /> --->
	
	<!--- minimum number of records in cache before performing automated strategy optimization --->
	<!--- <cfset instance.minConfigSize = 100 /> --->
	
	<!--- minimum number of minutes between monitoring --->
	<!--- <cfset instance.pollingInterval = 1 /> --->
	
	<!--- minimum number of minutes between strategy optimizations --->
	<!--- <cfset instance.optimizeInterval = 5 /> --->
	
	<!--- maximum number of minutes until out-of-memory error before performing automated strategy optimization - defaults to 2 hours --->
	<!--- <cfset instance.optimizeThresholdMinutes = 120 /> --->
	
	<!--- maximum number of minutes until out-of-memory error before displaying the warning on the Management Application --->
	<!--- <cfset instance.destructWarningThreshold = 60 /> --->
	
	<cffunction name="getApplicationSettings" access="public" output="false" 
	hint="I set application-specific settings for the reporting and management application, such as mappings and timeouts">
		<cfset var result = super.getApplicationSettings() />
		<cfset result.applicationTimeout = CreateTimeSpan(0,0,20,0) />
		<cfset result.sessionTimeout = CreateTimeSpan(0,0,20,0) />
		<cfreturn result />
	</cffunction>
	
	<cffunction name="onApplicationStart" access="public">
		<cfset super.onApplicationStart() />
		<!--- custom code here --->
	</cffunction>
	
	<cffunction name="onApplicationEnd" access="public" output="false">
		<cfargument name="applicationScope" type="struct" required="true" />
		<cfset super.onApplicationEnd(applicationScope) />
		<!--- custom code here --->
	</cffunction>
	
	<cffunction name="onRequestStart" access="public">
		<cfargument name="targetPage" type="string" required="true" />
		<cfset super.onRequestStart(targetPage) />
		<!--- custom code here --->
	</cffunction>
	
	<cffunction name="onRequestEnd" access="public">
		<cfset super.onRequestEnd() />
		<!--- custom code here --->
	</cffunction>
	
	<cffunction name="onSessionStart" access="public">
		<cfset super.onSessionStart() />
		<!--- custom code here --->
	</cffunction>
	
	<cffunction name="onSessionEnd" access="public" output="false">
		<cfargument name="applicationScope" type="struct" required="true" />
		<cfargument name="sessionScope" type="struct" required="true" />
		<cfset super.onSessionEnd(applicationScope,sessionScope) />
		<!--- custom code here --->
	</cffunction>
	
</cfcomponent>

