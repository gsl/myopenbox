<cfcomponent displayname="CacheBox.storage.native" extends="default" output="false" 
hint="I use the native ehCache instance in ColdFusion 9 to store content">
	<cfset instance.context = 2 />
	<cfset instance.isReady = iif(structKeyExists(getFunctionList(),"cacheGet"),true,false) />
	<cfset this.description = "Uses the native ehCache instance in ColdFusion 9" />
	
	<cffunction name="isReady" access="public" output="false" returntype="boolean">
		<cfreturn instance.isReady />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset cachePut(arguments.cachename,arguments.content) />
		<cfreturn "" />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var result = getStruct( content = cacheGet(arguments.cachename) ) />
		<cfset result.status = iif(isDefined("result.content"),0,1) />
		<cfif result.status><cfset result.content = "" /></cfif>
		<cfreturn result />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset cacheRemove(arguments.cachename) />
	</cffunction>
	
</cfcomponent>

