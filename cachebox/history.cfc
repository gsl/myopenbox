<cfcomponent displayname="CacheBox.History" output="false" extends="util" 
hint="I record statistical information about the cache for the lifespan of the server">
	<cfset setLog(QueryNew("time,interval,occupancy,freeMemory,cachedelta,memdelta","timestamp,integer,integer,integer,integer,integer")) />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset structAppend(instance,arguments,true) />
		<cfset instance.Snapshot = appendSnapshot(getDefaultSnapshot()) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getLog" access="public" output="false" returntype="query">
		<cfreturn instance.history />
	</cffunction>
	
	<cffunction name="setLog" access="private" output="false">
		<cfargument name="history" type="query" required="true" />
		<cfset instance.history = arguments.history />
	</cffunction>
	
	<cffunction name="getRuntime" access="private" output="false">
		<cfreturn CreateObject("java","java.lang.Runtime").getRuntime() />
	</cffunction>
	
	<cffunction name="getMaxMemory" access="public" output="false">
		<cfset var rt = getRuntime() />
		<cfreturn int((rt.freeMemory() + rt.maxMemory()) / 1024) />
	</cffunction>
	
	<cffunction name="getAllocatedMemory" access="public" output="false">
		<cfreturn int(getRuntime().totalMemory() / 1024) />
	</cffunction>
	
	<cffunction name="getFreeMemory" access="public" output="false">
		<cfset var rt = getRuntime() />
		<cfreturn int((rt.freeMemory() + rt.maxMemory() - rt.totalMemory()) / 1024) />
	</cffunction>
	
	<cffunction name="getPercentFreeMemory" access="public" output="false">
		<cfset var rt = getRuntime() />
		<cfset var total = rt.freeMemory() + rt.maxMemory() />
		<cfset var free = total - rt.totalMemory() />
		<cfreturn int((free / total) * 100) />
	</cffunction>
	
	<cffunction name="getDefaultSnapshot" access="private" output="false" 
	hint="creates the default snapshot of system resources at the time the service is created">
		<cfset var result = structNew() />
		<cfset result.time = now() />
		<cfset result.occupancy = 0 />
		<cfset result.cachedelta = 0 />
		<cfset result.memdelta = 0 />
		<cfset result.freeMemory = getFreeMemory() />
		<cfset result.interval = 0 />
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getLastSnapshot" access="public" output="false">
		<cfreturn instance.snapshot />
	</cffunction>
	
	<cffunction name="getSnapshot" access="public" output="false" 
	hint="creates a snapshot of system resources at the current time including memory utilization info since the last snapshot">
		<cfset var last = getLastSnapshot() />
		<cfset var result = getDefaultSnapshot() />
		
		<!--- number of seconds since the last snapshot - the default configuration uses a scheduled task once per minute, but different configurations may change that behavior 
		--- also under heavy load (or memory scarcity) the time between snapshots can be as much as 9 minutes despite the 1-minute polling interval --->
		<cfset result.interval = DateDiff("s",last.time,result.time) />
		<cfset result.occupancy = getService().getOccupancy() />
		
		<!--- delta values help to determine how much cache needs to be evicted or offloaded to maintain the applications --->
		<cfset result.cachedelta = result.occupancy - last.occupancy />
		<cfset result.memdelta = result.freeMemory - last.freeMemory />
		
		<!--- save this data in addition to the log as the most recent set --->
		<cfset instance.snapshot = appendSnapshot(result) />
		
		<!--- remove any extra history records --->
		<cfset trimHistory() />
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="appendSnapshot" access="private" output="false" hint="adds a snapshot to the history query">
		<cfargument name="snapshot" type="struct" required="true" />
		<cfset var history = getLog() />
		<cfset var x = 0 />
		
		<cflock name="#getCurrentTemplatePath()#" type="exclusive" timeout="10">
			<cfset QueryAddRow(history,1) />
			<cfset x = history.recordcount />
			<cfset history.time[x] = snapshot.time />
			<cfset history.interval[x] = snapshot.interval />
			<cfset history.occupancy[x] = snapshot.occupancy />
			<cfset history.freeMemory[x] = snapshot.freeMemory />
			<cfset history.cachedelta[x] = snapshot.cachedelta />
			<cfset history.memdelta[x] = snapshot.memdelta />
		</cflock>
		
		<cfset arguments.lastLogTime = getLastLogTime() />
		<cfif getConfig().logEvent( "history" , arguments )>
			<cfset setLastLogTime() />
		</cfif>
		
		<cfreturn snapshot />
	</cffunction>
	
	<cffunction name="trimHistory" access="private" output="false">
		<cfset var history = getLog() />
		<cfset var size = 0 />
		
		<!--- don't grow the history indefinitely, just save a few iterations for analysis --->
		<cfif structKeyExists(instance,"config")>
			<cfset size = instance.config.getHistorySize() />
			<cfif history.recordcount gt size>
				<!--- remove the oldest record from the history query --->
				<cfquery name="history" dbtype="query" debug="false">
					select * from history where [time] > <cfqueryparam value="#history.time[history.recordcount-size]#" cfsqltype="cf_sql_timestamp" />
				</cfquery>
				<cfset setLog(history) />
			</cfif>
		</cfif>
	</cffunction>
	
	<cffunction name="getCountDownToTotalDestruction" access="public" output="false" returntype="struct" 
	hint="I measure the time it will take to reach an OutOfMemory error with current trends on the server">
		<cfset var snapshot = getLastSnapshot() />
		<cfset var history = getLog() />
		<cfset var result = getStruct( 
									SampleDuration = DateDiff("s",history.time[1],history.time[history.recordcount]), 
									error = "", 
									SecondsRemaining = 0, 
									MinutesRemaining = 0 ) />
		<cfset var stats = 0 />
		<cfset var i = 0 />
		
		<cfquery name="stats" dbtype="query">
			select 
				avg(cast([interval] as integer)) as [interval], 
				avg(cast(cacheDelta as integer)) as avgCacheChange, 
				avg(cast(memDelta as integer)) as avgMemChange, 
				sum(cast(cacheDelta as integer)) as TotalChangeInCache, 
				sum(cast(memDelta as integer)) as TotalChangeInMemory 
			from history 
			where [interval] > 0 
		</cfquery>
		
		<cfif not stats.recordcount>
			<!--- there's not enough history to predict memory failure yet - return all zeros --->
			<cfloop index="i" list="#stats.columnlist#">
				<cfset result[i] = stats[i][1] />
			</cfloop>
			<cfset result.avgCost = 0 />
			<cfset result.IntervalsRemaining = 0 />
			<cfset result.MinutesRemaining = 0 />
			<cfset result.SecondsRemaining = 0 />
			<cfreturn result />
		</cfif>
		
		<cfloop index="i" list="#stats.columnlist#">
			<cfset result[i] = stats[i][1] />
		</cfloop>
		
		<cfif result.avgCacheChange gt 0 and result.avgMemChange lt 0>
			<!--- cache is growing and available memory is shrinking as expected --->
			<cfset result.avgCost = int((-result.totalChangeInMemory) / result.TotalChangeInCache) />
			<cfset result.IntervalsRemaining = -int(snapshot.freeMemory / result.avgMemChange) />
		<cfelseif result.avgCacheChange lt 0 and result.avgMemChange gt 0>
			<!--- cache is shrinking and memory is being freed up --->
			<cfset result.avgCost = int((-result.TotalChangeInMemory) / result.TotalChangeInCache) />
			<cfset result.IntervalsRemaining = 0 />
		<cfelseif result.avgCacheChange gt 0 and result.avgMemChange gt 0>
			<!--- Peculiar: available memory is increasing despite cache growth --->
			<cfset result.avgCost = 0 />
			<cfset result.IntervalsRemaining = 0 />
		<cfelseif result.avgCacheChange lt 0 and result.avgMemChange lt 0>
			<!--- DANGER: available memory is dropping despite shrinking cache - return an error message to indicate the problem --->
			<cfset result.error = "ImminentDestruction" />
			<cfset result.IntervalsRemaining = -int(snapshot.freeMemory / result.avgMemChange) />
		<cfelseif result.avgCacheChange eq 0 or result.avgMemChange eq 0>
			<!--- Peculiar: it's unlikely that either value would average out to an equilibrium, but if so, there's little threat of memory consumption --->
			<cfset result.avgCost = 0 />
			<cfset result.IntervalsRemaining = 0 />
		</cfif>
		
		<cfif result.IntervalsRemaining neq 0>
			<cfset result.SecondsRemaining = result.interval * result.IntervalsRemaining />
			<cfset result.MinutesRemaining = int(result.SecondsRemaining / 60) />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getMinutes" access="public" output="false" returntype="numeric" 
	hint="returns the number of minutes since 1/1/1970 for use in measuring the lifespan of cache">
		<cfargument name="time" type="date" required="false" default="#now()#" />
		<cfreturn DateDiff("n","1/1/1970",time) />
	</cffunction>
	
	<cffunction name="getTime" access="public" output="false" returntype="date" 
	hint="I convert a stored minute value into a date">
		<cfargument name="minutes" type="numeric" required="true" />
		<cfreturn DateAdd("n",arguments.minutes,"1/1/1970") />
	</cffunction>
	
	<cffunction name="setLastLogTime" access="private" output="false">
		<cfset instance.lastlogtime = now() />
	</cffunction>
	
	<cffunction name="getLastLogTime" access="public" output="false" returntype="string">
		<cfreturn iif( structKeyExists( instance , "lastLogTime" ) , "instance.lastLogTime" , de("") ) />
	</cffunction>
	
</cfcomponent>

