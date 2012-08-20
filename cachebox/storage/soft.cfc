<cfcomponent displayname="CacheBox.storage.soft" extends="default" output="false" 
hint="I use a Java SoftReference object to store the data, allowing the server to garbage collect the object as needed">
	<cfset instance.context = 2 />
	<cfset this.description = "Java soft-references allow the JVM to manage content expiration" />
	
	<cffunction name="store" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfreturn CreateObject("java","java.lang.ref.SoftReference").init(arguments.content) />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var result = structNew() />
		<cfset result.content = arguments.content.get() />
		<cfset result.status = iif(isDefined("result.content"),0,1) />
		<cfif result.status><cfset result.content = "" /></cfif>
		<cfreturn result />
	</cffunction>
	
</cfcomponent>

