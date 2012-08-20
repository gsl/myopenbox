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
			<!--- 
				content exceeds the fifo limit, expire the overage 
				
				frequency of use is a much more complicated calculation than recency (simple subtraction) 
				to get a true frequency of use, we would need to divide the hit count by the elapsed time since 
				storage, which is a challenge to do in a query of query -- instead we're going to rely on a 
				simpler (and hopefully faster) algorithm that simply ball-parks the records that are older and 
				have fewer hits by returning them in order - this may expire some frequent but recently added 
				content from the cache - or - it may allow some infrequent but recently added content to stay 
			--->
			<cfquery name="result" dbtype="query" maxrows="#num#" debug="false">
				select index from cache 
				order by timeHit asc, hitCount asc 
			</cfquery>
			
			<cfset result = listToArray(ValueList(result.index)) />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>
