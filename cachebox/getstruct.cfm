<!--- I provide getStruct() and getArray() --->
<!--- these methods allow the application to execute on older ColdFusion versions that don't support implicit structs and arrays --->

<cffunction name="getStruct" access="private" output="false" returntype="struct" 
hint="this function was added to improve support for ColdFusion 7">
	<cfreturn arguments />
</cffunction>

<cffunction name="getArray" access="private" output="false" returntype="array">
	<cfset var a = ArrayNew(1) />
	<cfset var x = 0 />
	<cfloop index="x" from="1" to="#ArrayLen(arguments)#">
		<cfset ArrayAppend(a, arguments[x]) />
	</cfloop>
	<cfreturn a />
</cffunction>
