<!--- 
	== CacheBox is Free Software == 
	 
	 * Copyright (c) 2008 
	 * AutLabs and S. Isaac Dealey.  All rights reserved.
	 * 
	 * Redistribution and use in source and binary forms, with or without
	 * modification, are permitted provided that the following conditions
	 * are met:
	 * 1. Redistributions of source code must retain the above copyright
	 *    notice, this list of conditions and the following disclaimer.
	 * 2. Redistributions in binary form must reproduce the above copyright
	 *    notice, this list of conditions and the following disclaimer in the
	 *    documentation and/or other materials provided with the distribution.
	 * 3. All advertising materials mentioning features or use of this software
	 *    must display the following acknowledgment:
	 *	This product includes software developed by AutLabs and S. Isaac Dealey.
	 * 4. Neither the name of the AutLabs, S. Isaac Dealey or other contributors 
	 *    may be used to endorse or promote products derived from this software
	 *    without specific prior written permission.
	 * 
	 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
	 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
	 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
	 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
	 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
	 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
	 * SUCH DAMAGE. 
--->

<cfcomponent displayname="CacheBoxAgent" output="false" 
hint="I provide a means of caching arbitrary objects and data via a facade to a back-end service for central cache management and hands-free, automated cache optimization - I also fail-over to an internal caching mechanism if the service is unavailable, to make me portable">
	<cfset instance = structNew() />
	<cfset instance.created = now() />
	<cfset instance.agentName = CreateUUID() />
	<cfset instance.reapListener = 0 />
	<cfset instance.lockName = "" />
	<cfset this.agentid = "" />
	<cfset instance.version = "1.4" />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="AgentName" type="string" required="true" 
			hint="uniquely identifies this cache agent for analysis and configuration" />
		<cfargument name="Context" type="string" required="false" default="application" 
			hint="application, server or cluster - indicates the context in which the created cache is relevant" />
		<cfargument name="Evict" type="string" required="false" default="auto" 
			hint="none, auto, fresh, perf, idle:x, age:x, LRU:x, LFU:x or FIFO:x - indicates if objects in this cache are allowed to expire and optionally the priority of expiration" />
		<cfargument name="ReapListener" type="any" required="false" default="" 
			hint="allows the agent to provide a callback to the application when content is removed from cache" />
		<cfargument name="CacheService" type="any" required="false" default="" 
			hint="allows the caching service to be managed by an IoC framework or for it to be stubbed for testing purposes" />
		<cfargument name="ApplicationName" type="string" required="false" default="#application.applicationName#" 
			hint="indicates the application to which this cache belongs - ignored for agents in the cluster or server context" />
		
		<!---
			=== Eviction Policies === 
			NONE   = content never expires - necessary for certain things like singletons that might be stored in an IoC framework and then used as properties of other objects 
			AUTO   = automatically determines the eviction policy based on the usage patterns and available resources 
			FRESH  = automatically determines the eviction policy with a priority on freshness of content - likely to use an age-based eviction policy 
			PERF   = automatically determines the eviction policy with a priority on speed of delivery - likely to use an idle-based eviction policy 
			AGE:X  = allows the cache to live for a maximum of x minutes, i.e. AGE:60 = 1 hour or AGE:480 = 8 hours or AGE:1440 = 1 day 
			IDLE:X = allows the cache to live indefinitely until it remains idle for x minutes 
			FIFO:X = allows the cache to grow to x number of entries, then evicts oldest first 
			LRU:X  = allows the cache to grow to x number of entries, then evicts least-recently used first 
			LFU:X  = allows the cache to grow to x number of entries, then evicts least-frequently used first 
			
			NOTE: ** eviction policy is ignored if the caching service is not available ** 
		--->
		<cfset structAppend(instance,arguments,true) />
		<cfset setLockName() />
		<cfset setDefaultService() />
		<cfset registerAgent() />
		<cfset reset() />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="setLockName" access="private" output="false">
		<cfset var cxt = getContext() />
		<cfset var n = "" />
		
		<cfswitch expression="#cxt#">
			<cfcase value="server"><cfset n = "svr|" /></cfcase>
			<cfcase value="cluster"><cfset n = "clu|" /></cfcase>
			<cfcase value="application">
				<cfset n = "app|" & lcase(getAppName()) />
			</cfcase>
		</cfswitch>
		
		<cfset instance.lockName = n & lcase(getAgentName()) />
	</cffunction>
	
	<cffunction name="reset" access="public" output="false">
		<cfset var svc = getService() />
		<cfif isObject(svc)>
			<cfset svc.resetAgent(this) />
		<cfelse>
			<cfset instance.map = StructNew() />
			<cfset instance.cache = QueryNew("cachename,content") />
		</cfif>
	</cffunction>
	
	<cffunction name="setDefaultService" access="private" output="false">
		<cfif not isObject(getService())>
			<cftry>
				<cfif FileExists(ExpandPath("/cachebox/cacheboxservice.cfc"))>
					<cfset instance.cacheService = CreateObject("component","cachebox.cacheboxservice").init() />
				</cfif>
				<cfcatch></cfcatch>
			</cftry>
		</cfif>
	</cffunction>
	
	<cffunction name="registerAgent" access="private" output="false">
		<cfset var svc = getService() />
		<cfif isObject(svc)>
			<cfset setAgentID(svc.registerAgent(this)) />
		</cfif>
	</cffunction>
	
	<cffunction name="setAgentID" access="private" output="false">
		<cfargument name="agentID" type="string" required="true" />
		<cfset this.agentID = arguments.agentID />
	</cffunction>
	
	<cffunction name="getAgentID" access="public" output="false" returntype="string">
		<cfreturn this.agentID />
	</cffunction>
	
	<cffunction name="isRegistered" access="public" output="false">
		<cfreturn YesNoFormat(len(getAgentID())) />
	</cffunction>
	
	<cffunction name="getService" access="public" output="false" hint="returns the cache service associated with this agent - not guaranteed to be an object">
		<cfreturn instance.cacheservice />
	</cffunction>
	
	<cffunction name="isConnected" access="public" output="false" hint="indicates if this agent is associated with a service object">
		<cfreturn isObject(getService()) />
	</cffunction>
	
	<cffunction name="getAgentName" access="public" output="false" hint="returns the name that identifies this agent - agents for server or cluster scopes must share the same name in order to share the same cache">
		<cfreturn instance.agentName />
	</cffunction>
	
	<cffunction name="getContext" access="public" output="false" hint="returns the context to which this agent should apply">
		<cfreturn instance.context />
	</cffunction>
	
	<cffunction name="getVersion" access="public" output="false" hint="returns the version of the agent - allows the service to distinguish between newer and older agent versions">
		<cfreturn instance.version />
	</cffunction>
	
	<cffunction name="getAppliedContext" access="public" output="false" 
	hint="returns the actual context to which this agent currently applies - applied context may not be the same as context, for example if the desired context is cluster or server but no service is available, an application context is used">
		<cfset var svc = getService() />
		<cfif isObject(svc)>
			<cfreturn lcase(svc.getAppliedContext(this)) />
		<cfelse>
			<cfreturn "application" />
		</cfif>
	</cffunction>
	
	<cffunction name="getAppName" access="public" output="false" returntype="string">
		<cfreturn instance.applicationName />
	</cffunction>
	
	<cffunction name="getEvictPolicy" access="public" output="false" returntype="string">
		<cfreturn instance.evict />
	</cffunction>
	
	<cffunction name="getAppliedEvictPolicy" access="public" output="false" 
	hint="returns the actual eviction policy for this agent - applied eviction policy is often different due to auto-assignment of eviction policies or when the service is unavailable">
		<cfset var svc = getService() />
		<cfif isObject(svc)>
			<cfreturn lcase(svc.getEvictPolicy(this)) />
		<cfelse>
			<cfreturn "none" />
		</cfif>
	</cffunction>
	
	<cffunction name="debug" access="public" output="true">
		<cfdump var="#variables.instance#" />
	</cffunction>
	
	<cffunction name="getLock" access="private" output="false" returntype="string">
		<cfargument name="cachename" type="string" required="false" default="" />
		<cfreturn instance.lockName & "|" & lcase(cachename) />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="struct">
		<cfargument name="cachename" type="string" required="true" />
		<cfset var result = 0 />
		<cfset var svc = getService() />
		<cfset var qry = 0 />
		
		<cfset cachename = lcase(cachename) />
		
		<!--- the read only lock ensures that we're not reading simultaneous to a set of the same item --->
		<cflock name="#getLock(cachename)#" type="readonly" timeout="10">
			<cfif isObject(svc)>
				<cfreturn svc.fetch(this,cachename) />
			<cfelse>
				<cfset result = structNew() />
				
				<cfif structKeyExists(instance.map,cachename)>
					<!--- status 0 indicates that the content is cached --->
					<cfset result.status = 0 />
					<cfset result.content = instance.cache.content[instance.map[cachename]] />
				<cfelse>
					<!--- status 1 indicates that the content is not cached --->
					<cfset result.status = 1 />
					<cfset result.content = "" />
				</cfif>
			</cfif>
		</cflock>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="struct" hint="places content in the cache">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var svc = getService() />
		<cfset var result = 0 />
		<cfset var qry = 0 />
		<cfset cachename = lcase(cachename) />
		
		<!--- 
			in some instances in order to handle race conditions 
			it may be necessary for the store method to return 
			an object other than the one being stored. Results 
			are returned as a structure with status and content 
			variables. The simplest syntax to use this method is: 
				<cfset content = agent.store(cachename,content).content />
		--->
		
		<cfif findOneOf("|%",cachename)>
			<cfthrow type="CacheBox.InvalidCacheName" 
				message="CacheBox: Invalid Cache Name (#cachename#)" 
				detail="Cache names may not contain | or % characters." />
		</cfif>
		
		<!--- an exclusive lock of the individual item ensures that only one request can set it at a time 
		and that there are no simultaneous fetch operations occuring at the time of setting --->
		<cflock name="#getLock(cachename)#" type="exclusive" timeout="10">
			<cfif isObject(svc)>
				<cfreturn svc.store(this,cachename,content) />
			<cfelse>
				<cfif structKeyExists(instance.map,cachename)>
					<cfset result = structNew() />
					<cfset result.content = instance.cache.content[instance.map[cachename]] />
					<cfif isObject(arguments.content) and isObject(result.content)>
						<!--- status 2 indicates the content was already cached --->
						<cfset result.status = 2 />
					<cfelse>
						<cfset result.status = 0 />
						<cfset result.content = arguments.content />
						<cfset instance.cache.content[instance.map[cachename]] = result.content />
					</cfif>
					<cfreturn result />
				</cfif>
				<!--- okay we dealt with the race condition of simultaneous requests using the above fetch, 
				the lock below deals with the race condition of simultaneous deletes by locking the entire agent --->
				<cflock name="#getLock()#" type="exclusive" timeout="10">
					<cfset instance.map[cachename] = insertRecord(cachename,content) />
				</cflock>
			</cfif>
		</cflock>
		
		<cfset result = structNew() />
		<cfset result.status = 0 />
		<cfset result.content = arguments.content />
		<cfreturn result />
	</cffunction>
	
	<cffunction name="insertRecord" access="private" output="false" returntype="numeric" hint="adds an item to the cache query - must be locked to prevent race conditions">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var x = instance.cache.recordcount + 1 />
		<cfset QueryAddRow(instance.cache) />
		<cfset instance.cache.cachename[x] = "x-" & arguments.cachename />
		<cfset instance.cache.content[x] = arguments.content />
		<cfreturn x />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" hint="removes one or more records from the agent's cache - a wild-card (%) at the end of the cache name can be used to remove multiple related records">
		<cfargument name="cachename" type="string" required="true" />
		<cfset var svc = getService() />
		<cfset var old = "" />
		<cfset var newcache = "" />
		<cfset var map = 0 />
		<cfset cachename = lcase(cachename) />
		
		<cflock name="#getLock()#" type="exclusive" timeout="10">
			<cfif isObject(svc)>
				<cfset svc.delete(this,cachename) />
			<cfelse>
				<!--- 
					using the like operator in this query allows us to pass in a value 
					with a wild card character (%) at the end of the cache name 
					if we want to remove multiple related entries from the cache 
				--->
				<cfquery name="old" dbtype="query" debug="false">
					select * from instance.cache 
					where cachename like <cfqueryparam value="x-#cachename#" cfsqltype="cf_sql_varchar" />
				</cfquery>
				
				<cfif old.recordcount>
					<!--- we only need to process deletion if we found any items to delete --->
					<cfif this.hasReapListener()>
						<!--- let the application know what we're removing --->
						<cfloop query="old">
							<!--- we need to remove the initial x- used to prevent interpretation of the cachename column as numeric --->
							<cfset AnnounceReap(removechars(old.cachename,1,2),old.content) />
						</cfloop>
					</cfif>
					
					<!--- get a query containing only the items we're keeping --->
					<cfquery name="newcache" dbtype="query" debug="false">
						select * from instance.cache 
						where cachename not like <cfqueryparam value="x-#cachename#" cfsqltype="cf_sql_varchar" />
					</cfquery>
					
					<!--- since we're removing some items from the query, the map will be inaccurate, so we have to recreate the map --->
					<cfset map = structNew() />
					<cfloop query="newcache">
						<cfset map[newcache.cachename] = currentrow />
					</cfloop>
					
					<cfset instance.cache = newcache />
					<cfset instance.map = map />
				</cfif>
			</cfif>
		</cflock>
	</cffunction>
	
	<cffunction name="expire" access="public" output="false" 
	hint="Marks one or more items in the cache as expired without immediately removing them">
		<cfargument name="cachename" type="string" required="false" default="%" />
		<cfset var svc = getService() />
		<cfset cachename = lcase(cachename) />
		
		<cfif isObject(svc)>
			<cfset svc.expire(this,cachename) />
		<cfelse>
			<!--- if the service isn't available, then there is no deferred removal --->
			<cfset delete(cachename) />
		</cfif>
	</cffunction>
	
	<cffunction name="getSize" access="public" output="false">
		<cfset var svc = getService() />
		<cfif isObject(svc)>
			<cfreturn svc.getAgentSize(this) />
		<cfelse>
			<cfreturn instance.cache.recordcount />
		</cfif>
	</cffunction>
	
	<cffunction name="hasReapListener" access="public" output="false" returntype="boolean">
		<cfreturn isObject(instance.ReapListener) />
	</cffunction>
	
	<cffunction name="AnnounceReap" access="public" output="false">
		<cfargument name="cacheName" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset instance.ReapListener.ReapCache(cacheName,content) />
	</cffunction>
	
</cfcomponent>
