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
	
	<!--- preferred storage media by context --->
	<cfset instance.preferred = getStruct( cluster = "cluster", server = "default", application = "default" ) />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="service" type="any" required="true" />
		
		<cfset structAppend(instance,arguments,true) />
		
		<cfset createManagers() />
		<cfset updateMonitoringTask() />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="CreateManagers" access="private" output="false" returntype="void">
		<cfset instance.history = CreateObject("component","history").init(this) />
		<cfset instance.clusterManager = CreateObject("component","clustermanager").init(this) />
		<cfset instance.agentManager = CreateObject("component","agentmanager").init(this) />
		<cfset instance.policyManager = CreateObject("component","policymanager").init(this) />
		<cfset instance.storageManager = CreateObject("component","storagemanager").init(this) />
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
		<cfschedule task="cachebox #getService().getFingerPrint()#" action="update" 
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
		
		<!--- don't poll more often than the poling interval and don't optimize unless we're polling --->
		<cfif DateDiff("n",history.getLastSnapshot().time,now()) gte instance.pollingInterval>
			<cfset history.getSnapshot() />
			<cfset analyze() />
		</cfif>
	</cffunction>
	
	<cffunction name="analyze" access="public" output="false" hint="I optimize and then purge the cache">
		<cfset var cache = getStorage().getCacheCopy() />
		
		<!--- don't bother reconfiguring until there's a goodly amount of content in the cache to start measuring, otherwise low sample sizes may cause miscalculations --->
		<cfif cache.recordcount gte instance.optimizeThreshold and DateDiff("n",instance.configTime,now()) gte instance.optimizeInterval>
			<cfset optimize(cache) />
		</cfif>
		
		<cfset reap(cache) />
	</cffunction>
	
	<cffunction name="getOptimizationStats" access="private" output="false" 
	hint="I get generalized statistics for agents from a cache query to use in optimization">
		<cfargument name="cache" type="query" required="true" hint="I'm the entire collection of data stored for these agents as it exists right now" />
		<cfset var minutes = getHistory().getMinutes() />
		<cfset var mgr = getAgentManager() />
		<cfset var col = getStruct( agentid=ArrayNew(1), agent=ArrayNew(1), perm=ArrayNew(1), storageType=ArrayNew(1), evictPolicy=ArrayNew(1), evictAfter=ArrayNew(1) ) />
		<cfset var result = 0 />
		<cfset var config = 0 />
		<cfset var perm = 0 />
		<cfset var i = 0 />
		
		<cfquery name="result" dbtype="query" debug="false">
			select context, appname, agentname, 
				count(index) as occupancy, 
				sum(hitCount) as hits, 
				sum(missCount) as misses, 
				<cfqueryparam value="#minutes#" cfsqltype="cf_sql_integer">-cast(min(timeStored) as integer) as oldest, 
				<cfqueryparam value="#minutes#" cfsqltype="cf_sql_integer">-cast(max(timeHit) as integer) as lastHit, 
				<cfqueryparam value="#minutes#" cfsqltype="cf_sql_integer">-cast(avg(timeStored) as integer) as MeanAge, 
				avg(hitCount/(<cfqueryparam value="#minutes#" cfsqltype="cf_sql_integer">-cast(timeStored as integer))) as MeanFrequency, 
				max(hitCount/(<cfqueryparam value="#minutes#" cfsqltype="cf_sql_integer">-cast(timeStored as integer))) as MinFrequency 
			from cache where timeStored is not null and timeStored > 0 <!--- don't include miss-counters in the calculations --->
			group by context, appname, agentname 
			order by occupancy desc 
		</cfquery>
		
		<cfloop query="result">
			<!--- we'll need the agentid later when we set eviction policies for auto-configuring agents --->
			<cfset config = mgr.getAgentID(result.context,result.appName,result.agentName) />
			<cfset ArrayAppend(col.agentid,config) />
			<cfset ArrayAppend(col.perm,structKeyList(mgr.getAgentSettingsXML(config))) /><!--- don't change or override permanent configurations --->
			<cfset config = mgr.getAgentConfig(config) />
			<cfloop index="i" list="agent,storageType,evictPolicy,evictAfter">
				<cfif structKeyExists(perm,i)>
					<cfset ArrayAppend(col[i],config[i]) />
				</cfif>
			</cfloop>
		</cfloop>
		
		<cfloop item="i" collection="#col#">
			<cfset QueryAddColumn(result,i,col[i]) />
		</cfloop>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="optimize" access="private" output="false" 
	hint="I reconfigure agents based on available statistics, storage types and eviction policies">
		<cfargument name="cache" type="query" required="true" hint="I'm the entire collection of data stored for these agents as it exists right now" />
		<cfset var crisis = getHistory().getCountDownToTotalDestruction() />
		<cfset var mgr = getAgentManager() />
		<cfset var stats = 0 />
		<cfset var temp = 0 />
		
		<cfset instance.configTime = now() />
		
		<!--- TO DO: use the remaining time statistic along with average memory consumption and agent settings 
		to reassign agents to a combined strategy (types and eviction policies) that will prevent the out-of-memory condition --->
		<cfif crisis.MinutesRemaining gt 0 and crisis.MinutesRemaining lte instance.optimizeThresholdMinutes>
			<!--- There's a predicted memory failure in under 2 hours -- attempt to optimize the agents to prevent it --->
			<cfset stats = getOptimizationStats(cache) />
			<cfloop query="stats">
				<cfif listfindnocase("auto,fresh,perf",stats.agent.getEvictPolicy()) and not listfindnocase(stats.perm,"evictPolicy")>
					<!--- this is an auto-configurable agent and has not been permanently set to a specific eviction policy --->
					<cfif stats.meanFrequency gte 1 and stats.minFrequency gt 2 * stats.meanFrequency>
						<!--- there are items in cache slower than twice the average frequency 
						-- this is a good candidate for an idle eviction policy --->
						<cfset mgr.setAgentConfig(agentid=stats.agentid, 
															evictPolicy="idle", 
															evictAfter=ceiling(2 * stats.meanFrequency)) />
					<cfelseif stats.MeanAge gte int(stats.oldest / 2)>
						<!--- average age is more than half the oldest age 
						-- these objects are stored early and kept in cache for a long time 
						-- we can clean them out periodically by usage, least recent first --->
						<cfset mgr.setAgentConfig(agentid=stats.agentid,
														  evictPolicy="lru",
														  evictAfter=int(stats.occupancy*0.75)) />
					</cfif>
				</cfif>
			</cfloop>
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
	
</cfcomponent>

