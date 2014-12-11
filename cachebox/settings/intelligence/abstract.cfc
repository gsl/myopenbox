<cfcomponent output="false" hint="intelligence agents should extend this class">
	
	<cfset variables.instance = structNew() />
	<cfset instance.hintText = "" />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfargument name="intelligence" type="any" required="true" />
		<cfargument name="next" type="any" required="true" />
		<cfset structAppend(instance, arguments, true) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getRecommendation" access="public" output="false" returntype="struct" hint="returns a single recommendation for a specified agent">
		<cfargument name="stats" type="struct" required="true" hint="statistics for a single cache agent" />
		<cfargument name="auto" type="numeric" required="true" hint="a multiplier value representing the type of auto-configuraiton - perf is a high number, fresh is a low number and auto is a median value" />
		<cfset var result = getDefaultRec() />
		
		<!--- use this area to analyze the data in the agent struct and set the evictPolicy and evictAfter variables --->
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getConfig" access="private" output="false">
		<cfreturn instance.config />
	</cffunction>
	
	<cffunction name="getNext" access="public" output="false" returntype="any">
		<cfreturn instance.next />
	</cffunction>
	
	<cffunction name="getDefaultRec" access="private" output="false">
		<cfset var result = StructNew() />
		<cfset result.evictPolicy = "" />
		<cfset result.evictAfter = "" />
		<cfset result.hintText = instance.hintText />
		<cfreturn result />
	</cffunction>
	
</cfcomponent>