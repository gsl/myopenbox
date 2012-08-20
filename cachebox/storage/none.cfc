<cfcomponent displayname="CacheBox.storage.none" extends="default" output="false" 
hint="I provide a method of disabling cache for a specific agent">
	<cfset this.description = "Disables caching for a specific agent" />
	<!--- allow caching to be disabled for any context, including cluster --->
	<cfset instance.context = 1 />
	
	<cffunction name="store" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfreturn "" />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<!--- we didn't store any content, so just return the error status --->
		<cfset var result = getStruct( status = 1, content = "" ) />
		<cfreturn result />
	</cffunction>
	
</cfcomponent>

