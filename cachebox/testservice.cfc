<cfcomponent extends="cacheboxservice">
	<cfset instance.fingerprint = "test:" & instance.fingerprint />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset var here = instance.fingerprint />
		
		<!--- create a config object - the new config is used for testing --->
		<cfset instance.config = getConfigObject(arguments.config.testInstanceExport()) />
		
		<!--- create a storage query object for the bulk of the work 
		- use the argument config so it can copy data from the live service if desired --->
		<cfset instance.storage = instance.config.createTestStorage(arguments.config) />
		
		<!--- don't set the server object unless config completed successfully above --->
		<cfset server.cachebox[here] = this />
		
		<cfreturn this />
	</cffunction>
	
</cfcomponent>