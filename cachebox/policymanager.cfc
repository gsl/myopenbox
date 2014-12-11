<cfcomponent output="false" extends="util" 
hint="I manage eviction policies for expiring cached content">
	<cfset instance.evictPolicy = structNew() />
	
	<cffunction name="getPolicy" access="public" output="false" 
	hint="I lazy-load and return an eviction policy specified by name">
		<cfargument name="policy" type="string" required="true" />
		<cfset var pol = 0 />
		
		<cflock type="readonly" timeout="10" name="cachebox.eviction.policy">
			<cfif structKeyExists(instance.evictPolicy,policy)>
				<cfreturn instance.evictPolicy[policy] />
			</cfif>
		</cflock>
		
		<cflock type="exclusive" timeout="10" name="cachebox.eviction.policy">
			<cfif structKeyExists(instance.evictPolicy,policy)>
				<cfreturn instance.evictPolicy[policy] />
			</cfif>
			
			<cfset pol = CreateObject("component","eviction.#lcase(policy)#").init(this) />
			<cfset instance.evictPolicy[policy] = pol />
			<cfreturn pol />
		</cflock>
	</cffunction>
	
	<cffunction name="getAvailablePolicies" access="public" output="false" returntype="array" 
	hint="returns a list of the names of available eviction policies">
		<cfset var qry = 0 />
		<cfset var result = ArrayNew(1) />
		<cfset var list = "" />
		<cfset var i = 0 />
		
		<cfdirectory action="list" name="qry" filter="*.cfc" sort="textnocase" 
			directory="#instance.rootDir#/eviction" />
		
		<cfloop query="qry">
			<cfif not refindnocase("^abstract",qry.name)>
				<cfset ArrayAppend(result,lcase(listfirst(qry.name,"."))) />
			</cfif>
		</cfloop>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>

