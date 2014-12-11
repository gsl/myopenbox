<!--- 
	*** DO NOT MODIFY THIS FILE *** 
	*** DO NOT MODIFY THIS FILE *** 
	*** DO NOT MODIFY THIS FILE *** 
	
	To customize your CacheBox installation, create a config.cfc in this directory like this: 
	<cfcomponent extends="defaultconfig">
		... custom settings here ... 
	</cfcomponent>
--->

<cfcomponent output="false" extends="applicationconfig" hint="I provide the default settings for a CacheBox installation">
	<!--- this sets the last time the cache was optimized, used later to decide when to re-optimize --->
	<cfset instance.configTime = instance.created />
	
	<!--- the url to use for the cachebox scheduled task which monitors and reconfigures the service --->
	<cfset instance.pollingURL = "http://127.0.0.1/cachebox/monitor.cfm" />
	
	<!--- minimum number of minutes between monitoring --->
	<cfset instance.pollingInterval = 1 />
	
	<!--- minimum number of minutes between strategy optimizations --->
	<cfset instance.optimizeInterval = 5 />
	
	<!--- minimum number of records in cache before performing automated strategy optimization --->
	<cfset instance.optimizeThreshold = 100 />
	
	<!--- maximum number of minutes until out-of-memory error before performing automated strategy optimization - defaults to 2 hours --->
	<cfset instance.optimizeThresholdMinutes = 120 />
	
	<!--- maximum number of minutes until out-of-memory error before displaying the warning on the Management Application --->
	<cfset instance.destructWarningThreshold = 60 />
	
	<!--- class path to a component that will handle logging - see log.cfc for an example with more settings --->
	<cfset instance.logger = "settings.log" />
	
	<!--- preferred storage media by context --->
	<cfset instance.preferred = getStruct( cluster = "cluster", server = "default", application = "default" ) />
	
	<!--- a component for generating recommendations for the expiration of auto-configured agents --->
	<cfset instance.intelligence = "intelligence" />
	<cfset setIntelligence("cachebox.settings.intelligence") />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="service" type="any" required="true" />
		<cfargument name="testInstance" type="any" required="false" default="" />
		<cfset var test = iif(isStruct(testInstance), "testInstance", "StructNew()") />
		<cfset structDelete(arguments, "testInstance") />
		
		<cfset structAppend(instance,arguments,true) />
		
		<cfset createManagers(test) />
		<cfset updateMonitoringTask() />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getFingerprint" access="public" output="false">
		<cfreturn getService().getFingerprint() />
	</cffunction>
	
	<cffunction name="setIntelligence" access="public" output="false">
		<cfargument name="path" type="string" required="true" />
		<cfif fileExists(ExpandPath("/#listchangedelims(path, '/', '.')#.cfc"))>
			<cfset instance.intelligence = listchangedelims(path, ".", "\/") />
		</cfif>
	</cffunction>
	
	<cffunction name="getLog" access="public" output="false" returntype="any">
		<cfset var logger = instance.logger />
		
		<cfif len(trim(logger))>
			<cftry>
				<cfset logger = CreateObject( "component", logger ).init( this ) />
				
				<cfcatch>
					<!--- if there's not a logger installed, don't continue to test for one --->
					<cfrethrow />
					<cfset instance.logger = "" />
				</cfcatch>
			</cftry>
		</cfif>
		
		<cfreturn logger />
	</cffunction>
	
	<cffunction name="logEvent" access="public" output="false" returntype="boolean">
		<cfargument name="logType" type="string" required="true" />
		<cfargument name="logData" type="struct" required="true" />
		<cfset var logger = getLog() />
		<cfset var status = false />
		
		<cfif isObject(logger)>
			<cftry>
				<cfinvoke component="#logger#" method="#logType#" 
					argumentcollection="#logData#" returnvariable="status" />
				
				<cfcatch>
					<!--- don't create an infinite loop on error logs --->
					<cfif logType is "error">
						<cfrethrow />
					<cfelse>
						<cfinvoke component="#logger#" method="error" errorData="#cfcatch#" />
					</cfif>
				</cfcatch>
			</cftry>
		</cfif>
		
		<cfreturn status />
	</cffunction>
	
	<cffunction name="CreateManagers" access="private" output="false" returntype="void">
		<cfargument name="test" type="struct" required="false" default="" />
		<cfset test = iif(isStruct(test), "test", "StructNew()") />
		
		<cfset instance.history = CreateObject("component","history").init(this) />
		<cfset instance.clusterManager = CreateObject("component","clustermanager").init(this) />
		<cfset instance.agentManager = CreateObject("component","agentmanager").init(this) />
		<cfset instance.policyManager = CreateObject("component","policymanager").init(this) />
		<cfset instance.storageManager = CreateObject("component","storagemanager").init(this) />
		
		<cfset structAppend(instance, test, true) />
	</cffunction>
	
	<cffunction name="testInstanceExport" access="public" output="false">
		<cfreturn getStruct( 
			history = instance.history, 
			clusterManager = instance.clusterManager, 
			agentManager = instance.agentManager, 
			policyManager = instance.policyManager, 
			storageManager = instance.storageManager 
		) />
	</cffunction>
	
	<cffunction name="getDestructWarningThreshold" access="public" output="false" returntype="numeric">
		<cfreturn instance.destructWarningThreshold />
	</cffunction>
	
	<cffunction name="getHistory" access="public" output="false">
		<cfreturn instance.history />
	</cffunction>
	
	<cffunction name="getHistorySize" access="public" output="false">
		<cfreturn 4 * instance.pollingInterval * instance.optimizeInterval />
	</cffunction>
	
	<cffunction name="getService" access="public" output="false">
		<cfreturn instance.service />
	</cffunction>
	
	<cffunction name="getStorage" access="private" output="false">
		<cfreturn getService().getStorage() />
	</cffunction>
	
	<cffunction name="getPolicyManager" access="public" output="false">
		<cfreturn instance.PolicyManager />
	</cffunction>
	
	<cffunction name="getStorageManager" access="public" output="false">
		<cfreturn instance.StorageManager />
	</cffunction>
	
	<cffunction name="getAgentManager" access="public" output="false">
		<cfreturn instance.AgentManager />
	</cffunction>
	
	<cffunction name="getClusterManager" access="public" output="false">
		<cfreturn instance.ClusterManager />
	</cffunction>
	
	<cffunction name="updateMonitoringTask" access="private" output="false" 
	hint="I schedule a task to monitor and reconfigure the cache at specified intervals - this method can be overridden in the config.cfc if you prefer another method of scheduling the monitor aside from cfschedule">
		<!--- *** NOTE: an interval of exactly 60 seconds doesn't seem to work with Adobe CF *** --->
		<cfschedule task="cachebox #getFingerprint()#" action="update" 
			startdate="#dateformat(now())#" starttime="12:00 AM" 
			interval="#max(61,instance.pollingInterval * 60)#" 
			operation="httprequest" url="#instance.pollingURL#" />
	</cffunction>
	
	<cffunction name="createStorage" access="public" output="false" hint="I create the storage component that manages the main cache query">
		<cfreturn CreateObject("component","cacheboxstorage").init(this) />
	</cffunction>
	
	<cffunction name="monitorCache" access="public" output="false" 
	hint="I monitor the cache and call configure and purge as needed">
		<cfset var mgr = getAgentManager() />
		<cfset var history = getHistory() />
		<cfset var logData = StructNew() />
		
		<cftry>
			<!--- don't poll more often than the poling interval and don't optimize unless we're polling --->
			<cfif DateDiff("n", history.getLastSnapshot().time, now()) gte instance.pollingInterval>
				<cfset history.getSnapshot() />
				<cfset analyze() />
			</cfif>
			<cfcatch>
				<cfset logData.errorData = cfcatch />
				<cfset logEvent( "error" , logData ) />
				<cfrethrow />
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="analyze" access="public" output="false" hint="I optimize and then purge the cache">
		<cfset var cache = getStorage().getCacheCopy() />
		
		<!--- 
			only optimize if there's a sufficient amount of content in the cache 
			to start measuring, otherwise low sample sizes may cause miscalculations 
		--->
		<cfif cache.recordcount gte instance.optimizeThreshold 
		and DateDiff("n", instance.configTime, now()) gte instance.optimizeInterval>
			<cfset optimize(cache) />
		</cfif>
		
		<cfset reap(cache) />
	</cffunction>
		
	<cffunction name="detectCrisis" access="public" output="false" returntype="boolean" 
	hint="returns true if a memory crisis is detected within the window of time specified by instance.optimizeThresholdMinutes (default is 2 hours)">
		<cfset var crisis = getHistory().getCountDownToTotalDestruction() />
		<cfreturn iif(crisis.MinutesRemaining gt 0 and crisis.MinutesRemaining lte instance.optimizeThresholdMinutes, true, false) />
	</cffunction>
	
	<cffunction name="getAgentRecommendations" access="public" output="false" returntype="Array">
		<cfargument name="agentid" type="string" required="true" />
		<cfreturn getRecommendations(agentid & "|%", true) />
	</cffunction>
	
	<cffunction name="getIntelligence" access="private" output="false">
		<!--- don't cache the intelligence so it can be changed without restarting the server --->
		<cfreturn CreateObject("component", instance.intelligence).init(this) />
	</cffunction>
	
	<cffunction name="getRecommendations" access="public" output="false" returntype="Array">
		<cfargument name="stats" type="any" required="true" />
		<cfargument name="all" type="boolean" required="false" default="false" hint="when true, more than one recommendation may be returned for each agent" />
		<cfset var rec = 0 />
		<cfset var result = ArrayNew(1) />
		<cfset var x = 0 />
		
		<cfif isSimpleValue( stats )>
			<cfset stats = getStorage().select( stats , true ) />
		<cfelseif not isQuery( stats )>
			<cfthrow type="CacheBox.Impl.Arguments.Recommendations" 
				message="The Stats argument to the getRecommendations method must be a query or a cache search string" />
		</cfif>
		
		<cfset result = getIntelligence().analyze( stats , all ) />
		
		<!--- remove any recommendations where arithmetic errors caused the result 
		to have a threshold of 1.#INF (infinite) or 1.#IND (indeterminate)
		-- these are IEEE floating-point exceptions --->
		<cfloop index="x" from="#ArrayLen(result)#" to="1" step="-1">
			<cfif find("##", result[x].evictAfter)>
				<cfset ArrayDeleteAt(result, 1) />
			</cfif>
		</cfloop>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="applyRecommendations" access="public" output="false" returntype="struct">
		<cfargument name="recommendations" type="array" required="true" />
		<cfargument name="permanent" type="string" required="false" default="" />
		<cfargument name="logtype" type="string" required="false" default="AUTOCONFIG" />
		<cfset var applied = structNew() />
		<cfset var mgr = getAgentManager() />
		<cfset var perm = arguments.permanent />
		<cfset var logdata = StructNew() />
		<cfset var rec = 0 />
		<cfset var x = 0 />
		
		<cfif isBoolean(permanent) and permanent>
			<cfset perm = "storage,evictpolicy" />
		</cfif>
		
		<cfloop index="x" from="1" to="#ArrayLen(recommendations)#">
			<cfset rec = recommendations[x] />
			
			<cfif not structKeyExists( applied , rec.agentid )>
				<cfset rec.permanent = perm />
				<cfset mgr.setAgentConfig(argumentCollection = rec) />
				
				<cfset logData.settings = rec />
				<cfset logData.recommendedBy = rec.recommendedBy />
				<cfset logEvent( logType , logData ) />
				
				<cfset applied[rec.agentid] = rec />
			</cfif>
		</cfloop>
		
		<cfreturn applied />
	</cffunction>
	
	<cffunction name="optimize" access="private" output="false" 
	hint="I reconfigure agents based on available statistics, storage types and eviction policies">
		<cfargument name="cache" type="query" required="true" hint="I'm the entire collection of data stored for these agents as it exists right now" />
		<cfset var rec = 0 />
		<cfset instance.configTime = now() />
		
		<cfif this.detectCrisis()>
			<!--- There's a predicted memory failure in under 2 hours -- attempt to optimize the agents to prevent it --->
			<cfset rec = applyRecommendations( getRecommendations( cache ) ) />
			<cfset sendAlertMessage( rec ) />
		</cfif>
	</cffunction>
	
	<cffunction name="sendAlertMessage" access="public" output="false">
		<cfargument name="recommendations" type="struct" required="false" default="#StructNew()#" />
		<cfset var fingerprint = getDirectoryFromPath(getFingerprint()) />
		<cfset var mailObj = fingerprint & "/settings/email.cfc" />
		<cfset var rec = recommendations />
		<cfset var minutes = 0 />
		<cfset var message = 0 />
		<cfset var x = 0 />
		
		<cfif fileexists(mailObj)>
			<cfset minutes = getWarningMinutes() />
			
			<cfsavecontent variable="message"><cfoutput>
CacheBox has predicted a possible memory failure. 

CacheBox Instance: #fingerprint# 
Minutes To Failure: #minutes# 
Items Stored: #getStorage().getOccupancy()# 
Recommendations Applied: #StructCount(rec)# 

<cfif not StructIsEmpty(rec)>Recommendations: 
<cfloop item="x" collection="#rec#">
AgentID: #x# 
Evict Policy: #rec[x].evictPolicy# <cfif structKeyExists(rec[x], "evictAfter") and val(rec[x].evictAfter)>(#rec[x].evictAfter#)</cfif>
Recommended By: #rec[x].recommendedBy# 
</cfloop></cfif>
			</cfoutput></cfsavecontent>
			
			<cfinvoke component="settings.email" method="sendAlert" 
				subject="CacheBox : Possible memory failure in #minutes# minutes." message="#trim(message)#">
		</cfif>
	</cffunction>
	
	<cffunction name="reap" access="public" output="false" hint="I remove expired content from the cache">
		<cfargument name="cache" type="query" required="true" hint="I'm the entire collection of data stored for these agents as it exists right now" />
		<cfset var agents = getAgentManager().getAllAgents() />
		<cfset var time = getHistory().getMinutes() />
		<cfset var policyMan = getPolicyManager() />
		<cfset var all = getStorage().allColumns() />
		<cfset var content = 0 />
		<cfset var expired = 0 />
		<cfset var result = 0 />
		<cfset var x = 0 />
		<cfset var i = 0 />
		
		<cfloop item="x" collection="#agents#">
			<!--- get the content for this agent --->
			<cfquery name="content" dbtype="query" debug="false">
				select #all# from cache 
				where expired = 0 
					and cachename like <cfqueryparam value="#x#" cfsqltype="cf_sql_varchar" />
			</cfquery>
			
			<cfif content.recordcount>
				<!--- feed content for this agent to the eviction policy for expiration --->
				<cfinvoke component="#policyMan.getPolicy(agents[x].evictPolicy)#" 
					method="getExpiredContent" 
					returnvariable="expired" 
					cachename="#x#" 
					evictLimit="#agents[x].evictAfter#" 
					currentTime="#time#" 
					cache="#content#" />
				
				<!--- if the eviciton policy returned any expired indexes, mark them expired --->
				<cfloop index="i" from="1" to="#ArrayLen(expired)#">
					<cfset cache.expired[expired[i]] = 1 />
				</cfloop>
			</cfif>
		</cfloop>
		
		<!--- fetch a query with all the expired cache items for deletion --->
		<cfquery name="result" dbtype="query" debug="false">
			select #all# from arguments.cache where expired = 1 
		</cfquery>
		
		<!--- tell the storage object which records we want to remove --->
		<cfset getStorage().reap(result) />
	</cffunction>
	
	<cffunction name="getPreferredMedium" access="public" output="false">
		<cfargument name="context" type="string" required="true" />
		<cfif structKeyExists(instance.preferred,arguments.context)>
			<cfreturn instance.preferred[arguments.context] />
		</cfif>
		
		<cfreturn "default" />		
	</cffunction>
	
	<cffunction name="getWarningMinutes" access="public" output="false" returntype="numeric" 
	hint="if the system predicts a memory failure within the warning threshold, this function returns the number of minutes until the predicted failure - otherwise it returns zero">
		<cfset var minutes = getHistory().getCountDownToTotalDestruction().minutesRemaining />
		<cfreturn iif(minutes gt 0 and minutes lte getDestructWarningThreshold(), "minutes", 0) />
	</cffunction>
	
	<cffunction name="getAdminService" access="public" output="false">
		<cfset var href = cgi.HTTP_HOST & "/" & cgi.PATH_INFO & "?" & cgi.QUERY_STRING />
		<cfset var isTest = findnocase("cbxtestsite", href) />
		<cfset var temp = iif(isTest, "CreateObject('component','testservice').init(this)", "getService()") />
		<cfreturn temp />
	</cffunction>
	
	<cffunction name="createTestStorage" access="public" output="false" hint="I create a modified storage component for testing purposes">
		<cfargument name="config" type="any" required="true" hint="the live config object can provide test data if desired - overwrite this method if you want to create test data some other way" />
		<cfset var storage = CreateObject("component","teststorage").init(this) />
		<cfset var srv = config.getService() />
		<!--- 
			care should be taken with this test storage component because delete/expire 
			operations on a copy of live data are likely to cause errors in the live service 
			- this copy is primarily intended for testing optimization analysis 
		--->
		<cfset storage.setIndex(srv.getStorage().getCacheCopy()) />
		<cfreturn storage />
	</cffunction>
	
</cfcomponent>

