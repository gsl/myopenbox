<!--- 
	*** DO NOT MODIFY THIS FILE *** 
	*** DO NOT MODIFY THIS FILE *** 
	*** DO NOT MODIFY THIS FILE *** 
	
	The intelligence agent can be customized by creating 
	the component /cachebox/settings/intelligence.cfc 
	and extending this component like this: 
	<cfcomponent extends="cachebox.intelligence">
		... custom settings here ... 
	</cfcomponent>
--->
<cfcomponent output="false" extends="util" 
hint="I accept a query containing cache data for a set of agents and produce a set of recommendations for those agents">
	
	<!--- a higher number for perf will cause content to be stored longer, 
		while a lower number for fresh will cause it to expire sooner and be refreshed more often --->
	<cfset instance.auto = getStruct( perf = 1.5, auto = 1, fresh = 0.5 ) />
	
	<!--- a list of specific brains to load for analysis first before other brains are applied --->
	<cfset instance.loadPriority = "" />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset super.init(argumentcollection=arguments) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="analyze" access="public" output="false" returntype="array">
		<cfargument name="cache" type="query" required="true" />
		<cfargument name="all" type="boolean" required="false" default="false" hint="when true, more than one recommendation may be returned for each agent" />
		<cfset var intelligence = getAnalysisChain() />
		<cfset var stats = getOptimizationStats( cache ) />
		<cfset var mgr = getConfig().getAgentManager() />
		<cfset var auto = instance.auto />
		<cfset var result = ArrayNew(1) />
		<cfset var conf = 0 />
		<cfset var brain = 0 />
		<cfset var rec = 0 />
		<cfset var x = 0 />
		
		<cfloop index="x" from="1" to="#ArrayLen(stats)#">
			<!--- this line is hotly debated --->
			<cfset brain = intelligence />
			
			<!--- we need this to check to see if the recommendation is already applied --->
			<cfset conf = mgr.getAgentConfig(stats[x].agentid) />
			
			<cfloop condition="isObject(brain)">
			
				<!--- ask the brain for a recommendation --->
				<cfset rec = brain.getRecommendation(stats[x], iif(structKeyExists(auto, stats[x].evictPolicy), "auto[stats[x].evictPolicy]", 1)) />
				
				<!--- check to see if the brain recommended something --->
				<cfif structKeyExists(rec, "evictPolicy") and len(trim(rec.evictPolicy))>
					<cfparam name="rec.evictAfter" type="string" default="" />
					
					<!--- don't add any recommendations that are already applied --->
					<cfif conf.evictPolicy is not rec.evictPolicy or val(conf.evictAfter) neq val(rec.evictAfter)>
						
						<!--- recommendedBy doesn't show up in the management application, 
							but should be useful in debugging new analysis objects --->
						<cfset rec.recommendedBy = brain.className />
						
						<!--- setting agentid here allows the analysis object to ignore it --->
						<cfset rec.agentid = stats[x].agentid />
						
						<!--- add the final recommendation to the list --->
						<cfset ArrayAppend(result, rec) />
						
						<!--- if we haven't asked for all recommenations, then move on to analyze the next agent --->
						<cfif not arguments.all><cfbreak /></cfif>
						
					</cfif>
					
				</cfif>
				
				<!--- move to the next brain to see what it suggests --->
				<cfset brain = brain.getNext() />
			</cfloop>
		</cfloop>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getConfigDirectory" access="private" output="false" returntype="string">
		<cfreturn getDirectoryFromPath(getConfig().getFingerprint()) & "/settings/intelligence/" />
	</cffunction>
	
	<cffunction name="getConfigClassPath" access="private" output="false" returntype="string">
		<cfreturn "settings.intelligence" />
	</cffunction>
	
	<cffunction name="getBrainList" access="private" output="false" returntype="string">
		<cfset var classPath = getConfigClassPath() />
		<cfset var loadFirst = instance.loadPriority />
		<cfset var brains = ArrayNew(1) />
		<cfset var className = "" />
		<cfset var qry = 0 />
		
		<!--- get a list of the components in the directory --->
		<cfdirectory action="list" name="qry" directory="#getConfigDirectory()#" filter="*.cfc" />
		
		<cfloop query="qry">
			<cfset className = rereplacenocase( qry.name, "\.cfc$", "" ) />
			<cfif not findnocase( "abstract" , qry.name ) and not listfindnocase( loadFirst, className )>
				<cfset arrayAppend( brains, classPath & "." & className ) />
			</cfif>
		</cfloop>
		
		<cfset loadFirst = listToArray(loadFirst) />
		<cfloop index="className" from="#ArrayLen(loadFirst)#" to="1" step="-1">
			<cfset ArrayAppend( brains, classPath & "." & loadFirst[className] ) />
		</cfloop>
		
		<cfreturn ArrayToList( brains ) />
	</cffunction>
	
	<cffunction name="getAnalysisChain" access="private" output="false">
		<cfset var cfg = getConfig() />
		<cfset var className = "" />
		<cfset var brain = 0 />
		<cfset var qry = 0 />
		
		<cfloop index="className" list="#getBrainList()#">
			<cfset brain = CreateObject( "component" , className ).init( cfg , this , brain ) />
			<cfset brain.className = listLast(className, ".") />
		</cfloop>
		
		<cfreturn brain />
	</cffunction>
	
	<cffunction name="getOptimizationStats" access="private" output="false" returntype="array" 
	hint="I get generalized statistics for agents from a cache query to use in optimization">
		<cfargument name="cache" type="query" required="true" hint="I'm the entire collection of data stored for these agents as it exists right now" />
		<cfargument name="automated" type="boolean" required="false" default="false" hint="if true, the optimization stats will be limited to only the agents that can be automatically set" />
		<cfset var minutes = getHistory().getMinutes() />
		<cfset var mgr = getAgentManager() />
		<cfset var col = getStruct( agentid=ArrayNew(1), perm=ArrayNew(1), storageType=ArrayNew(1), evictPolicy=ArrayNew(1), evictAfter=ArrayNew(1) ) />
		<cfset var result = 0 />
		<cfset var config = 0 />
		<cfset var agentid = 0 />
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
				max(hitCount/(<cfqueryparam value="#minutes#" cfsqltype="cf_sql_integer">-cast(timeStored as integer))) as MinFrequency, 
				min(hitCount/(<cfqueryparam value="#minutes#" cfsqltype="cf_sql_integer">-cast(timeStored as integer))) as MaxFrequency 
			from cache where expired = 0 and timeStored is not null and timeStored > 0 <!--- don't include miss-counters in the calculations --->
			group by context, appname, agentname 
			order by occupancy desc 
		</cfquery>
		
		<cfloop query="result">
			<!--- we'll need the agentid later when we set eviction policies for auto-configuring agents --->
			<cfset agentid = mgr.getAgentID(result.context, result.appName, result.agentName) />
			<cfset ArrayAppend(col.agentid, agentid) />
			
			<!--- don't change or override permanent configurations --->
			<cfset ArrayAppend(col.perm, lcase(mgr.listPermanentSettingsForAgent(agentid))) />
			<cfset config = mgr.getAgentConfig(agentid) />
			
			<cfloop index="i" list="storageType,evictPolicy,evictAfter">
				<cfset ArrayAppend(col[i], iif(structKeyExists(config, i), "lcase(config[i])", de(""))) />
			</cfloop>
		</cfloop>
		
		<cfloop item="i" collection="#col#">
			<cfset QueryAddColumn(result, i, col[i]) />
		</cfloop>
		
		<cfif automated>
			<!--- return only the results for agents that can be automatically configured --->
			<cfquery dbtype="query" name="result">
				select * from result 
				where perm not like '%evictpolicy%' 
					and evictpolicy in ('auto','fresh','perf') 
				order by occupancy desc 
			</cfquery>
		</cfif>
		
		<cfset result = QueryToArray(result) />
		
		<cfloop index="i" from="#ArrayLen(result)#" to="1" step="-1">
			<!--- remove records with 1.#INF - IEEEE decimal representation of an infinite value --->
			<cfif find("##INF", result[i].minfrequency) or find("##INF", result[i].meanfrequency) or find("##INF", result[i].maxfrequency)>
				<cfset ArrayDeleteAt( result , i ) />
			</cfif>
		</cfloop>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>

