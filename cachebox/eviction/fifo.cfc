<cfcomponent displayname="CacheBox.eviction.idle" output="false" extends="abstractpolicy" 
hint="evicts after the agent exceeds n records in cache, oldest first">
	<cfset this.description = "First In First Out: Expires after N records in cache" />
	
	<cffunction name="getExpiredContent" access="public" output="false" returntype="array" 
	hint="returns an array of index values for content to expire">
		<cfargument name="cacheName" type="string" required="true" />
		<cfargument name="evictLimit" type="string" required="true" />
		<cfargument name="currentTime" type="numeric" required="true" />
		<cfargument name="cache" type="query" required="true" />
		<cfset var result = ArrayNew(1) />
		<cfset var num = cache.recordcount - evictLimit />
		
		<cfif num gt 0>
			<!--- 
				content exceeds the fifo limit, expire the overage 
				the oldest records will have the lowest index values because they were added to the query first 
				-- remove the oldest n records to reduce the agent to a maximum of [evictLimit] active records 
			--->
			<cfquery name="result" dbtype="query" maxrows="#num#" debug="false">
				select index from cache 
				order by index asc
			</cfquery>
			
			<cfset result = listToArray(ValueList(result.index)) />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>
