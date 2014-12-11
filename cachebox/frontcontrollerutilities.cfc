<cfcomponent output="false" extends="util" displayname="CacheBox.FrontController" 
hint="I am the management application for manually viewing or modifying cache configuration">
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset structAppend(instance,arguments,true) />
		<cfset instance.cache = getStorage().getCacheCopy() />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getCacheQuery" access="private" output="false">
		<cfreturn instance.cache />
	</cffunction>
	
	<cffunction name="getMinutes" access="public" output="false" returntype="numeric" 
	hint="returns the number of minutes since 1/1/1970 for use in measuring the lifespan of cache">
		<cfreturn getHistory().getMinutes() />
	</cffunction>
	
	<cffunction name="formatTime" access="private" output="false">
		<cfargument name="date" type="string" required="true" />
		<cfargument name="alt" type="string" required="false" default="NONE" hint="this value is returned if the date argument is not a date" />
		
		<cfif isDate(date)>
			<cfset alt = lsTimeFormat(date,"short") />
			<cfif dateformat(date) is not dateformat(now())>
				<cfset alt = lsDateFormat(date,"short") & " " & alt />
			</cfif>
		</cfif>
		
		<cfreturn alt />
	</cffunction>
	
	<cffunction name="formatAge" access="private" output="false">
		<cfargument name="minutes" type="numeric" required="true" />
		<cfset var age = getMinutes() - minutes />
		
		<cfif minutes eq 0><cfreturn "&nbsp;" /></cfif>
		
		<cfif age gt 1440>
			<cfreturn int(age/1440) & " days" />
		<cfelseif age gt 120>
			<cfreturn int(age/60) & " hrs" />
		<cfelseif age lt 1>
			<cfreturn "seconds" />
		<cfelse>
			<cfreturn int(age) & " min" />
		</cfif>
	</cffunction>
	
	<cffunction name="showHitChart" access="private" output="false">
		<cfargument name="hits" type="numeric" required="true" />
		<cfargument name="misses" type="numeric" required="true" />
		<cfset var result = "" />
		<cfset var temp = "" />
		<cfset var hitlabel = "Hits" />
		<cfset var misslabel = "Misses" />
		
		<!--- add percentages to the labels if we have any hits --->
		<cfif hits + misses neq 0>
			<cfset temp = int((hits/(hits+misses))*100) />
			<cfset hitlabel &= " (" & temp & "%)" />
			<cfset misslabel &= " (" & 100 - temp & "%)" />
		</cfif>
		
		<!--- show the pie chart --->
		<cfsavecontent variable="result">
			<cfchart format="jpg" show3d="true" showlegend="true">
				<cfchartseries type="pie">
					<cfchartdata item="#hitlabel#" value="#hits#" />
					<cfchartdata item="#misslabel#" value="#misses#" />
				</cfchartseries>
			</cfchart>
		</cfsavecontent>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getAgentStats" access="private" output="false" hint="returns aggregate data for the agent list page">
		<cfset var agent = getAgentManager().getQuery() />
		<cfset var cache = getCacheQuery() />
		<cfset var group = "agent.agentid, agent.context, agent.appname, agent.agentname" />
		<cfset var qHit = 0 />
		<cfset var qry = 0 />
		
		<cfloop query="agent">
			<!--- the agentid has a % symbol at the end for convenience when fetching analysis data - 
			- we strip that off here so that it's not present when returned to the frontcontroller for display to the admin --->
			<cfset agent.agentid = removechars(agent.agentid,len(agent.agentid),1) />
		</cfloop>
		
		<!--- first we need to get all the data into hit and miss queries --->
		<cfquery name="qry" dbtype="query" debug="false">
			select #group#, cache.index, cache.hitcount, cache.misscount, 
				cache.timehit, cast(cache.timestored as integer) as timestored 
			from agent, cache where cache.cachename like agent.agentid + '%' and cache.expired = 0 
		</cfquery>
		
		<!--- get counts for stored cache --->
		<cfquery name="qHit" dbtype="query" debug="false">
			select agentid, count(index) as occupancy, min(timestored) as oldest, 
				sum(hitcount) as numhits, max(timehit) as lasthit 
			from qry where timestored is not null group by agentid 
		</cfquery>
		
		<!--- add in the miss counts --->
		<cfquery name="qry" dbtype="query" debug="false">
			select agentid, 0 as oldest, 0 as occupancy, 0 as numhits, 0 as lasthit, sum(misscount) as nummiss 
			from qry group by agentid 
			union all 
			select agentid, oldest, occupancy, numhits, lasthit, 0 from qHit 
			union all 
			<!--- some agents may not exist in qry or qHit, so we add them back in here with zeroes for all their aggregate data --->
			select agentid, 0, 0, 0, 0, 0 from agent 
		</cfquery>
		
		<!--- consolidate the results into a single entry for each agent --->
		<cfquery name="qry" dbtype="query" debug="false">
			select #group#, max(qry.oldest) as oldest, max(qry.occupancy) as occupancy, 
				max(qry.lasthit) as lasthit, max(qry.numhits) as numhits, max(qry.nummiss) as nummiss 
			from agent, qry where qry.agentid = agent.agentid group by #group# order by #group#
		</cfquery>
		
		<cfreturn qry />
	</cffunction>
	
	<cffunction name="getAppStats" access="private" output="false">
		<cfset var cache = getCacheQuery() />
		<cfset var qry = 0 />
		
		<cfquery name="qry" dbtype="query" debug="false">
			select distinct appname, 
				count(index) as occupancy, 
				min(timestored) as oldest, 
				max(timehit) as lasthit 
			from cache 
			where appName <> '' 
				and timeStored is not null 
				and timeStored <> 0
			group by appname 
		</cfquery>
		
		<cfreturn qry />
	</cffunction>
	
	<cffunction name="getAgentHits" access="public" output="false" returntype="struct">
		<cfargument name="agentid" type="string" required="true" />
		<cfset var cache = getCacheQuery() />
		<cfset var result = StructNew() />
		<cfset var qry = 0 />
		
		<cfquery name="qry" dbtype="query" debug="false">
			select sum(cast(hitCount as integer)) as hit, 
				sum(cast(missCount as integer)) as miss 
			from cache 
			where cachename like <cfqueryparam value="#arguments.agentid#|%" cfsqltype="cf_sql_varchar" />
		</cfquery>
		
		<cfset result.hit = val(qry.hit) />
		<cfset result.miss = val(qry.miss) />
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="getAgentOccupancy" access="private" output="false">
		<cfargument name="agentid" type="string" required="true" />
		<cfset var cache = getCacheQuery() />
		<cfset var result = 0 />
		
		<cfquery name="result" dbtype="query" debug="false">
			select count(index) as num 
			from cache 
			where timeStored is not null and timeStored <> 0 <!--- don't include miss counts --->
			and expired is not null and expired = 0 <!--- don't include expired content --->
			and cachename like <cfqueryparam value="#listChangeDelims(arguments.agentid,'|','|')#|%" cfsqltype="cf_sql_varchar" />
		</cfquery>
		
		<cfreturn val(result.num) />
	</cffunction>
	
	<cffunction name="checked" access="private" output="false" returntype="string">
		<cfargument name="checked" type="boolean" required="true" default="false" />
		<cfif checked><cfreturn "checked=""checked""" /></cfif>
		<cfreturn "" />
	</cffunction>
	
	<cffunction name="permanent" access="private" output="false" returntype="string">
		<cfargument name="value" type="string" required="true" />
		<cfargument name="permanent" type="boolean" required="true" />
		<cfreturn "<input type=""checkbox"" name=""permanent"" value=""#arguments.value#"" #checked(arguments.permanent)# /> Permanent" />
	</cffunction>
	
	<cffunction name="confirm" access="public" output="true">
		<cfargument name="message" type="string" required="true" />
		<cfargument name="confirm" type="boolean" required="false" default="true" />
		<cfif confirm and len(trim(arguments.message))>
			<cfoutput><div class="confirm statusmessage">#arguments.message#</div></cfoutput>
		</cfif>
	</cffunction>
	
	<cffunction name="warn" access="public" output="true">
		<cfargument name="message" type="string" required="true" />
		<cfargument name="warn" type="boolean" required="false" default="true" />
		<cfif warn and len(trim(arguments.message))>
			<cfoutput><div class="warning statusmessage">#arguments.message#</div></cfoutput>
		</cfif>
	</cffunction>
	
	<cffunction name="getPages" access="private" output="false">
		<cfargument name="recordcount" type="numeric" required="true" />
		<cfargument name="startrow" type="numeric" required="true" />
		<cfargument name="href" type="string" required="true" />
		<cfargument name="size" type="numeric" default="20" />
		<cfset var bounds = getStruct( bottom = 1, top = recordcount ) />
		<cfset var label = "Pages" />
		<cfset var result = "" />
		<cfset var i = 0 />
		
		<!--- don't show pages if there's only one page of results --->
		<cfif recordcount lte size><cfreturn "" /></cfif>
		
		<cfif int(recordcount / size) gt 15>
			<cfset bounds.bottom = max(1,startrow-(7*size)) />
			<cfset bounds.top = min(recordcount,bounds.bottom+(14*size)) />
			<cfset label &= " (#ceiling(recordcount/size)#)" />
		</cfif>
		
		<cfoutput>
			<cfsavecontent variable="result">
				<div class="pages">#label#: 
					<cfloop index="i" from="#bounds.bottom#" to="#bounds.top#" step="#size#"><a 
						href="#arguments.href#&amp;startrow=#i#"
						<cfif startrow is i>class="current"</cfif>>
							#int(1+int(i/size))#
					</a></cfloop>
				</div>
			</cfsavecontent>
		</cfoutput>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="formatAgentName" access="private" output="false" returntype="string">
		<cfargument name="agent" type="any" required="true" />
		<cfset var result = agent.getAgentName() & " (" />
		
		<cfif agent.getContext() is "application">
			<cfset result &= agent.getAppName() />
		<cfelse>
			<cfset result &= agent.getContext() />
		</cfif>
		
		<cfreturn result & ")" />
	</cffunction>
	
	<cffunction name="formatFrequency" access="private" output="false" returntype="string">
		<cfargument name="minutes" type="numeric" required="true" />
		<cfargument name="hits" type="numeric" required="true" />
		<cfset var dtn = max(1,minutes) />
		
		<cfif hits eq 0>
			<cfreturn "&nbsp;" />
		<cfelseif hits gte dtn>
			<!--- GREEN: constantly requested content (several times per minute) may merit special handling to limit dog-piling --->
			<cfreturn "<span class=""frequency constant"">#ceiling(hits/dtn)#/min</span>" />
		<cfelseif dtn / hits gte 1440>
			<!--- RED: content that sits in cache for over a day without being request is wasting resources --->
			<cfreturn "<span class=""frequency waste"">#int(dtn/1440)# days<span>" />
		<cfelseif dtn / hits gte 120>
			<!--- BLACK: low-frequency content (several times per day) --->
			<cfreturn "<span class=""frequency low"">#int(dtn/60)# hrs</span>" />
		<cfelse>
			<!--- BLUE: high-frequency content (several times per hour) --->
			<cfreturn "<span class=""frequency high"">#int(dtn/hits)# min</span>" />
		</cfif>
	</cffunction>
	
	<cffunction name="selectStorageType" access="private" output="true">
		<cfargument name="context" type="string" required="true" />
		<cfargument name="name" type="string" required="false" default="storagetype" />
		<cfargument name="selected" type="string" required="false" default="default" />
		<cfset var mgr = getStorageManager() />
		<cfset var types = mgr.listTypes(context=arguments.context,ready=true) />
		<cfset var span = CreateUUID() />
		<cfset var storage = 0 />
		<cfset var result = "" />
		<cfset var hint = "" />
		<cfset var i = 0 />
		
		<cfsavecontent variable="result">
		<cfoutput>
			<div>
				<select name="#arguments.name#" 
				onchange="document.getElementById('#span#').innerHTML=this.options[this.selectedIndex].getAttribute('hint');">
					<cfloop index="i" from="1" to="#ArrayLen(types)#">
						<cfset storage = mgr.getStorageType(types[i]) />
						<cfif storage.isReady()>
							<option value="#lcase(types[i])#" hint="#htmleditformat(storage.description)#"
							<cfif arguments.selected is types[i]>
								selected="selected"
								<cfset hint = htmleditformat(mgr.getStorageType(types[i]).description) />
							</cfif>>#ucase(types[i])#</option>
						</cfif>
					</cfloop>
					<option value="" hint="Use to remove a permanent storage type setting">AUTO</option>
				</select>
				<span id="#span#">#hint#</span>
			</div>
		</cfoutput>
		</cfsavecontent>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="selectEvictPolicy" access="private" output="true">
		<cfargument name="name" type="string" required="false" default="evictpolicy" />
		<cfargument name="selected" type="string" required="false" default="none" />
		<cfargument name="limit" type="string" required="false" default="" />
		<cfargument name="limitname" type="string" required="false" default="evictafter" />
		<cfset var input = " <input type=""text"" name=""#arguments.limitname#"" class=""number"" value=""#max(1,val(arguments.limit))#"" /> " />
		<cfset var mgr = getPolicyManager() />
		<cfset var pol = mgr.getAvailablePolicies() />
		<cfset var policy = 0 />
		<cfset var span = CreateUUID() />
		<cfset var result = "" />
		<cfset var temp = "" />
		<cfset var hint = "" />
		<cfset var i = 0 />
		
		<cfsavecontent variable="result">
		<cfoutput>
			<div>
				<select name="#arguments.name#" 
				onchange="document.getElementById('#span#').innerHTML=this.options[this.selectedIndex].getAttribute('hint');">
					<cfloop index="i" from="1" to="#ArrayLen(pol)#">
						<cfset policy = mgr.getPolicy(pol[i]) />
						<cfset temp = policy.description />
						<cfif len(trim(policy.limitlabel))>
							<cfset temp = rereplacenocase(temp,"\sN\s",input) />
						</cfif>
						
						<option value="#lcase(pol[i])#" hint="#htmleditformat(temp)#"
						<cfif arguments.selected is pol[i]>
							selected="selected"
							<cfset hint = temp />
						</cfif>>#ucase(pol[i])#</option>
					</cfloop>
					<option value="" hint="Use to remove a permanent eviction policy">AUTO</option>
				</select>
				<span id="#span#">#hint#</span>
			</div>
		</cfoutput>
		</cfsavecontent>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="navLink" access="private" output="false" returntype="string">
		<cfargument name="label" type="string" required="true" />
		<cfargument name="event" type="string" required="false" default="#lcase(rereplace(label,'\W','','ALL'))#" />
		
		<cfreturn "<a href=""?event=#event#"" id=""nav#listfirst(event,'_')#"">#label#</a>" />
	</cffunction>
	
	<cffunction name="getMenuArray" access="private" output="false" returntype="array">
		<cfset var st = getStruct />
		<cfreturn getArray( 
			st( label = "Home" ), 
			st( label = "Applications", event = "applist" ), 
			st( label = "Agents", event = "agent_list" ), 
			st( label = "Cluster" ), 
			st( label = "Options" ) 
			) />
	</cffunction>
	
	<cffunction name="getMenu" access="private" output="false" returntype="string">
		<cfset var menu = getMenuArray() />
		<cfset var x = 0 />
		
		<cfloop index="x" from="1" to="#ArrayLen(menu)#">
			<cfset menu[x] = navLink(argumentCollection = menu[x]) />
		</cfloop>
		
		<cfreturn ArrayToList(menu, chr(13) & chr(10)) />
	</cffunction>
	
	<cffunction name="showLayout" access="public" output="true">
		<cfargument name="event" type="string" required="true" />
		<cfargument name="content" type="string" required="true" />
		<cfargument name="events" type="struct" required="false" default="#StructNew()#" />
		<cfset var x = 0 />
		
		<cfoutput>
			<html>
			<head>
				<title>CacheBox</title>
				<link rel="stylesheet" href="cachebox.css" />
				
				<style type="text/css">
					##nav ##nav#lcase(listfirst(event,'_'))# { 
						border-bottom: 2px solid white; 
						background-color: white; 
						background-image: none; 
					} 
				</style>
				
				<script src="cachebox.js" language="javascript" type="text/javascript"></script>
			</head>
			<body<cfloop item="x" collection="#events#"> #lcase(x)#="#htmleditformat(events[x])#"</cfloop>>
				<div id="CBHead">
					<h1 id="header"><img src="images/cachebox.png" alt="CacheBox" /></h1>
					
					<div id="HelpAndLogOut">
						<cfif session.authenticated><a id="logout" href="?event=logout">Log Out</a></cfif>
						
						<a id="help" href="docs/CacheBox.pdf" target="_blank">Help</a>
					</div>
					
					<div id="nav">
					<cfswitch expression="#arguments.event#">
							<cfcase value="login">
								<a id="navlogin">Login</a>
							</cfcase>
							
						<cfdefaultcase>#getMenu()#</cfdefaultcase>
						</cfswitch>
					</div>
				</div>
				<div id="content">#arguments.content#</div>
			</body>
			</html>
		</cfoutput>
	</cffunction>
	
	<cffunction name="getConfig" access="public" output="false">
		<cfreturn request.service.getConfig() />
	</cffunction>
	
	<cffunction name="getService" access="public" output="false">
		<cfreturn request.service />
	</cffunction>
	
	<cffunction name="recommendationsToStruct" access="private" output="false">
		<cfargument name="rec" type="array" required="true" />
		<cfset var st = StructNew() />
		<cfset var id = 0 />
		<cfset var x = 0 />
		
		<cfloop index="x" from="1" to="#ArrayLen(rec)#">
			<cfset id = rec[x].agentid & "|%" />
			<cfset rec[x].index = x />
			<cfset st[id] = iif(structKeyExists(st, id), "st[id]", "ArrayNew(1)") />
			<cfset ArrayAppend(st[id], rec[x]) />
		</cfloop>
		
		<cfreturn st />
	</cffunction>
	
</cfcomponent>

