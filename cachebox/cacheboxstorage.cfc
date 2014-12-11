<cfcomponent displayname="CacheBoxStorage" output="false" extends="util">
	<cfset instance.cache = QueryNew("index,context,appName,agentName,cacheName,hitCount,missCount,timeStored,timeHit,storageType,expired,content"
												,"integer,varchar,varchar,varchar,varchar,integer,integer,integer,integer,varchar,bit,object") />
	<cfset instance.map = structNew() /><!--- the map allows us to speed up fetch operations, while still having the speed and flexibility of the query for statistics --->
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset arguments.lockname = "cachebox.#config.getService().getFingerPrint()#.storage" />
		<cfset arguments.typeManager = config.getStorageManager() />
		<cfset arguments.history = config.getHistory() />
		<cfset structAppend(instance, arguments, true) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getMinutes" access="public" output="false" returntype="numeric" 
	hint="returns the number of minutes since 1/1/1970 for use in measuring the lifespan of cache">
		<cfreturn instance.history.getMinutes() />
	</cffunction>
	
	<cffunction name="getTime" access="public" output="false" returntype="date" 
	hint="I return a date object from a stored minute value">
		<cfargument name="minutes" type="numeric" required="true" />
		<cfreturn DateAdd("n",arguments.minutes,"1/1/1970") />
	</cffunction>
	
	<cffunction name="getCacheData" access="public" output="false" returntype="query" 
	hint="returns the entire cache query for operations like reporting which might be tasked to other objects - NEVER duplicate() the result">
		<cfreturn instance.cache />
	</cffunction>
	
	<cffunction name="getLock" access="private" output="false" returntype="string">
		<cfreturn instance.lockname />
	</cffunction>
	
	<cffunction name="allColumns" access="public" output="false" returntype="string">
		<cfreturn "cast(index as integer) as index, 
					context, appName, agentName, cacheName, 
					cast(hitCount as integer) as hitcount, 
					cast(missCount as integer) as misscount, 
					cast(timeStored as integer) as timeStored, 
					cast(timeHit as integer) as timeHit, 
					storageType, expired, content" />
	</cffunction>
	
	<cffunction name="getCacheCopy" access="public" output="false" returntype="query" 
	hint="returns a duplicated copy of the entire query for operations like reporting without duplicating any of the stored objects">
		<cfset var cache = getCacheData() />
		<cfset var result = 0 />
		
		<cflock name="#getLock()#" type="readonly" timeout="10">
			<cfquery name="result" dbtype="query" debug="false">
				select #allColumns()# from cache order by index asc 
			</cfquery>
		</cflock>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="setIndex" access="public" output="false">
		<cfargument name="query" type="query" required="true" />
		
		<cflock name="#getLock()#" type="exclusive" timeout="10">
			<cfset instance.map = structNew() />
			<cfloop query="query">
				<cfset instance.map[query.cachename[currentrow]] = currentrow />
				<cfset query.index[currentrow] = currentrow />
			</cfloop>
			
			<cfset instance.cache = query />
		</cflock>
	</cffunction>
	
	<cffunction name="getOccupancy" access="public" output="false" returntype="numeric" hint="returns the number of records currently in cache">
		<cfargument name="cachename" type="string" required="false" default="" hint="a cache name string ending with a wild card (%) character" />
		<cfargument name="stored" type="boolean" required="false" default="true" hint="includes placeholders for miss-counts if this argument is false" />
		<cfset var result = getCacheData() />
		
		<cfif result.recordcount>
			<cfif arguments.stored or len(trim(arguments.cachename))>
				<cfquery name="result" dbtype="query" debug="false">
					select count(index) as occupancy from result 
					where 1 = 1 
					<cfif len(arguments.cachename)>
						<cfif not find("%",cachename)>
							<cfset cachename = cachename & "%" />
						</cfif>
						and cachename like <cfqueryparam value="#cachename#" cfsqltype="cf_sql_varchar" />
					</cfif>
					<cfif arguments.stored>
						and timeStored is not null 
						and timeStored <> 0 
						and expired is not null 
						and expired = 0 
					</cfif>
				</cfquery>
				<cfreturn val(result.occupancy) />
			<cfelse>
				<cfreturn result.recordcount />
			</cfif>
		<cfelse>
			<cfreturn 0 />
		</cfif>
	</cffunction>
	
	<cffunction name="debug" access="public" output="true">
		<cfargument name="cachename" type="string" required="false" default="" />
		<cfset var qry = "" />
		<cfif len(trim(arguments.cachename))>
			<cfset qry = getCacheData() />
			<cfquery name="qry" dbtype="query">
				select #allColumns()# from qry 
				where cachename like <cfqueryparam value="#arguments.cachename#" cfsqltype="cf_sql_varchar" />
			</cfquery>
			<cfdump var="#qry#" />
		<cfelse>
			<cfdump var="#getCacheData()#" />
		</cfif>
	</cffunction>
	
	<cffunction name="selectRecord" access="private" output="false" returntype="query">
		<cfargument name="cachename" type="string" required="true" />
		<cfset var cache = getCacheData() />
		<cfset var result = QueryNew(cache.columnlist) />
		<cfset var c = 0 />
		<cfset var i = 0 />
		
		<cfif structKeyExists(instance.map,cachename)>
			<!--- 
				this allows us to speed up fetch operations as the query grows - 
				with a large query, manually copying the data for the row 
				(identified by the map) into a manually created new query will 
				be faster than executing a query-of-query selection of the row 
				because the server only needs to index the arrays in the query 
				by number, instead of performing more expensive string-comparisons 
				on each row of the query 
			 --->
			<cfset i = instance.map[cachename] />
			<cfset QueryAddRow(result,1) />
			<cfloop index="c" list="#result.columnlist#">
				<cfset result[c][1] = cache[c][i] />
			</cfloop>
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getStorageType" access="private" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfreturn instance.typeManager.getStorageType(type) />
	</cffunction>
	
	<cffunction name="fetchFromCluster" access="private" output="false">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="storagetype" type="string" required="true" />
		<cfset var x = 0 />
		<cfset var qry = 0 />
		<cfset var result = structNew() />
		<cfset result.status = 1 />
		<cfset result.content = "" />
		
		<cfif left(cachename,3) is "clu">
			<!--- we didn't find the content in local storage, 
			but it's stored for the cluster, so we'll go look for it before we declare a miss --->
			<cfset result = getStorageType(arguments.storageType).fetch(arguments.cachename,"") />
			
			<cfif not result.status>
				<!--- we found content in the cluster storage, lets record stats locally --->
				<cflock name="#getLock()#" type="exclusive" timeout="10">
					<!--- we need to lock and check again to prevent a race condition 
					that might insert two local stat counters for this content --->
					<cfset qry = selectRecord(arguments.cachename) />
					<cfif val(qry.timeStored) neq 0>
						<!--- this is the race condition - another request got here first, so all we need to do is update the hit count --->
						<cfset x = qry.index />
						<cfset qry = getCacheData() />
					<cfelse>
						<!--- okay, we're the first ones here, so we need to grow the cache query and set the storage type and time --->
						<cfset qry = getCacheData() />
						<cfset x = growCache(qry,arguments.cachename) />
						<cfset qry.timeStored[x] = getMinutes() />
						<cfset qry.storageType[x] = arguments.storageType />
					</cfif>
					<cfset qry.timeHit[x] = getMinutes() />
					<cfset qry.hitcount[x] = qry.hitcount[x] + 1 />
				</cflock>
			</cfif>
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="struct">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="storagetype" type="string" required="true" />
		<cfset var qry = 0 />
		<cfset var result = 0 />
		<cfset var x = 0 />
		
		<cflock name="#getLock()#" type="readonly" timeout="10">
			<cfset qry = selectRecord(arguments.cachename) />
		</cflock>
		
		<cfif val(qry.expired) eq 0 and val(qry.timeStored) neq 0>
			<!--- content found -- 
			alternative storage types may need to customize the content column for their own purposes, 
			so we need to now go back to the custom storage type to fetch the actual content --->
			<cfset result = getStorageType(qry.storageType).fetch(qry.cachename,qry.content) />
			<cfif result.status neq 0>
				<!--- status 1 indicates the content is not cached 
				- this may be a result of either failure or programatic expiration of the content as indicated by the individual storage type --->
				<cfset recordMiss(cacheName,qry.index) />
			<cfelse>
				<!--- the stored record is valid content --->
				<cfset recordHit(cacheName,qry.index) />
			</cfif>
		<cfelse>
			<!--- if this content belongs to the cluster, it may already be there, check first --->
			<cfset result = fetchFromCluster(arguments.cachename,arguments.storagetype) />
			<cfif not result.status>
				<!--- we found content on the cluster, so we don't need to record the miss --->
				<cfreturn result />
			</cfif>
			
			<!--- either the record is not stored or the stored record is a placeholder for miss-counts --->
			<cfset recordMiss(arguments.cacheName,val(qry.index)) />
			<!--- return the expected structure with a status of 1 indicating that the content is not cached --->
			<cfset result = structNew() />
			<cfset result.status = 1 />
			<cfset result.content = "" />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="recordHit" access="private" output="false" hint="updates the hit count for a specified entry">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="index" type="numeric" required="true" />
		<cfset var qry = 0 />
		
		<!--- 
			we need this lock because the cache query is replaced during a reap operation 
			and if that happens during an attempt to record a hit then we might either 
			get bad hit data or we might throw errors trying to set values for a record that no longer exists 
		--->
		<cflock name="#getLock()#" type="exclusive" timeout="10">
			<cfset qry = getCacheData() />
			<cfif qry.cachename[index] is arguments.cachename>
				<cfset qry.hitCount[index] = qry.hitCount[index] + 1 />
				<cfset qry.timeHit[index] = getMinutes() />
			</cfif>
		</cflock>
	</cffunction>
	
	<cffunction name="recordMiss" access="private" output="false" hint="updates the miss count for a specified entry">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="index" type="numeric" required="true" />
		<cfset var qry = 0 />
		<cfset var cxt = 0 />
		<cfset var x = 0 />
		
		<!--- 
			we need this lock because the cache query is replaced during a reap operation 
			and if that happens during an attempt to record a miss then we might either 
			get bad miss data or we might throw errors trying to set values for a record that no longer exists 
		--->
		<cflock name="#getLock()#" type="exclusive" timeout="10">
			<cfset qry = getCacheData() />
			<cfif index gt 0 and qry.cachename[index] is arguments.cachename>
				<!--- previous misses have already been recorded for this cache --->
				<cfset qry.missCount[index] = qry.missCount[index] + 1 />
				<cfset qry.timeHit[index] = getMinutes() />
				<cfset qry.expired[index] = 0 />
			<cfelse>
				<cfset x = growCache(qry,cachename) />
				<cfset qry.missCount[x] = 1 />
				<cfset qry.timeHit[x] = getMinutes() />
			</cfif>
		</cflock>
	</cffunction>
	
	<cffunction name="getCacheContext" access="private" output="false" returntype="struct">
		<cfargument name="cachename" type="string" required="true" />
		<cfset var result = structNew() />
		<cfset result.context = listfirst(cachename,"|") />
		<cfset result.appName = iif(result.context is "app","listgetat(cachename,2,'|')",de("")) />
		<cfset result.agentName = listgetat(cachename,iif(result.context is "clu",2,3),"|") />
		<cfreturn result />
	</cffunction>
	
	<cffunction name="growCache" access="private" output="false" returntype="numeric"
	hint="I add a record to the cache query -- I need to be exclusively locked">
		<cfargument name="qry" type="query" required="true" />
		<cfargument name="cachename" type="string" required="true" />
		<cfset var x = 0 />
		
		<cfset QueryAddRow(qry,1) />
		<cfset x = qry.recordcount />
		<cfset qry.cacheName[x] = cacheName />
		<!--- the map needs to know where this record is if we're not going to use a query of query as a back-up --->
		<cfset instance.map[cachename] = x />
		<cfset qry.index[x] = x />
		<cfset qry.hitCount[x] = 0 />
		<cfset qry.missCount[x] = 0 />
		<cfset qry.timeHit[x] = getMinutes() />
		<cfset qry.expired[x] = 0 />
		
		<!--- context information is used for statistical reporting of data by applicatication, etc. --->
		<cfset cxt = getCacheContext(cachename) />
		<cfset qry.context[x] = lcase(cxt.context) />
		<cfset qry.appName[x] = lcase(cxt.appName) />
		<cfset qry.agentName[x] = lcase(cxt.agentName) />
		
		<cfreturn x />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="struct">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfargument name="storageType" type="string" required="true" />
		<cfset var record = 0 />
		<cfset var result = 0 />
		<cfset var qry = 0 />
		<cfset var x = 0 />
		<cfset var cxt = 0 />
		
		<cflock name="#getLock()#" type="exclusive" timeout="10">
			<cfset qry = getCacheData() />
			<cfset record = selectRecord(cacheName) />
			
			<cfif val(record.expired) eq 0 and val(record.timestored) neq 0 and isObject(arguments.content)>
				<!--- if the content is a fragment (simple value), then it doesn't matter if it gets stored more than once 
				because it's passed by value not by reference and may be stored over itself deliberately - however - 
				complex data such as objects need to be checked for dups to allow the cache to be used for singleton creation 
				--->
				
				<!--- use the specified storage type to determine if the content is indeed retained and valid --->
				<cfset result = getStorageType(record.storageType).fetch(record.cachename,record.content) />
				<cfif result.status eq 0 and isObject(result.content)>
					<!--- we hit the dogpile! (race condition) multiple simultaneous requests created and attempted to cache the content for this record --->
					<cfset recordHit(cachename,record.index) />
					
					<!--- status 2 indicates the dogpile condition in which case the storing code may need to reassign the result content --->
					<cfset result.status = 2 />
					
					<cfreturn result />
				</cfif>
				
				<!--- it was cached but is no longer valid (an expired soft reference for example) so we can continue with storage --->
			</cfif>
			
			<cfif record.recordcount>
				<!--- there was a miss prior to storing this record (or it expired), so we already have an index for it --->
				<cfset x = record.index />
			<cfelse>
				<!--- this is the first we've heard of this record, grow the query to accommodate it --->
				<cfset x = growCache(qry,cacheName) />
			</cfif>
			
			<!--- store all the management values we need for this record --->
			<cfset qry.storageType[x] = lcase(storageType) />
			
			<!--- don't update the storage time for overwrites because we need to know hit frequency by dividing hit count by time --->
			<cfset expired[x] = 0 />
			<cfif val(qry.timeStored[x]) eq 0>
				<!--- we're overwriting a miss-counter, so we set the storage time here --->
				<cfset qry.timeStored[x] = getMinutes() />
			</cfif>
			
			<!--- allow the custom storage type to modify the content column for its own purposes --->
			<cfset qry.content[x] = getStorageType(arguments.storageType).store(arguments.cachename,arguments.content) />
			
			<!--- okay, we're done adding the content, now we need to return it just like we did for the dogpile --->
			<cfset recordHit(cachename,x) />
			<cfset result = structNew() />
			<cfset result.status = 0 />
			<cfset result.content = arguments.content />
			
			<cfreturn result />
		</cflock>
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" 
	hint="removes one or more records from the query - a wild card character (%) at the end of the name will delete multiple related entries">
		<cfargument name="cachename" type="string" required="true" />
		<cfset var cache = getCacheData() />
		<cfset var old = 0 />
		
		<!--- find the old records --->
		<cfquery name="old" dbtype="query" debug="false">
			select #allColumns()# from cache 
			where cachename like <cfqueryparam value="#arguments.cachename#" cfsqltype="cf_sql_varchar" />
		</cfquery>
				
		<cfset reap(old) />
	</cffunction>
	
	<cffunction name="expire" access="public" output="false" 
	hint="I mark content for later removal without immediately removing the content">
		<cfargument name="cachename" type="string" required="true" />
		<cfset var cache = getCacheData() />
		<cfset var old = 0 />
		
		<cflock name="#getLock()#" type="exclusive" timeout="10">
			<!--- find the records to expire --->
			<cfquery name="old" dbtype="query" debug="false">
				select index from cache 
				where cachename like <cfqueryparam value="#arguments.cachename#" cfsqltype="cf_sql_varchar" />
			</cfquery>
			
			<!--- this is probably faster and definitely easier than a union query and replacement --->
			<cfloop query="old">
				<cfset cache.expired[old.index] = 1 />
			</cfloop>
		</cflock>
	</cffunction>
	
	<cffunction name="reap" access="public" output="false" 
	hint="removes all the records indicated by a purge operation">
		<cfargument name="old" type="query" required="true" />
		<cfset var cache = getCacheData() />
		<cfset var qry = 0 />
		
		<cfif old.recordcount>
			<!--- only remove records that were in the old query 
			- this queryparam uses the ascii beep code to delimit the list to ensure that it won't conflict with anything in the cachenames --->
			<cflock name="#getLock()#" type="exclusive" timeout="10">
				<cfquery name="qry" dbtype="query" debug="false">
					select #allColumns()# from cache 
					where cachename not in 
						(<cfqueryparam value="#valuelist(old.cachename,chr(7))#" 
							cfsqltype="cf_sql_varchar" list="true" separator="#chr(7)#" />)
				</cfquery>
				
				<cfset setIndex(qry) />
			</cflock>
			
			<!--- perform any cleanup that might be needed on the old records - cleanup is specific to storage-types --->
			<cfset cleanUp(old) />
		</cfif>
	</cffunction>
	
	<cffunction name="cleanUp" access="private" output="false">
		<cfargument name="deleted" type="query" required="true" />
		<!--- this will be a lot faster than requesting the type from the config each time and we already know these types are loaded --->
		<cfset var st = instance.typeManager.getAllTypes() />
		
		<cfset announceReap(deleted) />
		
		<cfloop query="deleted">
			<!--- misses are stored in the cache query with no storage type (no content), 
			so we have to check here to see if there actually is content to clean up or 
			if we're just purging a miss-counter on an agent or application reset --->
			<cfif len(trim(storageType))>
				<cfset st[storageType].delete(cacheName,content) />
			</cfif>
		</cfloop>
	</cffunction>
	
	<cffunction name="announceReap" access="private" output="false">
		<cfargument name="deleted" type="query" required="true" />
		<!--- this will be a lot faster than requesting the type from the config each time and we already know these types are loaded --->
		<cfset var st = instance.typeManager.getAllTypes() />
		<cfset var mgr = getAgentManager() />
		<cfset var my = structNew() />
		<cfset var temp = "" />
		
		<cfquery name="temp" dbtype="query" debug="false">
			select #allColumns()# from deleted 
			where hitcount is not null and hitcount > 0 
			order by context, appName, agentName 
		</cfquery>
		
		<cfoutput query="temp" group="context">
			<cfoutput group="appName">
				<cfoutput group="agentName">
					<cfset my.agent = mgr.getAgent(mgr.getAgentID(context,appName,agentName)) />
					<cfif structKeyExists(my.agent,"hasReapListener") and my.agent.hasReapListener()>
						<cfoutput>
							<cfset my.agent.announceReap(listlast(cachename,"|"),st[storageType].fetch(cachename,content).content) />
						</cfoutput>
					</cfif>
				</cfoutput>
			</cfoutput>
		</cfoutput>
		
	</cffunction>
	
	<cffunction name="select" access="public" output="false" returntype="query" hint="returns a sub-selection of the cache query for reporting and analysis">
		<cfargument name="cachename" type="string" required="true" hint="a cache name string ending with a wild card (%) character" />
		<cfargument name="stored" type="boolean" required="false" default="true" hint="includes expired content and placeholders for miss-counts if this argument is false" />
		<cfset var cache = getCacheData() />
		<cfset var result = 0 />
		
		<cfquery name="result" dbtype="query" debug="false">
			select #allColumns()# from cache 
			where cachename like <cfqueryparam value="#arguments.cachename#" cfsqltype="cf_sql_varchar" />
			<cfif arguments.stored>
				and expired = 0 
				and timeStored is not null 
				and timeStored > 0 
			</cfif>
		</cfquery>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>