<cfcomponent output="false">
	<cfset request.service = CreateObject("component","cacheboxservice").init().getConfig().getAdminService() />
	<cfset structAppend(this, request.service.getConfig().getApplicationSettings()) />
	
	<cffunction name="onApplicationStart" access="public">
		<cfset application.config = request.service.getConfig() />
		<cfset application.config.onApplicationStart() />
	</cffunction>
	
	<cffunction name="onApplicationEnd" access="public" output="false">
		<cfargument name="applicationScope" type="struct" required="true" />
		<cfset applicationScope.config.onApplicationEnd(applicationScope) />
	</cffunction>
	
	<cffunction name="onRequestStart" access="public">
		<cfargument name="targetPage" type="string" required="true" />
		<cfset application.config.onRequestStart(targetPage) />
	</cffunction>
	
	<cffunction name="onRequestEnd" access="public">
		<cfset application.config.onRequestEnd() />
	</cffunction>
	
	<cffunction name="onSessionStart" access="public">
		<cfset application.config.onSessionStart() />
	</cffunction>
	
	<cffunction name="onSessionEnd" access="public" output="false">
		<cfargument name="sessionScope" type="struct" required="true" />
		<cfargument name="applicationScope" type="struct" required="true" />
		<cfset applicationScope.config.onSessionEnd(sessionScope,applicationScope) />
	</cffunction>
	
</cfcomponent>

