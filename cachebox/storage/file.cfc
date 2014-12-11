<cfcomponent displayname="CacheBox.storage.file" extends="default" output="false" 
hint="I cache content to a physical file -- I can only be used for agents that store strings, not objects">
	<cfset instance.context = 2 />
	<cfset instance.storagedirectory = "" />
	<cfset instance.settings = "file.xml.cfm" />
	<cfset this.description = "Saves cached content to a physical file" />
	
	<cffunction name="isReady" access="public" output="false" returntype="boolean">
		<cfreturn directoryExists(instance.storageDirectory) />
	</cffunction>
	
	<cffunction name="getFilePath" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfreturn instance.storagedirectory & "/" & replace(arguments.cachename,"|","/","ALL") & ".cfm" />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var path = getFilePath(arguments.cachename) />
		<cfset var dir = getDirectoryFromPath(path) />
		<cfset var binary = iif(isBinary(content),1,0) />
		
		<!--- if the directory doesn't exist, the server throws an error on write --->
		<cfif not DirectoryExists(dir)><cfset mkDir(dir) /></cfif>
		<cffile action="write" file="#path#" output="#arguments.content#" />
		
		<cfreturn binary />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var result = getStruct( status = 0, content = "" ) />
		
		<cftry>
			<cffile action="#iif(val(content),de('readbinary'),de('read'))#" 
				variable="result.content" file="#getFilePath(arguments.cachename)#" />
			<cfcatch>
				<!--- unable to fetch the content --->
				<cfset result.status = 3 />
			</cfcatch>
		</cftry>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" hint="removes the cache file from the storage directory">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var path = getFilePath(arguments.cachename) />
		<cfif fileExists(path)><cfset fileDelete(path) /></cfif>
	</cffunction>
	
	<cffunction name="getConfigForm" access="public" output="false" returntype="string">
		<cfset var result = "" />
		
		<cfsavecontent variable="result">
			<cfoutput>
				<form>
					<input type="text" name="storagedirectory" 
						label="Directory" value="#XmlFormat(instance.storagedirectory)#" />
				</form>
			</cfoutput>
		</cfsavecontent>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="mkDir" access="private" output="false">
		<cfargument name="dir" type="string" required="true" />
		<cfset var fso = CreateObject("java","java.io.File").init(dir) />
		<cfset fso.mkdirs() />
	</cffunction>
	
	<cffunction name="setConfig" access="public" output="false" 
	hint="I format user inputs and save them to a configuration file for the storage type">
		<cfargument name="parameters" type="struct" required="true" />
		<cfset var old = instance.storagedirectory />
		
		<cfif old neq parameters.storagedirectory>
			<cfif directoryexists(old)>
				<cfdirectory action="delete" directory="#old#" recurse="true" />
			</cfif>
			
			<cfif len(parameters.storagedirectory)>
				<cfset mkDir(parameters.storagedirectory) />
			</cfif>
			
			<cfset super.setConfig(parameters) />
		</cfif>
	</cffunction>
	
</cfcomponent>

