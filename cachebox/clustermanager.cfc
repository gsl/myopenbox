<cfcomponent displayname="CacheBox.ClusterManager" output="false" extends="util"
hint="I manage informationa bout other servers in the cluster">
	<cfset instance.configfile = instance.configdir & "cluster.xml.cfm" />
	<cfset instance.serverid = CreateUUID() />
	<cfset instance.service = structNew() />
	<cfset instance.trusted = ArrayNew(1) />
	<cfset instance.cluster = ArrayNew(1) />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset structAppend(instance,arguments,true) />
		<cfset readConfig() />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getServerID" access="public" output="false" returntype="string">
		<cfreturn instance.serverid />
	</cffunction>
	
	<cffunction name="getServerArray" access="public" output="false" returntype="array">
		<cfreturn instance.cluster />
	</cffunction>
	
	<cffunction name="getServerURL" access="public" output="false" returntype="string">
		<cfargument name="serverstring" type="string" required="true" />
		<cfset var path = serverstring />
		<cfif not findnocase("/",path)>
			<cfset path &= "/cachebox" />
		</cfif>
		<cfset path = rereplacenocase(path,"^(http://)?","http://") />
		<cfset path = rereplacenocase(path,"/\w+\.cfc(\?WSDL)?$","") />
		<cfreturn path />
	</cffunction>
	
	<cffunction name="getWebserviceURL" access="public" output="false" returntype="string">
		<cfargument name="serverstring" type="string" required="true" />
		<cfset var path = serverstring />
		<cfif not findnocase("/",path)>
			<cfset path &= "/cachebox" />
		</cfif>
		<cfset path = rereplacenocase(path,"^(http://)?","http://") />
		<cfif refindnocase("\.cfc$",path)>
			<cfset path &= "?WSDL" />
		<cfelseif not refindnocase("\?WSDL$",path)>
			<cfset path &= "/webservice.cfc?WSDL" />
		</cfif>
		<cfreturn path />
	</cffunction>
	
	<cffunction name="getWebservice" access="public" output="false">
		<cfargument name="serverstring" type="string" required="true" />
		<cfif not structKeyExists(instance.service,serverstring)>
			<cfset instance.service[serverstring] = CreateObject("webservice",getWebserviceURL(serverstring)) />
		</cfif>
		<cfreturn instance.service[serverstring] />
	</cffunction>
	
	<cffunction name="getWebserviceArray" access="public" output="false">
		<cfset var result = instance.cluster />
		<cfset var i = 0 />
		
		<cfloop index="i" from="#ArrayLen(result)#" to="1" step="-1">
			<cftry>
				<cfset result[i] = getWebservice(result[i]) />
				<cfcatch>
					<cfset ArrayDeleteAt(result,i) />
				</cfcatch>
			</cftry>
		</cfloop>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="readConfig" access="private" output="false">
		<cfset var xml = "" />
		<cfif not FileExists(instance.configfile)>
			<!--- if the file doesn't exist, create it and save the default settings --->
			<cfset saveConfig() />
		</cfif>
		
		<cfset xml = XmlParse(instance.configfile).cluster />
		<cfif xml.xmlAttributes.fingerprint neq getService().getFingerPrint()>
			<!--- the server settings belong to a different location, create new server settings --->
			<cffile action="delete" file="#instance.configfile#" />
			<cfreturn readConfig() />
		</cfif>
		
		<!--- okay the file exists and it's valid for this location, get our previously stored settings --->
		<cfset instance.serverid = xml.xmlAttributes.serverid />
		<cfset instance.cluster = listToArray(xml.servers.xmlText,chr(13) & chr(10)) />
		<cfset instance.trusted = listToArray(xml.trusted.xmlText,chr(13) & chr(10)) />
		
		<!--- clear the list of trusted servers --->
		<cfset instance.security = ArrayNew(1) />
	</cffunction>
	
	<cffunction name="saveConfig" access="private" output="false">
		<cfset var xml = "" />
		<cfset var param = structNew() />
		<cfset param["serverid"] = instance.serverid />
		<cfset param["fingerprint"] = getService().getFingerPrint() />
		<cfset param["servers"] = arrayToList(instance.cluster,chr(13) & chr(10)) />
		<cfset param["trusted"] = arrayToList(instance.trusted,chr(13) & chr(10)) />
		<cfset xml = XmlTransform("<cluster />",instance.configdir & "/cluster.xsl.cfm",param) />
		<cffile action="write" file="#instance.configfile#" output="#xml#" />
		<cfset readConfig() />
	</cffunction>
	
	<cffunction name="setServers" access="public" output="false">
		<cfargument name="serverList" type="string" required="true" />
		<cfset var config = listToArray(serverlist,chr(13) & chr(10)) />
		<cfset var x = 0 />
		
		<!--- scrub out any attempts to enter localhost to prevent possible circular references --->
		<cfloop index="x" from="#ArrayLen(config)#" to="1" step="-1">
			<cfif config[x] is "127.0.0.1" or config[x] is "localhost">
				<cfset ArrayDeleteAt(config,x) />
			</cfif>
		</cfloop>
		
		<cfset instance.cluster = config />
		
		<cfset saveConfig() />
	</cffunction>
	
	<cffunction name="getTrustedServers" access="public" output="false" returntype="array" 
	hint="I get a list of trusted servers in our cluster by requesting the serverid from each server in my list of known servers">
		<cfreturn instance.trusted />
	</cffunction>
	
	<cffunction name="addServer" access="public" output="false" 
	hint="I add the serverid of a server in the cluster to the list of trusted servers for this server">
		<cfargument name="serverstring" type="string" required="true" />
		<cfset var svr = instance.cluster />
		<cfset var i = 0 />
		
		<cfloop index="i" from="1" to="#ArrayLen(svr)#">
			<cfif svr[i] eq arguments.serverstring><cfreturn /></cfif>
		</cfloop>
		
		<cfset ArrayAppend(instance.cluster,arguments.serverstring) />
		<cfset saveConfig() />
	</cffunction>
	
	<cffunction name="addTrustedServer" access="public" output="false" 
	hint="I add the serverid of a server in the cluster to the list of trusted servers for this server">
		<cfargument name="serverid" type="string" required="true" />
		<cfset var svr = instance.trusted />
		<cfset var i = 0 />
		
		<cfloop index="i" from="1" to="#ArrayLen(svr)#">
			<cfif svr[i] eq arguments.serverid><cfreturn /></cfif>
		</cfloop>
		
		<cfset ArrayAppend(instance.trusted,arguments.serverid) />
		<cfset saveConfig() />
	</cffunction>
	
	<cffunction name="isTrustedServer" access="public" output="false" returntype="boolean" 
	hint="I check to see if I know a particular server (by ID) by comparing its serverid to the ids requested from my known servers">
		<cfargument name="serverid" type="string" required="true" />
		<cfset var svr = getTrustedServers() />
		<cfset var i = 0 />
		<cfloop index="i" from="1" to="#ArrayLen(svr)#">
			<cfif svr[i] is serverid>
				<!--- this is a valid server for sync operations! --->
				<cfreturn true />
			</cfif>
		</cfloop>
		
		<!--- Darn, we don't have this server in our list, so we can't trust it --->
		<cfreturn false />
	</cffunction>
	
	<cffunction name="syncStorage" access="public" output="false">
		<cfargument name="settings" type="struct" required="true" />
		<cfset var localhost = getServerID() />
		<cfset var svr = getWebserviceArray() />
		<cfset var i = 0 />
		<cfloop index="i" from="1" to="#ArrayLen(svr)#">
			<cfset svr[i].syncStorage(localhost,settings) />
		</cfloop>
	</cffunction>
	
	<cffunction name="syncAgent" access="public" output="false">
		<cfargument name="settings" type="struct" required="true" />
		<cfset var localhost = getServerID() />
		<cfset var svr = getWebserviceArray() />
		<cfset var i = 0 />
		<cfloop index="i" from="1" to="#ArrayLen(svr)#">
			<cfset svr[i].syncAgent(localhost,settings) />
		</cfloop>
	</cffunction>
	
</cfcomponent>