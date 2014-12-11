<cfcomponent output="false" hint="I provide a remote access to the service object">
	<cfset instance.service = request.service />
	<cfset instance.config = instance.service.getConfig() />
	<cfset instance.manager = instance.config.getClusterManager() />
	
	<cffunction name="isTrustedServer" access="public" output="false">
		<cfargument name="serverid" type="string" required="true" />
		<cfreturn instance.manager.isTrustedServer(serverid) />
	</cffunction>
	
	<cffunction name="getTrust" access="remote" output="false" returntype="boolean">
		<cfargument name="serverid" type="string" required="true" />
		<cfargument name="remoteserverid" type="string" required="true" />
		<cfif arguments.serverid is instance.manager.getServerID()>
			<cfset instance.manager.addTrustedServer(remoteserverid) />
			<cfset propagateTrustedServer(remoteserverid) />
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
	
	<cffunction name="propagateTrustedServer" access="private" output="false">
		<cfargument name="serverid" type="string" required="true" />
		<cfset var mgr = instance.manager />
		<cfset var localhost = mgr.getServerID() />
		<cfset var svr = mgr.getServerArray() />
		<cfset var i = 0 />
		
		<cfloop index="i" from="1" to="#ArrayLen(svr)#">
			<cftry>
				<cfset mgr.getWebservice(svr[i]).addTrustedServer(localhost,arguments.serverid) />
				<cfcatch></cfcatch>
			</cftry>
		</cfloop>
		
	</cffunction>
	
	<cffunction name="getServerID" access="remote" output="false" returntype="string">
		<cfargument name="serverid" type="string" required="true" />
		<cfif isTrustedServer(serverid)>
			<cfreturn instance.manager.getServerID() />
		<cfelse>
			<cfreturn "REJECTED" />
		</cfif>
	</cffunction>
	
	<cffunction name="addTrustedServer" access="remote" output="false" returntype="boolean">
		<cfargument name="serverid" type="string" required="true" />
		<cfargument name="trustedserverid" type="string" required="true" />
		<cfif serverid neq instance.manager.getServerID() and isTrustedServer(serverid)>
			<cfset instance.manager.addTrustedServer(trustedserverid) />
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
	
	<cffunction name="addServer" access="remote" output="false" returntype="boolean">
		<cfargument name="serverid" type="string" required="true" />
		<cfargument name="serverstring" type="string" required="true" />
		<cfif isTrustedServer(serverid)>
			<cfset instance.manager.addServer(trustedserverid) />
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
	
	<cffunction name="getServerArray" access="remote" output="false" returntype="array">
		<cfargument name="serverid" type="string" required="true" />
		<cfif isTrustedServer(serverid)>
			<cfreturn instance.manager.getServerArray() />
		<cfelse>
			<cfreturn ArrayNew(1) />
		</cfif>
	</cffunction>
	
	<cffunction name="getTrustedServers" access="remote" output="false" returntype="array">
		<cfargument name="serverid" type="string" required="true" />
		<cfif isTrustedServer(serverid)>
			<cfreturn instance.manager.getTrustedServers() />
		<cfelse>
			<cfreturn ArrayNew(1) />
		</cfif>
	</cffunction>
	
	<cffunction name="syncStorage" access="remote" output="false" returntype="boolean">
		<cfargument name="serverid" type="string" required="true" />
		<cfargument name="settings" type="struct" required="true" />
		
		<cfset var mgr = 0 />
		<cfset var storage = 0 />
		
		<cfif not isTrustedServer(serverid)>
			<cfreturn false />
		</cfif>
		
		<cftry>
			<cfset mgr = instance.config.getStorageManager() />
			<cfset storage = mgr.getStorageType(settings.storagetype) />
			<cfset storage.setConfig(arguments.settings) />
			<cfreturn true />
			
			<cfcatch>
				<cfreturn false />
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="syncAgent" access="remote" output="false" returntype="boolean">
		<cfargument name="serverid" type="string" required="true" />
		<cfargument name="settings" type="struct" required="true" />
		
		<cfset var mgr = 0 />
		<cfset var storage = 0 />
		
		<cfif not isTrustedServer(serverid)>
			<cfreturn false />
		</cfif>
		
		<cftry>
			<cfset mgr = instance.config.getAgentManager() />
			<cfset mgr.setAgentConfig(argumentCollection=arguments.settings) />
			<cfset instance.config.logEvent( "syncAgent" , arguments ) />
			<cfreturn true />
			
			<cfcatch>
				<cfreturn false />
			</cfcatch>
		</cftry>
	</cffunction>
	
</cfcomponent>

