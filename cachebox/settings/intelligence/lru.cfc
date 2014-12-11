<cfcomponent extends="abstract" hint="suggests an LRU eviction poicy for agents with an average age more than half the oldest age">
	
	<cfset instance.hintText = "If content is stored early and kept for a long time, least recently used items could be removed." />
	
	<cffunction name="getRecommendation" access="public" output="false" returntype="struct" hint="returns a single recommendation for a specified agent">
		<cfargument name="stats" type="struct" required="true" hint="statistics for a single cache agent" />
		<cfargument name="auto" type="numeric" required="true" hint="a multiplier value representing the type of auto-configuraiton - perf is a high number, fresh is a low number and auto is a median value" />
		<cfset var result = getDefaultRec() />
		
		<cfif stats.MeanAge gte 5 and stats.occupancy gte 20 
		and stats.oldest gte 10 and stats.MeanAge gte ceiling(stats.oldest / 2)>
			<!--- average age is more than half the oldest age 
			-- these objects are stored early and kept in cache for a long time 
			-- we can clean them out periodically by usage, least recent first --->
			<cfset result.evictPolicy = "lru" />
			<cfset result.evictAfter = ceiling(stats.occupancy * 0.75) />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>