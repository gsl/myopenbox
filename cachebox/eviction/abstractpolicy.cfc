<cfcomponent displayname="CacheBox.eviction.AbstractPolicy" output="false" 
hint="Eviction policies should extend tihs abstract policy (although it's not strictly required)">
	<cfinclude template="../instance.cfm" />
	<cfset this.description = "Description not available." />
	<cfset this.limitlabel = "Max Objects" />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset structAppend(instance,arguments,true) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="hasThreshold" access="public" output="false" returntype="boolean">
		<cfreturn iif(len(trim(this.limitlabel)), true, false) />
	</cffunction>
	
	<cffunction name="getExpiredContent" access="public" output="false" returntype="array" 
	hint="returns an array of index values for content to expire">
		<cfargument name="cacheName" type="string" required="true" />
		<cfargument name="evictLimit" type="string" required="true" />
		<cfargument name="currentTime" type="numeric" required="true" />
		<cfargument name="cache" type="query" required="true" />
		
		<cfthrow type="CacheBox.AbstractPolicy" message="The abstract eviction policy must be extended" />
		<!---
			EXAMPLE: 
			<cfset var qry = 0 />
			<cfset var expired = ArrayNew(1) />
			
			<cfloop query="qry">
				<cfif someCondition>
					<cfset ArrayAppend(expired,qry.index) />
				</cfif>
			</cfloop>
			
			<cfreturn expired />
		--->
	</cffunction>
	
</cfcomponent>
