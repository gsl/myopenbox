<cfcomponent displayname="CacheBox.eviction.none" output="false" extends="abstractpolicy" 
hint="content with this eviction policy is never removed from cache">
	<cfset this.description = "Content never expires." />
	<cfset this.limitlabel = "" />
	
	<cffunction name="getExpiredContent" access="public" output="false" returntype="array" 
	hint="returns an array of index values for content to expire">
		<cfargument name="cacheName" type="string" required="true" />
		<cfargument name="evictLimit" type="string" required="true" />
		<cfargument name="currentTime" type="numeric" required="true" />
		<cfargument name="cache" type="query" required="true" />
		
		<cfreturn ArrayNew(1) />
	</cffunction>
	
</cfcomponent>
