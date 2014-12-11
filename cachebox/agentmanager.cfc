<cfcomponent displayname="CacheBox.AgentManager" output="false" extends="util" 
hint="I manage the agents that register with the cachebox service">
	<cfset instance.agent = structNew() />
	<cfset instance.savedsettings = "agents.xml.cfm" />
	<cfset instance.settings = "" />
	<cfset instance.lock = getCurrentTemplatePath() />
	
	<cffunction name="registerAgent" access="public" output="false" returntype="string" 
	hint="I configure and store an agent when the agent is created - returns the registered agentID">
		<cfargument name="agent" type="any" required="true" />
		<cfset var cfg = getAgentSettings(agent) />
		<cfset cfg.agent = arguments.agent />
		<cfset instance.agent["#cfg.agentid#|%"] = cfg />
		
		<!--- this lets the agent know that it's successfully registered --->
		<cfreturn cfg.agentID />
	</cffunction>
	
	<cffunction name="getLock" access="private" output="false" returntype="string" 
	hint="I return a lock name that allows the agent manager to prevent race conditions that might damage the settings files">
		<cfreturn instance.lock />
	</cffunction>
	
	<cffunction name="getConfigDir" access="private" output="false" 
	hint="I return the directory in which XML settings files and related XSL transformers are stored">
		<cfreturn instance.configdir />
	</cffunction>
	
	<cffunction name="getAgentConfig" access="public" output="false" returntype="struct"
	hint="I return all the settings applied to a specified agent and the agent">
		<cfargument name="agent" type="any" required="true" />
		<cfif isSimpleValue(arguments.agent)>
			<cfset arguments.agent = replace(rereplace(agent,"(\|\%)?$","|%"),"||","|","ALL") />
		<cfelse>
			<cfset arguments.agent = formatCacheName(arguments.agent,"%") />
		</cfif>
		
		<cftry>
			<cfreturn structFind(instance.agent,arguments.agent) />
			<cfcatch>
				<cfset raiseMissingAgentException(arguments.agent) />
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="raiseMissingAgentException" access="private" output="false">
		<cfargument name="agent" type="string" required="true" />
		<cfthrow type="CacheBox.Agent.NotRegistered" message="The requested agent is not registered." detail="#arguments.agent#" />
	</cffunction>
	
	<cffunction name="getAgent" access="public" output="false" 
	hint="I return just the agent specified by its ID - use getAgentConfig() to return the agent and its settings">
		<cfargument name="agent" type="string" required="true" />
		<cfreturn getAgentConfig(arguments.agent).agent />
	</cffunction>
	
	<cffunction name="getAllAgents" access="public" output="false" returntype="struct" 
	hint="I return a structure containing all registered agents - this is used in purge handling">
		<cfreturn instance.agent />
	</cffunction>
	
	<cffunction name="getAppliedContext" access="public" output="false" 
	hint="I return the actual context applied to an agent, which may be less than the requested context if storage types for the requested context are unavailable">
		<cfargument name="agent" type="any" required="true" />
		<cfreturn getAgentConfig(agent).context />
	</cffunction>
	
	<cffunction name="formatCacheName" access="public" output="false" returntype="string"
	hint="I format the name of a specific object to fetch or store in cache using the agent naming convention">
		<cfargument name="agent" type="any" required="true" />
		<cfargument name="cachename" type="string" required="true" />
		<cfset var result = agent.getAgentID() />
		<cfif not len(result)>
			<cfset result = getAgentID(agent.getContext(),agent.getAppName(),agent.getAgentName()) />
		</cfif>
		<cfreturn result & "|" & cachename />
	</cffunction>
	
	<cffunction name="getContext" access="private" output="false" 
	hint="I return the full name of a context from an agentid or a context abbreviation">
		<cfargument name="agentid" type="string" required="true" />
		<cfswitch expression="#left(agentid,3)#">
			<cfcase value="app"><cfreturn "application" /></cfcase>
			<cfcase value="srv"><cfreturn "server" /></cfcase>
			<cfcase value="clu"><cfreturn "cluster" /></cfcase>
		</cfswitch>
	</cffunction>
	
	<cffunction name="getAgentID" access="public" output="false" returntype="string"
	hint="I construct an agent ID from a context, AppName and AgentName">
		<cfargument name="context" type="string" required="true" />
		<cfargument name="appname" type="string" required="true" />
		<cfargument name="agentname" type="string" required="true" />
		<cfset var result = "" />
		
		<cfswitch expression="#context#">
			<cfcase value="app,application" delimiters=","><cfset context = "app|" & lcase(appname) /></cfcase>
			<cfcase value="srv,server" delimiters=","><cfset context = "srv|" & lcase(getServerID()) /></cfcase>
			<cfcase value="clu,cluster" delimiters=","><cfset context = "clu" /></cfcase>
		</cfswitch>
		
		<cfreturn context & "|" & lcase(agentname) />
	</cffunction>
	
	<cffunction name="getQuery" access="public" output="false" 
	hint="I return a query with all the registered agents and their config information">
		<cfset var columns = "context,evictpolicy,evictafter,storagetype" />
		<cfset var qry = QueryNew("agentid,appname,agentname," & columns) />
		<cfset var agent = 0 />
		<cfset var x = "" />
		<cfset var i = 0 />
		
		<cfloop item="x" collection="#instance.agent#">
			<cfset QueryAddRow(qry,1) />
			<cfset i = qry.recordcount />
			<cfset qry.agentid[i] = x />
			<cfset agent = instance.agent[x] />
			<cfset qry.agentName[i] = lcase(agent.agent.getAgentName()) />
			<cfset qry.appName[i] = lcase(agent.agent.getAppName()) />
			<cfloop index="x" list="#columns#">
				<cfset qry[x][i] = agent[x] />
			</cfloop>
		</cfloop>
		
		<cfreturn qry />
	</cffunction>
	
	<cffunction name="getStruct" access="private" output="false" returntype="struct" 
	hint="this function was added to improve support for ColdFusion 7">
		<cfreturn arguments />
	</cffunction>
	
	<cffunction name="getAgentSettings" access="public" output="false" 
	hint="I fetch the manually configured and default settings for a specific caching agent">
		<cfargument name="agent" type="any" required="true" />
		<cfset var cfg = getConfig() />
		<cfset var typeMan = cfg.getStorageManager() />
		<cfset var result = StructNew() />
		<cfset var evict = 0 />
		<cfset var evictAfter = 0 />
		<cfset var context = 0 />
		
		<cfif isSimpleValue(agent)>
			<cfset agent = getAgent(agent) />
		</cfif>
		<!--- 
			these are the default settings for all agents, 
			so an agent that hasn't been manually configured 
			with alternate settings will receive these defaults 
			-- storageType and EvictPolicy are set when the agent is registered 
			and then are updated later when it's auto-configured 
			if the agent's eviction policy is auto, fresh or perf 
		--->
		<cfset evict = agent.getEvictPolicy() />
		<cfset context = agent.getContext() />
		
		<cfif find(":",evict)>
			<cfset evictAfter = max(1,val(listlast(evict,":"))) />
			<cfset evict = listfirst(evict,":") />
		<cfelseif listfindnocase("auto,fresh,perf",evict)>
			<cfset evict = "none" />
		</cfif>
		
		<cfset result = getStruct( 
			context = typeMan.getAvailableContext(context), 
			storageType = cfg.getPreferredMedium(context), 
			evictPolicy = evict, 
			evictAfter = evictAfter, 
			agentid = getAgentID(context,agent.getAppName(),agent.getAgentName())
		) />
		
		<!--- add settings from the XML doc to the defaults --->
		<cfset structAppend(result,getAgentSettingsXML(result.agentID),true) />
		
		<!--- if the storage type for the specified context isn't available, then we revert to default storage --->
		<cfif not typeMan.getStorageType(result.storageType).isReady()>
			<cfset result.storageType = "default" />
			<cfset result.context = iif(result.context is "application",de("application"),de("server")) />
			
			<!--- if we changed the context, then we need to change the agentid to ensure proper identification --->
			<cfset result.agentID = getAgentID(result.context,agent.getAppName(),agent.getAgentName()) />
			
			<!--- if we changed the context, then we might have new config settings for the new context --->
			<cfset structAppend(result,getAgentSettingsXML(result.agentID),true) />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getAgentSettingsXML" access="public" output="false" returntype="struct" 
	hint="I fetch the manually configured settings for a specific caching agent">
		<cfargument name="agentid" type="string" required="true" />
		<cfset var settings = getSavedSettings() />
		<cfset var result = StructNew() />
		<cfset var node = 0 />
		
		<cfset result["id"] = arguments.agentid />
		<cflock name="#getLock()#" type="exclusive" timeout="10">
			<cfset node = XmlSearch(settings,"//agents/agent[@id='#xmlformat(agentid)#']") />
			<cfif ArrayLen(node) and IsXmlElem(node[1])>
				<cfset structAppend(result,node[1].xmlAttributes,false) />
			</cfif>
		</cflock>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="listPermanentSettingsForAgent" access="public" output="false" returntype="string">
		<cfargument name="agentid" type="string" required="true" />
		<cfreturn structKeyList(getAgentSettingsXML(agentid)) />
	</cffunction>
	
	<cffunction name="setAgentConfig" access="public" output="false" 
	hint="I set the storage type and eviction policy for a specific agent">
		<cfargument name="agentid" type="string" required="true" />
		<cfargument name="permanent" type="string" required="false" default="" />
		<cfargument name="storagetype" type="string" required="false" default="" />
		<cfargument name="evictpolicy" type="string" required="false" default="" />
		<cfargument name="evictafter" type="numeric" required="false" default="0" />
		
		<cfset var settings = getSavedSettings() />
		<cfset var config = getAgentConfig(arguments.agentid) />
		<cfset var xml = getAgentSettingsXML(arguments.agentid) />
		<cfset var perm = getStruct( storage = listfindnocase(permanent,"storage"), evict = listfindnocase(permanent,"evict") ) />
		<cfset var mymax = 0 />
		
		<cflock name="#getLock()#" type="exclusive" timeout="10">
			<cfif len(trim(arguments.storagetype))>
				<cfset config.storagetype = arguments.storagetype />
				<cfif perm.storage>
					<cfset xml["storagetype"] = arguments.storagetype />
				</cfif>
			<cfelseif perm.storage>
				<cfset StructDelete(xml, "storagetype") />
			</cfif>
			
			<cfif len(trim(arguments.evictpolicy))>
				<cfset arguments.evictpolicy = rereplacenocase(arguments.evictpolicy, "^auto$", "") />
				
				<cfif len(trim(arguments.evictpolicy))>
					<cfset config.evictpolicy = arguments.evictpolicy />
					<cfset config.evictafter = max(1, val(arguments.evictafter)) />
					<cfif perm.evict>
						<cfset xml["evictpolicy"] = config.evictpolicy />
						<cfset xml["evictafter"] = config.evictafter />
					</cfif>
					
					<cfif not getPolicyManager().getPolicy(config.evictPolicy).hasThreshold()>
						<cfset config.evictafter = 0 />
					</cfif>
				<cfelse>
					<cfset config.evictpolicy = "none" />
					<cfset structDelete(config, "evictafter") />
					<cfif perm.evict>
						<cfset StructDelete(xml, "evictpolicy") />
						<cfset StructDelete(xml, "evictafter") />
					</cfif>
				</cfif>
			</cfif>
			
			<cfif len(trim(arguments.permanent))>
				<cfset saveSettings(XmlTransform(settings, getAddXSL(), xml)) />
			</cfif>
		</cflock>
	</cffunction>
	
	<cffunction name="getSavedSettings" access="private" output="false" 
	hint="I fetch saved settings for all agents from an XML document">
		<cfif not isXmlDoc(instance.settings)>
			<!--- settings haven't been read from the file yet --->
			<cflock name="#getLock()#" type="exclusive" timeout="10">
				<!--- check to see if there is a file --->
				<cfset temp = "#getConfigDir()##instance.savedsettings#" />
				<cfif fileExists("#getConfigDir()##instance.savedsettings#")>
					<cfset instance.settings = XmlParse("#getConfigDir()##instance.savedsettings#") />
				<cfelse>
					<!--- there isn't a file, create a default xml document instead --->
					<cfset instance.settings = XmlParse("<agents />") />
				</cfif>
			</cflock>
		</cfif>
		
		<cfreturn instance.settings />
	</cffunction>
	
	<cffunction name="getDropXSL" access="private" output="false" 
	hint="I get the XSL template for removing an agent from the XML file">
		<cfset var xsl = 0 />
		<cffile action="read" variable="xsl" file="#getConfigDir()#/agentdrop.xsl.cfm" />
		<cfreturn xsl />
	</cffunction>
	
	<cffunction name="getAddXSL" access="private" output="false"
	hint="I get the XSL template for adding or updating an agent in the XML file">
		<cfset var xsl = 0 />
		<cffile action="read" variable="xsl" file="#getConfigDir()#/agentadd.xsl.cfm" />
		<cfreturn xsl />
	</cffunction>
	
	<cffunction name="dropAgentConfig" access="public" output="false" 
	hint="I remove saved settings for an agent from the XML document">
		<cfargument name="agentid" type="string" required="true" />
		<cfset var settings = getSavedSettings() />
		
		<cflock name="#getLock()#" type="exclusive" timeout="10">
			<cfset saveSettings(XmlTransform(settings,getDropXSL(),arguments)) />
		</cflock>
	</cffunction>
	
	<cffunction name="saveSettings" access="private" output="false" 
	hint="I write settings information to an XML document">
		<cfargument name="settings" type="string" required="true" />
		
		<cffile action="write" file="#getConfigDir()##instance.savedsettings#" output="#arguments.settings#" />
		<cfset instance.settings = XmlParse(arguments.settings) />
	</cffunction>
	
</cfcomponent>

