<cfcomponent output="false" extends="frontcontrollerutilities" displayname="CacheBox.FrontController" 
hint="I am the management application for manually viewing or modifying cache configuration">
	
	<cffunction name="home" access="public" output="true">
		<cfset var history = getHistory() />
		<cfset var data = getCacheQuery() />
		
		<!--- get the total number of hits and misses from raw data --->
		<cfquery name="data" dbtype="query" debug="false">
			select sum(hitCount) as hitCount, sum(missCount) as missCount from data 
		</cfquery>
				
		<cfoutput>
			<div id="home">
				<table border="0" cellpadding="2" cellspacing="0">
					<tr><td>Cache Size:</td><td>#lsNumberFormat(request.service.getOccupancy())#</td></tr>
					<tr><td>Free Memory:</td><td>#history.getPercentFreeMemory()#%</td></tr>
				</table>
				
				#showFailureWarning()#
				
				<div class="chart">
					<div class="title">History</div>
					#showHistoryGraph()#
				</div>
				<div class="chart">
					<div class="title">Hit Ratio</div>
					#showHitChart(val(data.hitCount),val(data.missCount))#
				</div>
			</div>
		</cfoutput>
	</cffunction>
	
	<cffunction name="showFailureWarning" access="private" output="false" returntype="string">
		<cfset var minutes = getConfig().getWarningMinutes() />
		<cfif minutes neq 0>
			<cfreturn "<div class=""warning statusmessage"">Possible memory failure in #minutes# minutes.</div>" />
		</cfif>
	</cffunction>
	
	<cffunction name="showHistoryGraph" access="private" output="false">
		<cfset var history = getHistory().getLog() />
		<cfset var result = "" />
		
		<cfquery name="history" dbtype="query" debug="false">
			select [time], occupancy, cast(freememory / 1000 as INTEGER) as freememory from history 
		</cfquery>
		
		<cfsavecontent variable="result">
			<cfchart format="jpg" xaxistitle="Available Memory (MB)">
				<cfchartseries type="line">
					<cfloop query="history">
						<cfif currentrow is 1 or currentrow is recordcount>
							<cfchartdata item="#lsTimeFormat(history.time,'short')#" value="#history.freememory#" />
						<cfelse>
							<cfchartdata value="#history.freememory#" />
						</cfif>
					</cfloop>
				</cfchartseries>
			</cfchart>
			<cfchart format="jpg" xaxistitle="Cached Objects">
				<cfchartseries type="line">
					<cfloop query="history">
						<cfif currentrow is 1 or currentrow is recordcount>
							<cfchartdata item="#lsTimeFormat(history.time,'short')#" value="#history.occupancy#" />
						<cfelse>
							<cfchartdata value="#history.occupancy#" />
						</cfif>
					</cfloop>
				</cfchartseries>
			</cfchart>
		</cfsavecontent>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="agent_list_optimized" access="public" output="true">
		<cfset confirm("Agents have been optimized.") />
		<cfinvoke method="agent_list" />
	</cffunction>
	
	<cffunction name="agent_list" access="public" output="true">
		<cfargument name="agentid" type="string" required="false" default="" />
		<cfset var mgr = getAgentManager() />
		<cfset var qry = getAgentStats() />
		<cfset var config = 0 />
		<cfset var aid = "" />
		
		<cfif len(arguments.agentid)>
			<cfset config = mgr.getAgentConfig(arguments.agentid) />
			<cfset confirm("The agent #htmleditformat(config.agent.getAgentName())# is reset.") />
		</cfif>
		
		<h3 id="BreadCrumbs"><a>Agent List</a></h3>
		
		<cfif not qry.recordcount>
			<div class="empty statusmessage">No Agents Registered.</div>
		</cfif>
		
		<cfoutput query="qry" group="context">
			<h4>#lcase(context)#</h4>
			<table class="list" cellpadding="2" cellspacing="0">
				<thead>
					<th>Agent</th>
					<th>Count</th>
					<th>Hits</th>
					<th>Oldest</th>
					<th>Last Hit</th>
					<th>Storage</th>
					<th>Eviction</th>
				</thead>
				<tbody>
					<cfoutput group="appname">
						<cfif qry.context is "application">
							<tr class="appname">
								<th colspan="7" title="#htmleditformat(appname)#">
									#htmleditformat(rereplace(lcase(appname),"_+"," ","ALL"))#
									<div><a name="#htmleditformat(appname)#">&nbsp;</a></div>
								</th>
							</tr>
						</cfif>
						<cfoutput group="agentname">
							<cfset config = mgr.getAgentConfig(mgr.getAgentID(context,appname,agentname)) />
							<cfset aid = urlencodedformat(listchangedelims(qry.agentid, "|", "|")) />
							<tr>
								<td>
									<a href="?event=agent_reset&amp;agentid=#aid#" class="icon reset" title="Reset"></a>
									<a href="?event=agent_browse&amp;agentid=#aid#" class="icon detail" title="Browse Content"></a>
									<a href="?event=agent_detail&amp;agentid=#aid#" title="Agent Details">#htmleditformat(agentname)#</a>
								</td>
								<td class="numeric">#int(occupancy)#</td>
								<td class="numeric">
									<cfif numHits or numMiss>
										#int(100 * (numHits / (numHits + numMiss)))#%
									</cfif>
								</td>
								<td><cfif val(oldest)>#formatAge(oldest)#</cfif></td>
								<td>#formatAge(lastHit)#</td>
								<td>#config.storageType#</td>
								<td>
									<cfset temp = config.agent.getEvictPolicy() />
									<cfif listfindnocase("auto,fresh,perf",temp)>#lcase(temp)#:</cfif>
									#lcase(config.evictPolicy)# <cfif val(config.evictAfter) gt 0>(#config.evictAfter#)</cfif>
								</td>
							</tr>
						</cfoutput>
					</cfoutput>
				</tbody>
			</table>
		</cfoutput>
	</cffunction>
	
	<cffunction name="applist" access="public" output="true">
		<cfargument name="appname" type="string" required="false" default="" />
		<cfset var qry = getAppStats() />
		<cfset var history = getHistory() />
		
		<cfoutput>
			<cfset confirm("The application #arguments.appname# is reset.",len(trim(arguments.appname)))>
			
			<table class="list" cellpadding="2" cellspacing="0">
				<thead>
					<th>Application</th>
					<th>Occupancy</th>
					<th>Oldest</th>
					<th>Last Hit</th>
				</thead>
				<tbody>
					<cfif not qry.recordcount>
						<tr>
							<td colspan="4">
								<div class="empty statusmessage">No Application Content In Cache.</div>
							</td>
						</tr>
					<cfelse>
						<cfloop query="qry">
							<tr>
								<td>
									<a href="?event=appReset&amp;appname=#urlencodedformat(qry.appname)#" class="icon reset" title="Reset"></a>
									<a href="?event=agent_list###htmleditformat(qry.appname)#" title="Browse Agents">#htmleditformat(qry.appname)#</a>
								</td>
								<td>#int(occupancy)#</td>
								<td>#formatTime(history.getTime(oldest))#</td>
								<td>#formatAge(lastHit)#</td>
							</tr>
						</cfloop>
					</cfif>
				</tbody>
			</table>
		</cfoutput>
	</cffunction>
	
	<cffunction name="appReset" access="public" output="false">
		<cfargument name="appName" type="string" required="true" />
		<cfsetting requesttimeout="900" />
		<cfset request.service.resetApplication(appName) />
		<cflocation url="?event=applist&appname=#urlencodedformat(appName)#" addtoken="false" />
	</cffunction>
	
	<cffunction name="agent_detail" access="public" output="true">
		<cfargument name="agentid" type="string" required="true" />
		<cfargument name="saved" type="boolean" required="false" default="false" />
		<cfset var mgr = getAgentManager() />
		<cfset var config = mgr.getAgentConfig(arguments.agentid) />
		<cfset var hitdata = getAgentHits(agentid) />
		<cfset var temp = 0 />
		<cfset var perm = mgr.getAgentSettingsXML(arguments.agentid) />
		<cfset var rec = getConfig().getAgentRecommendations(agentid) />
		<cfset var x = 0 />
		
		<cfparam name="perm.storagetype" type="string" default="" />
		<cfparam name="perm.evictpolicy" type="string" default="" />
		<cfparam name="perm.evictafter" type="string" default="" />
		
		<cfset request.pageevents.onload &= "setEvictPolicy('#config.evictpolicy#:#config.evictafter#');" />
		
		<cfoutput>
			<cfset confirm("Agent Settings Updated", arguments.saved) />
			
			<h3 id="BreadCrumbs">
				<a href="?event=agent_list">Agent List</a> 
				<a>#formatAgentName(config.agent)#</a> 
			</h3>
			
			<form action="?" method="post" name="frmAgentConfig">
				<input type="hidden" name="event" value="agentupdate" />
				<input type="hidden" name="agentid" value="#htmleditformat(arguments.agentid)#" />
				
				<table cellpadding="3" cellspacing="0">
					<tbody>
						<tr>
							<td>Context:</td>
							<td>
								#config.context#
								<cfif config.context is "application">
									(#htmleditformat(config.agent.getAppName())#) 
								</cfif>
							</td>
						</tr>
						<cfif config.context is not config.agent.getContext()>
							<tr>
								<td>Requested Context:</td>
								<td>#htmleditformat(config.agent.getContext())#</td>
							</tr>
						</cfif>
						<tr>
							<td>Storage Type:</td>
							<td>
								#selectStorageType(context=config.context, selected=config.storageType)#
								<div>#permanent("storage", perm.storagetype is config.storageType)#</div>
							</td>
						</tr>
						<tr>
							<td>Eviction Policy:</td>
							<td>
								<cfset temp = config.agent.getEvictPolicy()>
								<cfif listfindnocase("auto,fresh,perf", temp)><div style="float:left; margin-right:5px;">#ucase(temp)#</div></cfif>
								#selectEvictPolicy(selected=config.evictPolicy, limit=config.evictAfter)#
								<div>#permanent("evict", perm.evictPolicy is config.evictPolicy)#</div>
							</td>
						</tr>
						<tr>
							<td>Recommended:</td>
							<td>
								<cfif not ArrayLen(rec)>Not Available</cfif>
								<cfloop index="x" from="1" to="#ArrayLen(rec)#">
									<button type="button" onclick="setEvictPolicy('#rec[x].evictPolicy#:#rec[x].evictAfter#');">
										#ucase(rec[x].evictPolicy)#<cfif len(trim(rec[x].evictAfter))>:#rec[x].evictAfter#</cfif>
									</button>
								</cfloop>
							</td>
						</tr>
						<tr>
							<td>Occupancy:</td>
							<td><cfset temp = getAgentOccupancy(agentid) />
								#temp# <cfif temp>
									<a href="?event=agent_browse&amp;agentid=#urlencodedformat(agentid)#" class="icon detail" title="Browse Content"></a>
								</cfif>
							</td>
						</tr>
					</tbody>
					<tfoot>
						<tr>
							<td></td>
							<td><button type="submit">Update</button></td>
						</tr>
					</tfoot>
				</table>
			</form>
			
			#showHitChart(hitdata.hit,hitdata.miss)#
		</cfoutput>
	</cffunction>
	
	<cffunction name="agentUpdate" access="public" output="false">
		<cfargument name="agentid" type="string" required="true" />
		<cfargument name="permanent" type="string" required="false" default="" />
		
		<cfinvoke component="#getAgentManager()#" method="setAgentConfig" argumentcollection="#arguments#" />
		
		<cfset getConfig().logEvent( "MANUAL" , getStruct( settings = arguments ) ) />
		
		<cfif left(agentid,3) is "clu">
			<!--- this is a cluster agent, sync it with the other servers in the cluster --->
			<cfset getClusterManager().syncAgent(arguments) />
		</cfif>
		<cflocation url="?event=agent_detail&saved=true&agentid=#arguments.agentid#" addtoken="false" />
	</cffunction>
	
	<cffunction name="agent_reset" access="public" output="true">
		<cfargument name="agentid" type="string" required="true" />
		<cfsetting requesttimeout="900" />
		<cfset request.service.resetAgent(agentid) />
		<cflocation url="?event=agent_list&agentid=#urlencodedformat(agentid)#" addtoken="false" />
	</cffunction>
	
	<cffunction name="agentNotRegistered" access="public" output="true" 
	hint="Displays a friendly error message when you request an unregistered agent">
		<cfargument name="agentid" type="string" required="false" default="" />
		<cfoutput>
			<div class="empty statusmessage">
				Agent Not Registered
			</div>
			
			<p>Sorry! The agent you requested is not 
			currently registered with the CacheBox service.</p>
			
			<p>This may happen if the server is restarted 
			or the ColdFusion service is restarted.</p>
			
			<p>You requested: #htmleditformat(arguments.agentid)#</p>
		</cfoutput>
	</cffunction>
	
	<cffunction name="shortenCacheName" access="private" output="false" returntype="string">
		<cfargument name="cachename" type="string" required="true" />
		<cfset var cn = trim(cachename) />
		<cfset var x = len(cn) />
		<cfif x lte 32><cfreturn cn /></cfif>
		<cfset x = x - 32 />
		<cfreturn insert("...", removechars(cn, 16, x), 15) />
	</cffunction>
	
	<cffunction name="agent_browse" access="public" output="true" 
	hint="allows the user to view and potentially drop single items from cache">
		<cfargument name="agentid" type="string" required="true" />
		<cfargument name="startrow" type="string" required="false" default="1" />
		<cfargument name="drop" type="string" required="false" default="" />
		<cfargument name="miss" type="string" required="false" default="" />
		<cfset var mgr = getAgentManager() />
		<cfset var config = mgr.getAgentConfig(arguments.agentid) />
		<cfset var currentTime = getHistory().getMinutes() />
		<cfset var cache = getCacheQuery() />
		<cfset var missCount = 0 />
		<cfset var pages = "" />
		<cfset var qry = 0 />
		
		<cfset arguments.miss = val(arguments.miss) />
		
		<cfif not isNumeric(arguments.startrow)>
			<cfset arguments.startrow = 1 />
		</cfif>
		
		<cfif len(trim(drop))>
			<cfset confirm("Content removed from cache (#htmleditformat(drop)#)") />
		</cfif>
		
		<cfif not arguments.miss>
			<cfquery name="qry" dbtype="query">
				select count(cachename) as missCount from cache 
				where cachename like <cfqueryparam value="#arguments.agentid#|%" cfsqltype="cf_sql_varchar" />
				and expired is not null and expired = 0 and timestored is null 
			</cfquery>
			<cfset missCount = val(qry.missCount) />
		</cfif>
		
		<cfquery name="qry" dbtype="query">
			select * from cache 
			where cachename like <cfqueryparam value="#arguments.agentid#|%" cfsqltype="cf_sql_varchar" />
			and expired is not null and expired = 0 
			<cfif not arguments.miss>
				and timestored is not null and timestored <> 0 
			</cfif>
			order by cachename 
		</cfquery>
		
		<cfoutput>
			<h3 id="BreadCrumbs">
				<a href="?event=agent_list">Agent List</a> 
				<a href="?event=agent_detail&amp;agentid=#urlencodedformat(arguments.agentid)#">#formatAgentName(config.agent)#</a>
				<a>Content</a>
			</h3>
			
			<cfif qry.recordcount>
				<cfset pages = getPages(qry.recordcount,arguments.startrow,"?event=agent_browse&amp;miss=#arguments.miss#&amp;agentid=" & urlencodedformat(arguments.agentid)) />
				#pages#
				
				<div style="margin-top:10px;">
					Frequency: 
					<span class="frequency constant" title="Requests &gt; 1 / minute">Constant</span>
					<span class="frequency high" title="Requests &gt; 1 / hour">High</span>
					<span class="frequency low" title="Requests &gt; 1 / day">Low</span>
					<span class="frequency waste" title="Requests &lt; 1 / day">Waste</span>
				</div>
				
				<cfif arguments.miss>
					<a class="iconlink drop" href="?event=agent_browse&amp;agentid=#urlencodedformat(arguments.agentid)#">Hide Misses</a>
				<cfelseif not arguments.miss and missCount>
					<a class="iconlink detail" href="?event=agent_browse&amp;miss=1&amp;agentid=#urlencodedformat(arguments.agentid)#">Show Misses</a>
				</cfif>
				
				<table class="list" border="0" cellpadding="0" cellspacing="0">
					<col style="text-align: right;" />
					<col />
					<col />
					<col />
					<col style="text-align: center;" />
					<col style="text-align: center;" />
					<col style="text-align: center;" />
					<thead>
						<th><span></span></th>
						<th>Name</th>
						<th>Stored</th>
						<th>Last Hit</th>
						<th>Hits</th>
						<th>Misses</th>
						<th>Frequency</th>
					</thead>
					<tbody>
						<cfloop query="qry" startrow="#arguments.startrow#" endrow="#min(qry.recordcount,arguments.startrow+19)#">
							<tr class="hits_#int(qry.hitCount)#">
								<td>
									#numberformat(currentrow,000)# <cfif qry.hitCount>
										<a href="?event=contentdrop&amp;cachename=#urlencodedformat(qry.cachename)#&amp;startrow=#arguments.startrow#" class="icon drop" title="Remove From Cache"></a>
									</cfif>
								</td>
								<td>
									<cfif qry.hitCount>
										<a href="?event=contentview&amp;cachename=#urlencodedformat(qry.cachename)#" onclick="return popup(this);" title="#htmleditformat(listlast(qry.cachename,"|"))#" target="_blank">
											#htmleditformat(shortenCacheName(listlast(qry.cachename,"|")))#
										</a>
									<cfelse>
										<span title="#htmleditformat(listlast(qry.cachename,"|"))#">
										#htmleditformat(shortenCacheName(listlast(qry.cachename,"|")))#</span>
									</cfif>
								</td>
								<td>#formatAge(val(qry.timeStored))#</td>
								<td>#formatAge(qry.timeHit)#</td>
								<td>#int(qry.hitCount)#</td>
								<td>#int(qry.missCount)#</td>
								<td>#formatFrequency(currentTime-val(qry.timeStored),qry.hitCount)#</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
				
				#pages#
			<cfelse>
				<div class="empty statusmessage">There is no stored content for this agent.</div>
			</cfif>
		</cfoutput>
	</cffunction>
	
	<cffunction name="contentdrop" access="public" output="true" hint="removes a specific item from cache">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="startrow" type="string" required="false" default="1" />
		<cfset var mgr = getAgentManager() />
		<cfset var agent = mgr.getAgent(rereplace(cachename,"\|[^|]*?$","")) />
		
		<cfset agent.delete(listlast(cachename,"|")) />
		
		<cfif not isNumeric(arguments.startrow)>
			<cfset arguments.startrow = 1 />
		</cfif>
		
		<cflocation url="?event=agent_browse&agentid=#urlencodedformat(agent.getAgentID())#&startrow=#arguments.startrow#&drop=#urlencodedformat(listlast(cachename,'|'))#" addtoken="false" />
	</cffunction>
	
	<cffunction name="contentview" access="public" output="true" hint="displays an individual content record">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="saved" type="string" required="false" default="0" />
		<cfset var cache = getCacheQuery() />
		<cfset var agentid = rereplace(cachename,"\|[^|]*?$","") />
		<cfset var mgr = getAgentManager() />
		<cfset var agent = mgr.getAgent(agentid) />
		<cfset var result = agent.fetch(listlast(cachename,"|")) />
		
		<cfsetting showdebugoutput="false" />
		
		<cfoutput>
			<style>
				body { padding-top: 30px; } 
				##nav { display: none; } 
			</style>
			
			<cfset confirm("Content is updated!",val(saved)) />
			
			<h2>View Content</h2>
			
			<table border="0" cellpadding="2" cellspacing="0">
				<tr>
					<td>Agent:</td>
					<td>#formatAgentName(agent)#</td>
				</tr>
				<tr>
					<td>Content:</td>
					<td>#listlast(arguments.cachename,"|")#</td>
				</tr>
			</table>
			
			<cfif result.status eq 0>
				<cfif isSimpleValue(result.content)>
					<form action="?" method="post">
						<input type="hidden" name="event" value="contentset" />
						<input type="hidden" name="cachename" value="#htmleditformat(arguments.cachename)#" />
						<textarea name="content" style="width:550px; height:200px;" wrap="off">#htmleditformat(result.content)#</textarea>
						<div style="text-align:center;">
							<button type="submit">Update</button>
						</div>
					</form>
				<cfelse>
					<cfdump var="#result.content#" />
				</cfif>
			<cfelse>
				<div class="empty statusmessage">
					Content Not Found
				</div>
				
				<p>This content item may have been purged from cache.</p>
			</cfif>
		</cfoutput>
	</cffunction>
	
	<cffunction name="contentset" access="public" output="true" hint="removes a specific item from cache">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="string" required="true" />
		<cfargument name="layout" type="string" required="false" default="0" />
		<cfset var mgr = getAgentManager() />
		<cfset var agent = mgr.getAgent(rereplace(cachename,"\|[^|]*?$","")) />
		<cfset agent.store(listlast(cachename,"|"),arguments.content) />
		<cflocation url="?event=contentview&cachename=#urlencodedformat(arguments.cachename)#&saved=1&layout=#val(arguments.layout)#" addtoken="false" />
	</cffunction>
	
	<cffunction name="showStorageTypeList" access="private" output="true">
		<cfset var mgr = getStorageManager() />
		<cfset var types = mgr.listTypes(ready=false) />
		<cfset var storage = 0 />
		<cfset var context = 0 />
		<cfset var i = 0 />
		
		<cfoutput>
			<table class="list" cellpadding="2" cellspacing="0">
				<thead>
					<tr>
						<th>Storage Type</th>
						<th>Context</th>
						<th>Ready</th>
						<th>Description</th>
					</tr>
				</thead>
				<tbody>
					<cfloop index="i" from="1" to="#ArrayLen(types)#">
						<cfset storage = mgr.getStorageType(types[i]) />
						<tr class="storage ready_#iif(storage.isReady(),1,0)#">
							<td>
								<cfif structKeyExists(storage,"getConfigForm")>
									<a href="?event=storageconfig&amp;storagetype=#types[i]#" 
									class="iconlink configure" title="Configure">#ucase(types[i])#</a>
								<cfelse>
									<a class="iconlink">#ucase(types[i])#</a>
								</cfif>
							</td>
							<td>
								<cfset x = 0 />
								<cfloop index="context" list="CLUSTER,SERVER,APPLICATION">
									<cfset x = x + 1 />
									<cfif storage.supportsContext(x)>
										#context#
										<cfbreak />
									</cfif>
								</cfloop>
							</td>
							<td>#yesnoformat(storage.isready())#</td>
							<td>#htmleditformat(storage.description)#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cffunction>
	
	<cffunction name="storageconfig" access="public" output="true">
		<cfargument name="storagetype" type="string" required="true" />
		<cfoutput>
			<h2>Configure Storage Type: #ucase(trim(arguments.storagetype))#</h2>
			#getStorageManager().getConfigForm(arguments.storagetype)#
		</cfoutput>
	</cffunction>
	
	<cffunction name="storageupdate" access="public" output="false">
		<cfargument name="storagetype" type="string" required="true" />
		<cfset var stmgr = getStorageManager() />
		<cfset var storage = stmgr.getStorageType(arguments.storagetype) />
		
		<cfset storage.setConfig(arguments) />
		<cfif storage.supportsContext(1)>
			<!--- this type supports the cluster context, sync it with other servers in the cluster --->
			<cfset getClusterManager().syncStorage(arguments) />
		</cfif>
		
		<cflocation url="?event=options&confirm=#urlencodedformat('Storage type ' & ucase(arguments.storagetype) & ' updated.')#">
	</cffunction>
	
	<cffunction name="showEvictionPoliciesList" access="private" output="true">
		<cfset var mgr = getPolicyManager() />
		<cfset var types = mgr.getAvailablePolicies() />
		<cfset var i = 0 />
		
		<cfoutput>
			<table class="list" cellpadding="2" cellspacing="0">
				<thead>
					<tr>
						<th>Eviction Policy</th>
						<th>Description</th>
					</tr>
				</thead>
				<tbody>
					<cfloop index="i" from="1" to="#ArrayLen(types)#">
						<tr>
							<td>#ucase(types[i])#</td>
							<td>#htmleditformat(mgr.getPolicy(types[i]).description)#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfoutput>
	</cffunction>
	
	<cffunction name="options" access="public" output="true">
		<cfargument name="confirm" type="string" required="false" default="" />
		
		<cfset variables.confirm(arguments.confirm) />
		
		<cfoutput>
			<div id="OptionsMenu">
				<a href="?event=clusterreset" class="iconlink reset">Reset Cluster Cache</a>
				<a href="?event=serverreset" class="iconlink reset">Reset Server Cache</a>
				<a href="?event=agent_recommendations" class="iconlink configure">Optimize Now</a>
			</div>
		</cfoutput>
		
		<cfset showStorageTypeList() />
		<cfset showEvictionPoliciesList() />
	</cffunction>
	
	<cffunction name="agent_recommendations" access="public" output="true">
		<cfset var cfg = getConfig() />
		<cfset var mgr = getAgentManager() />
		<cfset var qAgent = mgr.getQuery() />
		<cfset var rec = cfg.getRecommendations( "%" , true ) />
		<cfset var json = 0 />
		<cfset var config = 0 />
		<cfset var temp = 0 />
		<cfset var x = 1 />
		
		<cfif not qAgent.recordcount>
			<cfinvoke method="agent_list" />
		<cfelseif not ArrayLen(rec)>
			<cfoutput>#confirm("No new recommendations.")#</cfoutput>
			<cfinvoke method="agent_list" />
		<cfelse>
			<h3 id="BreadCrumbs"><a href="?event=agent_list">Agent List</a><a>Recommendations</a></h3>
			<cfset json = serializeJSON(rec) />
			<cfset rec = recommendationsToStruct( rec ) />
			
			<cfquery name="qAgent" dbtype="query" debug="true" result="temp">
				select *, upper(context) as uppercontext, 
					upper(appname) as upperappname, upper(agentname) as upperagentname 
				from qAgent order by uppercontext, upperappname, upperagentname 
			</cfquery>
			
			<form action="?" method="post">
				<input type="hidden" name="event" value="optimize" />
				<cfoutput query="qAgent" group="context">
					<cfif currentrow eq 1>
						<input type="hidden" name="recommendations" value="#htmleditformat(json)#" />
					</cfif>
					
					<h4>#lcase(context)#</h4>
					
					<table class="list" cellpadding="2" cellspacing="0">
						<thead>
							<th>Agent</th>
							<th>Storage Type</th>
							<th>Evict Policy</th>
							<th>Recommendation</th>
						</thead>
						<tbody>
							<cfoutput group="appname">
								<cfif qAgent.context is "application">
									<tr class="appname">
										<th colspan="7" title="#htmleditformat(appname)#">
											#htmleditformat(rereplace(lcase(appname),"_+"," ","ALL"))#
											<div><a name="#htmleditformat(appname)#">&nbsp;</a></div>
										</th>
									</tr>
								</cfif>
								<cfoutput group="agentname">
									<cfset config = mgr.getAgentConfig(mgr.getAgentID(context,appname,agentname)) />
									<cfset aid = urlencodedformat(agentid) />
									<tr>
										<td><a href="?event=agent_detail&amp;agentid=#urlencodedformat(listchangedelims(replace(qAgent.agentid, '%', ''), '|', '|'))#" title="Agent Details">#htmleditformat(agentname)#</a></td>
										<td>#config.storageType#</td>
										<td>
											<cfset temp = config.agent.getEvictPolicy() />
											<cfif listfindnocase("auto,fresh,perf",temp)>#lcase(temp)#:</cfif>
											#lcase(config.evictPolicy)# <cfif val(config.evictAfter) gt 0>(#config.evictAfter#)</cfif>
										</td>
										
										<cfif StructKeyExists(rec, agentid)>
											<td>
												<cfloop index="x" from="1" to="#ArrayLen(rec[agentid])#">
													<cfset temp = rec[agentid][x] />
													<cfparam name="temp.evictAfter" default="" />
													<cfparam name="temp.hintText" default="" />
													<label class="recommendation" title="#htmleditformat(temp.hintText)#">
														<input type="checkbox" name="selected" 
															onchange="selectRecommendation(this);" 
															value="#temp.index#" <cfif x is 1>checked="checked" </cfif>/>
														#temp.evictPolicy#
														<cfif len(trim(temp.evictAfter))>(#temp.evictAfter#)</cfif>
													</label>
													<cfset x = x + 1 />
												</cfloop>
											</td>
										<cfelseif not config.agent.getSize()>
											<td class="NoContent">no content</td>
										<cfelse>
											<td><!-- no recommendations --></td>
										</cfif>
									</tr>
								</cfoutput>
							</cfoutput>
						</tbody>
					</table>
				</cfoutput>
				
				<p style="text-align:center; width:600px;">
					<label style="display:block;">
						<input type="checkbox" name="permanent" value="evictpolicy" /> Make Permanent
					</label>
					<button type="submit">Apply Recommendations</button>
				</p>
			</form>
		</cfif>
	</cffunction>
	
	<cffunction name="optimize" access="public" output="false">
		<cfargument name="recommendations" type="string" required="true" />
		<cfargument name="selected" type="string" required="false" default="" />
		<cfargument name="permanent" type="string" required="false" default="" />
		<cfset var rec = deserializeJSON(recommendations) />
		<cfset var applied = ArrayNew(1) />
		<cfset var x = 0 />
		
		<cfloop index="x" list="#selected#">
			<cfset ArrayAppend(applied, rec[x]) />
		</cfloop>
		
		<cfset getConfig().applyRecommendations( applied , permanent , "MANUAL" ) />
		
		<cflocation url="?event=agent_list_optimized" addtoken="false" />
	</cffunction>
	
	<cffunction name="cluster" access="public" output="true">
		<cfargument name="confirm" type="string" required="false" default="" />
		<cfargument name="warn" type="string" required="false" default="" />
		<cfset var mgr = getClusterManager() />
		<cfset var svr = mgr.getServerArray() />
		<cfset var localhost = getServerID() />
		<cfset var serverid = "" />
		<cfset var status = "OK" />
		<cfset var svc = 0 />
		<cfset var i = 0 />
		
		<cfset variables.confirm(arguments.confirm) />
		<cfset variables.warn(arguments.warn) />
		
		<cfoutput>
			<table class="list" cellpadding="2" cellspacing="0">
				<thead>
					<tr>
						<th>Server</th>
						<th>Status</th>
						<th>ServerID</th>
					</tr>
				</thead>
				<tbody>
					<tr style="background-color: ##F0F0FF; color: navy; font-weight: bold;">
						<td>#rereplace(cgi.server_name & getDirectoryFromPath(cgi.script_name),"^(\w+)/cachebox/?$","\1")#</td>
						<td>OK</td>
						<td>#localhost#</td>
					</tr>
					<cfloop index="i" from="1" to="#ArrayLen(svr)#">
						<cftry>
							<cfset serverid = "" />
							<cfset svc = mgr.getWebservice(svr[i]) />
							<cftry>
								<cfset serverid = svc.getServerID(localhost) />
								<cfif serverid is "REJECTED">
									<!--- created the webservice but not yet trusted by that server --->
									<cfset status = serverid />
								<cfelseif len(trim(serverid))>
									<!--- created the webservice and got the serverid, everything is working swimmingly --->
									<cfset status = "OK" />
								<cfelse>
									<cfthrow />
								</cfif>
								
								<cfcatch>
									<!--- created the webservice, but couldn't get the serverid --->
									<cfset status = "DAMAGED" />
								</cfcatch>
							</cftry>
							<cfcatch>
								<!--- couldn't create the webservice --->
								<cfset status = "UNAVAILABLE" />
							</cfcatch>
						</cftry>
						
						<!--- only show the server in the list if it's not the current server --->
						<cfif serverid is not localhost>
							<tr>
								<td><a href="#mgr.getServerURL(svr[i])#/?event=cluster">#svr[i]#</a></td>
								<td>#status#</td>
								<td>
									<cfif status is "REJECTED">
										<form action="?" method="post" title="Get trust by entering the serverid.">
											<input type="hidden" name="event" value="serverauthenticate" />
											<input type="hidden" name="serverstring" value="#htmleditformat(svr[i])#" />
											<input type="text" name="serverid" value="" />
											<button type="submit">Get Trust</button>
										</form>
									<cfelse>
										<span>#serverid#</span>
									</cfif>
								</td>
							</tr>
						</cfif>
					</cfloop>
				</tbody>
			</table>
			
			<form action="?event=clustersave" method="post">
				<div style="width:40em; text-align:center; margin-top:3em;">
					<div>Enter one server per line as an IP Address or full URL.</div>
					<textarea name="serverlist" style="height:5em;width:100%;">#htmleditformat(arraytolist(svr,chr(13) & chr(10)))#</textarea>
					<div><button type="submit">Save</button></div>
				</div>
			</form>
		</cfoutput>
	</cffunction>
	
	<cffunction name="clustersave" access="public" output="false">
		<cfargument name="serverlist" type="string" required="false" default="" />
		<cfset getClusterManager().setServers(serverlist) />
		<cflocation url="?event=cluster" addtoken="false" />
	</cffunction>
	
	<cffunction name="serverauthenticate" access="public" output="false">
		<cfargument name="serverstring" type="string" required="true" />
		<cfargument name="serverid" type="string" required="true" />
		<cfset var localhost = getServerID() />
		<cfset var mgr = getClusterManager() />
		<cfset var result = 0 />
		<cfset var svc = 0 />
		<cfset var i = 0 />
		
		<cftry>
			<cfset svc = mgr.getWebservice(serverstring) />
			<cftry>
				<cfif svc.getTrust(serverid,localhost)>
					<cfset mgr.addTrustedServer(arguments.serverid) />
					
					<cftry>
						<!--- since we've established trust, now we can attempt to fetch the other 
						trusted servers and servers from the cluster -- this isn't strictly 
						necessary, but it cuts down on the time it takes to configure a cluster --->
						<cfset result = svc.getTrustedServers(localhost) />
						<cfloop index="i" from="1" to="#ArrayLen(result)#">
							<cfset mgr.addTrustedServer(result[i]) />
						</cfloop>
						
						<cfset result = svc.getServerArray(localhost) />
						<cfloop index="i" from="1" to="#ArrayLen(result)#">
							<cfset svc = mgr.getWebservice(result[i]) />
							<cfset serverid = svc.getServerID(localhost) />
							<cfif serverid neq localhost and serverid neq "REJECTED">
								<cfset mgr.addServer(result[i]) />
							</cfif>
						</cfloop>
						<cfcatch>
							<!--- <cfdump var="#cfcatch#" /><cfabort /> --->
						</cfcatch>
					</cftry>
					
					<cflocation url="?event=cluster&confirm=#urlencodedformat('Trust established with #serverstring#.')#" addtoken="false" />
				<cfelse>
					<cflocation url="?event=cluster&warn=#urlencodedformat('Trust request rejected by #serverstring#.')#" addtoken="false" />
				</cfif>
				
				<cfcatch>
					<cflocation url="?event=cluster&warn=#urlencoedformat('An unknown error occurred while establish trust with #serverstring#.')#" addtoken="false" />
				</cfcatch>
			</cftry>
			<cfcatch>
				<cflocation url="?event=cluster&warn=#urlencodedformat('Can''t connect to #serverstring# server.')#" addtoken="false" />
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="clusterreset" access="public" output="false">
		<cfsetting requesttimeout="900" />
		<cfset request.service.resetCluster() />
		<cflocation url="?event=options" addtoken="false" />
	</cffunction>
	
	<cffunction name="serverreset" access="public" output="false">
		<cfsetting requesttimeout="900" />
		<cfset request.service.resetserver() />
		<cflocation url="?event=options" addtoken="false" />
	</cffunction>
	
	<cffunction name="logout" access="public" output="false">
		<cfset session.authenticated = false />
		<cflocation url="?" addtoken="false" />
	</cffunction>
	
</cfcomponent>

