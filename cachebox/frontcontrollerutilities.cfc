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
	
	<cffunction name="getAgentStats" access="private" output="false">
		<cfset var agent = getAgentManager().getQuery() />
		<cfset var cache = getCacheQuery() />
		
		<cfloop query="agent">
			<cfset agent.agentid = removechars(agent.agentid,len(agent.agentid)-1,1) />
		</cfloop>
		
		<cfquery name="qry" dbtype="query" debug="false">
			select agent.agentid, agent.context, agent.appname, agent.agentname, 
				count(cache.index) as occupancy, 
				min(cache.timestored) as oldest, 
				max(cache.timehit) as lasthit 
			from agent, cache 
			where cache.timeStored is not null and cache.timeStored <> 0
				and cache.cachename like agent.agentid + '%'
			group by agent.context, agent.appname, agent.agentname, agentid 
		</cfquery>
		
		<cfquery name="qry" dbtype="query" debug="false">
			select agentid, context, appname, agentname, occupancy, oldest, lasthit 
			from qry 
			
			union 
			
			select agentid, context, appname, agentname, 0 as occupancy, 0 as oldest, 0 as lasthit 
			from agent 
			where agentid not in (<cfqueryparam value="#valuelist(qry.agentid)#" cfsqltype="cf_sql_varchar" list="true" />)
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
			and cachename like <cfqueryparam value="#arguments.agentid#|%" cfsqltype="cf_sql_varchar" />
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
		<cfargument name="limit" type="numeric" required="false" default="0" />
		<cfargument name="limitname" type="string" required="false" default="evictafter" />
		<cfset var input = " <input type=""text"" name=""#arguments.limitname#"" class=""number"" value=""#max(1,arguments.limit)#"" /> " />
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
	
	<cffunction name="showHeader" access="public" output="true">
		<cfargument name="event" type="string" required="true" />
		<cfargument name="onload" type="string" required="false" default="window.focus();" />
		
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
				
				<script language="javascript" type="text/javascript">//<![CDATA[ 
					function popup(lnk) { 
						window.cbx_detail = window.open(lnk.href + "&layout=0","cbx_detail","height=400,width=600,status=0,toolbar=0,location=0,menubar=0,directories=0,scrollbars=1,resizable=1"); 
						<!--- this is a workaround for a bug in FireFox that prevents a popup window from displaying above the opening window if it's already open --->
						setTimeout("window.cbx_detail.focus();",100); 
						return false; 
					} 
				//]]></script>
			</head>
			<body>
				<h1 id="header"><img src="images/cachebox.png" alt="CacheBox" /></h1>
				<a id="help" href="docs/CacheBox.pdf" target="_blank">Help</a>
				<div id="nav">
					<cfswitch expression="#arguments.event#">
						<cfcase value="login">
							<a id="navlogin">Login</a>
						</cfcase>
						<cfdefaultcase>
							#navLink("Home")# 
							#navLink("Applications","applist")# 
							#navLink("Agents","agent_list")# 
							#navLink("Cluster")#
							#navLink("Options")#
						</cfdefaultcase>
					</cfswitch>
				</div>
				<div id="content">
		</cfoutput>
	</cffunction>
	
	<cffunction name="showFooter" access="public" output="true">
		<cfoutput>
				</div>
			</body>
			</html>
		</cfoutput>
	</cffunction>
	
</cfcomponent>

