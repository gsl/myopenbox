<cfcomponent output="false" hint="I provide utility functions">
	<cfinclude template="instance.cfm" />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset structAppend(instance,arguments,true) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getConfig" access="public" output="false">
		<cfreturn instance.config />
	</cffunction>
	
	<cffunction name="getService" access="private" output="false">
		<cfreturn instance.config.getService() />
	</cffunction>
	
	<cffunction name="getServerID" access="public" output="false">
		<cfreturn getClusterManager().getServerID() />
	</cffunction>
	
	<cffunction name="getHistory" access="private" output="false">
		<cfreturn instance.config.getHistory() />
	</cffunction>
	
	<cffunction name="getStorage" access="private" output="false">
		<cfreturn getService().getStorage() />
	</cffunction>
	
	<cffunction name="getClusterManager" access="public" output="false">
		<cfreturn instance.config.getClusterManager() />
	</cffunction>	
	
	<cffunction name="getPolicyManager" access="private" output="false">
		<cfreturn instance.config.getPolicyManager() />
	</cffunction>
	
	<cffunction name="getStorageManager" access="private" output="false">
		<cfreturn instance.config.getStorageManager() />
	</cffunction>
	
	<cffunction name="getAgentManager" access="private" output="false">
		<cfreturn instance.config.getAgentManager() />
	</cffunction>
	
	<cffunction name="getStruct" access="private" output="false" returntype="struct" 
	hint="this function was added to improve support for ColdFusion 7">
		<cfreturn arguments />
	</cffunction>
	
</cfcomponent>
