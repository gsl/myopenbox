<cfcomponent extends="abstract" hint="suggests an idle eviction poicy for agents with items in cache slower than 3x the average frequency for the agent">
	
	<cfset instance.hintText = "Hit frequency slower than 3x the average may indicate storage that could be better used." />
	
	<cffunction name="getRecommendation" access="public" output="false" returntype="struct" hint="returns a single recommendation for a specified agent">
		<cfargument name="stats" type="struct" required="true" hint="statistics for a single cache agent" />
		<cfargument name="auto" type="numeric" required="true" hint="a multiplier value representing the type of auto-configuraiton - perf is a high number, fresh is a low number and auto is a median value" />
		<cfset var result = getDefaultRec() />
		<cfset var testVal = ceiling(3 * auto * stats.meanFrequency) />		
		<!--- 
			by default the limit is 3x the mean frequency for the cache agent 
			multiplying by the auto value will set the limit lower for fresh, so content is 
			evicted faster, and higher for perf so content is held longer 
		--->
		
		<cfif stats.meanFrequency gte 1 and stats.minFrequency gt testval>
			<cfset result.evictPolicy = "idle" />
			<cfset result.evictAfter = testval />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>