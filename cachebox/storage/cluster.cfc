<cfcomponent displayname="CacheBox.storage.cluster" extends="default" output="false" 
hint="I store the content in the cluster scope introduced by Railo">
	<cfset instance.myself = CreateUUID() />
	<cfset instance.context = 1 />
	<cfset variables.cache = structNew() />
	<cfset this.description = "In-memory storage using the cluster scope (Railo)" />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset super.init( argumentcollection = arguments ) />
		
		<!--- it's not possible to cflock across the cluster scope in Railo, 
		so this unusual bit of code is used as a workaround to ensure that only 
		one cachebox object is created in the cluster scope. This doesn't work 
		like the CacheBox fingerprint, so you can't test alternate versions of 
		the cluster storage without copying this function and renaming the 
		cluster scope variables --->
		<cfif isReady()>
			<cfparam name="cluster.cachebox.id" type="string" default="#instance.myself#" />
			
			<cfif cluster.cachebox.id eq instance.myself>
				<cfset cluster.cachebox.storage = this />
				<cfreturn this />
			<cfelse>
				<cfloop condition="not isDefined('cluster.cachebox.storage')">
					<cfset CreateObject("java","java.lang.Thread").sleep(100) />
				</cfloop>
				<cfreturn cluster.cachebox.storage />
			</cfif>
		<cfelse>
			<cfreturn this />
		</cfif>
	</cffunction>
	
	<cffunction name="isReady" access="public" output="false" returntype="boolean">
		<cfreturn isDefined("cluster") />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset cache[arguments.cachename] = arguments.content />
		<cfreturn "" />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var result = structNew() />
		<cfset result.status = 0 />
		
		<cftry>
			<cfset result.content = cache[arguments.cachename] />
			<cfcatch>
				<cfset result.content = "" />
				<cfset result.status = 1 />
			</cfcatch>
		</cftry>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfparam name="cluster.cachebox" type="struct" default="#structNew()#" />
		<cfset structDelete(cache,arguments.cachename) />
	</cffunction>
</cfcomponent>

