<cfcomponent displayname="CacheBox.eviction.idle" output="false" extends="abstractpolicy" 
hint="evicts after content has been idle for a specified period of time">
	<cfset this.description = "Expires after N minutes unused" />
	<cfset this.limitlabel = "Minutes" />
	
	<cffunction name="getExpiredContent" access="public" output="false" returntype="array" 
	hint="returns an array of index values for content to expire">
		<cfargument name="cacheName" type="string" required="true" />
		<cfargument name="evictLimit" type="string" required="true" />
		<cfargument name="currentTime" type="numeric" required="true" />
		<cfargument name="cache" type="query" required="true" />
		<cfset var lim = evictLimit />
		<cfset var result = 0 />
		
		<!--- allow age to be specified in common intervals without having to calculate them --->
		<cfswitch expression="#lim#">
			<cfcase value="hour"><cfset lim = 60 /></cfcase>
		</cfswitch>
		
		<cfquery name="result" dbtype="query" debug="false">
			select index from cache 
			where timeHit <= <cfqueryparam value="#currentTime-lim#" cfsqltype="cf_sql_integer" />
		</cfquery>
		
		<cfreturn listToArray(ValueList(result.index)) />
	</cffunction>
	
</cfcomponent>
