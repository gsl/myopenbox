<cfcomponent displayname="CacheBoxService" output="false" extends="util" 
hint="I provide a seamless interface to the CacheBox features by interfacing with many thin agents">
	<cfset instance.fingerprint = getCurrentTemplatePath() />
	<cfset instance.serverid = "" />
	<cfset instance.version = "1.1.0 RC2" />
	
	<cffunction name="init" access="public" output="false">
		<cfset var here = instance.fingerprint />
		<!--- 
			This somewhat unorthodox lock and return allows the service to create itself as a singleton 
			while also eliminating dependency on a separate IoC framework and use of the file path as a key 
			allows multiple instances of the service to be tested on a single machine or deployed in a 
			shared hosting environment (although in practice typical production environments will only 
			maintain one instance per server to allow the management of all cache for that server from 
			a central location). 
			NOTE: if creating an alternative version of the service, 
				instance.fingerprint must be re-declared in the new CFC even if it extends this one 
		--->
		<cflock name="cachebox.service" type="exclusive" timeout="10">
			<cfparam name="server.cachebox" type="struct" default="#structNew()#" />
			
			<cfif structKeyExists(server.cachebox,here)>
				<cfreturn server.cachebox[here] />
			<cfelse>
				<!--- create a config object - this allows much of the framework to be customized without edits via the config.cfc --->
				<cfset instance.config = getConfigObject() />
				
				<!--- create a storage query object for the bulk of the work --->
				<cfset instance.storage = instance.config.createStorage() />
				
				<!--- don't set the server object unless config completed successfully above --->
				<cfset server.cachebox[here] = this />
			</cfif>
			
			<cfreturn this />
		</cflock>
	</cffunction>
	
	<cffunction name="getServerID" access="public" output="false" returntype="string">
		<cfif not len(trim(instance.serverid))>
			<cfset instance.serverid = super.getServerID() />
		</cfif>
		<cfreturn instance.serverid />
	</cffunction>
	
	<cffunction name="getConfigObject" access="private" output="false">
		<cfargument name="testInstance" type="struct" required="false" default="#StructNew()#" />
		<cfset var here = getDirectoryFromPath(instance.fingerPrint) />
		<cfset var path = iif(fileExists(here & "/config.cfc"),de("config"),de("defaultconfig")) />
		<cfreturn CreateObject("component",path).init(this, testInstance) />
	</cffunction>
	
	<cffunction name="getFingerPrint" access="public" output="false">
		<cfreturn instance.fingerPrint />
	</cffunction>
	
	<cffunction name="getStorage" access="public" output="false">
		<cfreturn instance.storage />
	</cffunction>
	
	<cffunction name="getVersion" access="public" output="false">
		<cfreturn instance.version />
	</cffunction>
	
	<cffunction name="getOccupancy" access="public" output="false">
		<cfargument name="cachename" type="string" required="false" default="" hint="allows occupancy to be limited to keys with an arbitrary pattern, i.e. clu|% for the cluster" />
		<cfreturn getStorage().getOccupancy(stored=true,cachename=arguments.cachename) />
	</cffunction>
	
	<cffunction name="registerAgent" access="public" output="false">
		<cfargument name="agent" type="any" required="true" />
		<cfreturn getAgentManager().registerAgent(agent) />
	</cffunction>
	
	<cffunction name="getAgentConfig" access="private" output="false">
		<cfargument name="agent" type="any" required="true" />
		<cfreturn getAgentManager().getAgentConfig(agent) />
	</cffunction>
	
	<cffunction name="getStorageType" access="private" output="false">
		<cfargument name="agent" type="any" required="true" />
		<cfreturn getAgentConfig(agent).storageType />
	</cffunction>
	
	<cffunction name="getAppliedContext" access="public" output="false">
		<cfargument name="agent" type="any" required="true" />
		<cfreturn getAgentManager().getAppliedContext(agent) />
	</cffunction>
	
	<cffunction name="formatCacheName" access="public" output="false" returntype="string">
		<cfargument name="agent" type="any" required="true" />
		<cfargument name="cachename" type="string" required="true" />
		<cfreturn getAgentManager().formatCacheName(agent,cachename) />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="struct">
		<cfargument name="agent" type="any" required="true" />
		<cfargument name="cachename" type="string" required="true" />
		<cfreturn getStorage().fetch(formatCacheName(agent,cachename),getStorageType(agent)) />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="struct">
		<cfargument name="agent" type="any" required="true" />
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<!--- figure out which storage type this agent is configured to use --->
		<cfset var storageType = getAgentConfig(agent).storageType />
		
		<!--- actually store the data, but to prevent race conditions, we may need to return a previously stored copy --->
		<cfset var result = getStorage().store(formatCacheName(agent,cachename),content,storageType) />
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="monitorCache" access="public" output="false" 
	hint="monitors the cache and reconfigures the agent strategies as needed">
		<cfset getConfig().monitorCache() />
	</cffunction>
	
	<cffunction name="reap" access="public" output="false" hint="I purge expired content from storage">
		<cfset getConfig().reap(getStorage().getCacheCopy()) />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="void" 
	hint="deletes one or more entries from the cache">
		<cfargument name="agent" type="any" required="true" />
		<cfargument name="cachename" type="string" required="true" />
		<cfset getStorage().delete(formatCacheName(agent,cachename)) />
	</cffunction>
	
	<cffunction name="expire" access="public" output="false" returntype="void" 
	hint="marks one or more entries in the cache as expired without immediately deleting them">
		<cfargument name="agent" type="any" required="true" />
		<cfargument name="cachename" type="string" required="true" />
		<cfset getStorage().expire(formatCacheName(agent,cachename)) />
	</cffunction>
	
	<cffunction name="resetServer" access="public" output="false" 
	hint="removes all avauilable server cache">
		<cfset getStorage().delete("srv|%") />
	</cffunction>
	
	<cffunction name="resetCluster" access="public" output="false" 
	hint="removes all available cluster cache">
		<cfset getStorage().delete("clu|%") />
	</cffunction>
	
	<cffunction name="resetApplication" access="public" output="false" 
	hint="removes all cache for a given application">
		<cfargument name="appName" type="string" required="true" />
		<cfset getStorage().delete("app|#lcase(appName)#|%") />
	</cffunction>
	
	<cffunction name="resetAgent" access="public" output="false" 
	hint="removes all cache created for a specific agent in the agent's context">
		<cfargument name="agent" type="any" required="true" />
		
		<cfif isSimpleValue(agent)>
			<cfset arguments.agent = getAgentManager().getAgent(arguments.agent) />
		</cfif>
		
		<cfset getStorage().delete(formatCacheName(arguments.agent,"%")) />
	</cffunction>
	
	<cffunction name="getAgentSize" access="public" output="false">
		<cfargument name="Agent" type="any" required="true" />
		<cfreturn getOccupancy(formatCacheName(agent,"%")) />
	</cffunction>
	
</cfcomponent>

