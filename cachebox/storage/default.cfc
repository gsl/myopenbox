<cfcomponent displayname="CacheBox.storage.default" output="false" 
hint="I am the default storage medium - I represent internally cached content in the CacheBox storage object and define default behavior for external caching mediums to extend">
	<cfinclude template="../instance.cfm" />
	<cfset instance.configDir = instance.configDir & "storage/" />
	<cfset this.description = "Standard in-process memory storage" />
	<cfset instance.context = 2 />
	<cfset instance.settings = "" />
	<cfset instance.isReady = true />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset structAppend(instance,arguments,true) />
		<cfset readConfig() />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="isReady" access="public" output="false" returntype="boolean" 
	hint="I check to see if this storage medium is properly configured and ready to use - if I return false, this method is unusable">
		<cfreturn instance.isReady />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="any"
	hint="stores content for a storage medium - allows the medium to store the content outside the cachebox storage manager - not used by the default medium">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfreturn content />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="any"
	hint="fetches content from a storage medium - this allows the medium to store the content outside the cachebox storage manager - not used by the default medium">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var result = structNew() />
		<cfset result.status = 0 />
		<cfset result.content = arguments.content />
		<cfreturn result />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="any"
	hint="performs any additional cleanup that might be required by a storage medium after removal from the cachebox storage manager - not used by the default medium">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
	</cffunction>
	
	<cffunction name="configure" access="public" output="false" hint="provides a place to perform additional configuration after the init method, without involving the init arguments">
	</cffunction>
	
	<cffunction name="getConfig" access="private" output="false">
		<cfreturn instance.config />
	</cffunction>
	
	<cffunction name="getConfigPath" access="private" output="false" hint="returns the fully-qualified file path to the file that stores settings for this storage type">
		<cfreturn instance.configDir & instance.settings />
	</cffunction>
	
	<cffunction name="readXmlValues" access="private" output="false" returntype="struct" hint="reads values from the XML config file into a structure">
		<cfargument name="xml" type="xml" required="true" />
		<cfset var config = xml.xmlChildren />
		<cfset var result = StructNew() />
		<cfset var i = 0 />
		
		<cfloop index="i" from="1" to="#ArrayLen(config)#">
			<cfset result[config[i].xmlName] = config[i].xmlText />
		</cfloop>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="readConfig" access="private" output="false" hint="reads any required configuration from an XML config file into the instance variables">
		<cfset var config = getConfigPath() />
		<cfset var i = 0 />
		
		<cfif fileExists(config)>
			<cfset structAppend(instance, readXmlValues(XmlParse(config).config), true) />
		</cfif>
	</cffunction>
	
	<cffunction name="setConfig" access="public" output="false"
	hint="I format user inputs and save them to a configuration file for the storage type">
		<cfargument name="parameters" type="struct" required="true" />
		<cfset var param = StructNew() />
		<cfset var config = "" />
		<cfset var i = 0 />
		
		<cfset structAppend(param,parameters,true) />
		<cfset structDelete(param,"storagetype") />
		<cfset structDelete(param,"event") />
		<cfset structDelete(param,"fieldnames") />
		
		<!--- create the XML document --->
		<cfsavecontent variable="config">
			<cfoutput>
<config><cfloop item="i" collection="#param#">
	<#lcase(i)#>#XmlFormat(param[i])#</#lcase(i)#></cfloop>
</config>
			</cfoutput>
		</cfsavecontent>
		
		<!--- save the new config to file --->
		<cfset writeConfig(config) />
		
		<!--- use the new config values --->
		<cfset readConfig() />
	</cffunction>
	
	<cffunction name="writeConfig" access="private" output="false" 
	hint="I save formatted configuration values for the storage type to a file">
		<cfargument name="config" type="string" required="true" />
		<cffile action="write" file="#getConfigPath()#" output="#trim(arguments.config)#" />
	</cffunction>
	
	<cffunction name="supportsContext" access="public" output="false" returntype="boolean" 
	hint="I determine if the storage type supports a specific context - cluster, server or application">
		<cfargument name="context" type="numeric" required="true" />
		<cfreturn iif(instance.context lte arguments.context,true,false) />
	</cffunction>
	
	<cffunction name="getStruct" access="private" output="false" returntype="struct" 
	hint="this function was added to improve support for ColdFusion 7">
		<cfreturn arguments />
	</cffunction>

</cfcomponent>
