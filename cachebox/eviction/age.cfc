<cfcomponent displayname="CacheBox.eviction.age" output="false" extends="abstractpolicy" 
hint="evicts after content reaches a specified age">
	<cfset this.description = "Expires N minutes after creation" />
	<cfset this.limitlabel = "Minutes" />
	
	<cffunction name="getExpiredContent" access="public" output="false" returntype="array" 
	hint="returns an array of index values for content to expire">
		<cfargument name="cacheName" type="string" required="true" />
		<cfargument name="evictLimit" type="string" required="true" />
		<cfargument name="currentTime" type="numeric" required="true" />
		<cfargument name="cache" type="query" required="true" />
		<cfset var lim = val(evictLimit) />
		<cfset var result = 0 />
		
		<!--- allow age to be specified in common intervals without having to calculate them --->
		<cfswitch expression="#lim#">
			<cfcase value="day"><cfset lim = 1440 /></cfcase>
			<cfcase value="hour"><cfset lim = 60 /></cfcase>
		</cfswitch>
		
		<cfquery name="result" dbtype="query" debug="false">
			select index from cache 
			where timeStored is null or 
			timeStored <= <cfqueryparam value="#currentTime-lim#" cfsqltype="cf_sql_integer" />
		</cfquery>
		
		<cfreturn listToArray(ValueList(result.index)) />
	</cffunction>
	
</cfcomponent>
