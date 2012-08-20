<cfcomponent output="false" extends="util" displayname="CacheBox.StorageManager" 
hint="I manage storage mediums for providing alternate or external methods of storage">
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		
		<cfset structAppend(instance,arguments,true) />
		<cfset loadStorageTypes() />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="loadStorageTypes" access="public" output="false" hint="I load all the storage types in the storage directory">
		<cfset var result = structNew() />
		<cfset var types = 0 />
		<cfset var temp = 0 />
		
		<cfdirectory name="types" action="list" filter="*.cfc" directory="#instance.rootDir#/storage" />
		
		<cfloop query="types">
			<cfset temp = listfirst(types.name,".") />
			<cfset result[temp] = CreateObject("component","storage." & temp).init(this) />
			<cfset result[temp].configure() />
		</cfloop>
		
		<cfset instance.medium = result />
	</cffunction>
	
	<cffunction name="getStorageType" access="public" output="false" 
	hint="I return the medium object for a specified type of storage">
		<cfargument name="typeName" type="string" required="true" />
		
		<cfreturn instance.medium[typeName] />
	</cffunction>
	
	<cffunction name="getAllTypes" access="public" output="false">
		<cfreturn instance.medium />
	</cffunction>
	
	<cffunction name="listTypes" access="public" output="false" returntype="array" 
	hint="returns a list of the names of available storage types">
		<cfargument name="context" type="string" required="false" default="" />
		<cfargument name="ready" type="boolean" required="false" default="true" />
		<cfscript>
			var storage = instance.medium; 
			var result = ""; 
			var type = 0; 
			
			arguments.context = listfindnocase(instance.contextList,arguments.context); 
			
			for (type in storage) {
				if (ready and not storage[type].isReady()) { continue; } 
				if (arguments.context and not storage[type].supportsContext(arguments.context)) { continue; } 
				result &= "," & type; 
			} 
			
			return listToArray(listSort(result,"textnocase","asc")); 
		</cfscript>
	</cffunction>
	
	<cffunction name="supportsContext" access="public" output="false" returntype="boolean">
		<cfargument name="storagetype" type="string" required="true" />
		<cfargument name="context" type="string" required="true" />
		<cfreturn getStorageType(arguments.storageType).supportsContext(listfindnocase(instance.contextList,arguments.context)) />
	</cffunction>
	
	<cffunction name="getAvailableContext" access="public" output="false" returntype="string" 
	hint="indicates if a specified context is available for storage - allows graceful degrade if not available">
		<cfargument name="context" type="string" required="true" />
		<cfset var cList = instance.contextList />
		<cfset var storage = instance.medium />
		<cfset var type = "" />
		<cfset var x = 0 />
		
		<!--- loop over the contexts from widest to narrowest --->
		<cfloop index="x" from="#listFindNoCase(cList,arguments.context)#" to="#ListLen(cList)#">
			<!--- check to see if there are any ready storage methods for this context --->
			<cfloop item="type" collection="#storage#">
				<cfif storage[type].isReady() and storage[type].supportsContext(x)>
					<!--- there is at least one storage method available for this context --->
					<cfreturn listGetAt(cList,x) />
				</cfif>
			</cfloop>
		</cfloop>
	</cffunction>
	
	<cffunction name="getConfigXsl" access="private" output="false">
		<cfset var result = "" />
		<cffile action="read" variable="result" file="#instance.configDir#/storageconfig.xsl.cfm" />
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getConfigForm" access="public" output="false">
		<cfargument name="storagetype" type="string" required="true" />
		<cfset var param = StructNew() />
		<cfset param["storagetype"] = arguments.storagetype />
		<cfreturn XmlTransform(XmlParse(getStorageType(storagetype).getConfigForm()),getConfigXSL(),param) />
	</cffunction>
</cfcomponent>
