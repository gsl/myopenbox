<cfcomponent displayname="CacheBox.eviction.idle" output="false" extends="abstractpolicy" 
hint="evicts after the agent exceeds n records in cache, least frequently used first">
	<cfset this.description = "Least Frequently Used: Expires after N records in cache" />
	
	<cffunction name="getExpiredContent" access="public" output="false" returntype="array" 
	hint="returns an array of index values for content to expire">
		<cfargument name="cacheName" type="string" required="true" />
		<cfargument name="evictLimit" type="string" required="true" />
		<cfargument name="currentTime" type="numeric" required="true" />
		<cfargument name="cache" type="query" required="true" />
		<cfset var result = ArrayNew(1) />
		<cfset var num = cache.recordcount - evictLimit />
		
		<cfif num gt 0>
			<!--- content exceeds the limit, expire the overage --->
			<cfquery name="result" dbtype="query" maxrows="#num#" debug="false">
				select index, ((#currentTime#-timestored) / hitcount) as frequency 
				from cache where timestored is not null 
				order by frequency desc 
			</cfquery>
			
			<cfset result = listToArray(ValueList(result.index)) />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>
