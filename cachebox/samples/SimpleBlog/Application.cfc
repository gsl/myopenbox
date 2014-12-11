<cfcomponent output="false">

	<cfset this.name = right(rereplace(getDirectoryFromPath(getCurrentTemplatePath()),"\W+","_","ALL"),65)>
	<cfset this.sessionManagement = true>
	<cfset this.sessionTimeout = createTimeSpan(0,0,30,0)>
	<cfset this.setClientCookies = true>
	
	<cfset request.view = "" />
	<cfset request.event = structNew() />
	<cfset request.event.cachename = "" />
	
	<cffunction name="onApplicationStart" output="false">
		<!--- 
			create a space to hold our cache 
			NOTE: the cacheboxagent.cfc is coppied into this directory and the agent is created here, 
			instead of being created at "cachebox.cacheboxagent" -- this means the cache will work 
			if you copy this application onto any server, whether or not CacheBox is installed, 
			i.e. the Cache is NOT dependent on CacheBox -- HOWEVER -- eviction policies and advanced 
			caching features require a CacheBox installation 
			
			Content caching occurs in the onRequest method below 
		--->
		<cfset application.cache = CreateObject("component","cacheboxagent").init("simpleblog") />
	</cffunction>
	
	<cffunction name="onApplicationEnd" returnType="void"  output="false">
		<cfargument name="applicationScope" type="struct" required="true">
		<!--- we don't need any content from this application anymore, throw it out --->
		<cfset applicationScope.cache.reset() />
	</cffunction>
	
	<cffunction name="onSessionStart" returnType="void" output="false">
	</cffunction>
	
	<cffunction name="getSESStruct" access="private" output="false" returntype="struct">
		<cfset var path = listfirst(cgi.query_string,"&") />
		<cfset var result = structNew() />
		<cfif len(trim(path))>
			<cfset result.event = rereplace(path,"^/(\w+).(\w+).*$","\1.\2") />
			<cfswitch expression="#result.event#">
				<cfcase value="general.viewPost">
					<cfset result.id = listgetat(path,3,"/") />
					<cfset setValue("cachename","event.#result.event#.#result.id#") />
				</cfcase>
				<cfcase value="general.blog">
					<cfset setValue("cachename","event.#result.event#") />
				</cfcase>
			</cfswitch>
		</cfif>
		<cfreturn result />
	</cffunction>
	
	<cffunction name="onRequestStart" output="false">
		<cfargument name="targetPage" type="string" required="true" />
		<cfset request.collection = duplicate(url) />
		<cfset structAppend(request.collection,form,true) />
		
		<cfset structAppend(request.collection,getSESStruct(),true) />
		
		<cfparam name="request.collection.event" type="string" default="general.index" />
	</cffunction>
	
	<cffunction name="getCollection" access="public" output="false">
		<cfreturn request.collection />
	</cffunction>
	
	<cffunction name="getCache" access="public" output="false">
		<cfreturn application.cache />
	</cffunction>
	
	<cffunction name="setValue" access="public" output="false">
		<cfargument name="varname" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset request.event[varname] = content />
	</cffunction>
	
	<cffunction name="getValue" access="public" output="false">
		<cfargument name="varname" type="string" required="true" />
		<cfreturn request.event[varname] />
	</cffunction>
	
	<cffunction name="setView" access="public" output="false">
		<cfargument name="viewname" type="string" required="true" />
		<cfset request.view = arguments.viewname />
	</cffunction>
	
	<cffunction name="buildLink" access="public" output="false" returntype="string">
		<cfargument name="eventname" type="string" required="true" />
		<cfargument name="querystring" type="string" required="false" default="" />
		<cfreturn "index.cfm?/#replace(arguments.eventname,'.','/','ALL')#/&#arguments.querystring#" />
	</cffunction>
	
	<cffunction name="renderView" access="public" output="true">
		<cfargument name="viewname" type="string" required="false" default="#request.view#" />
		<cfset var event = this />
		<cfset var rc = getCollection() />
		<cfinclude template="views/#arguments.viewname#.cfm" />
	</cffunction>
	
	<cffunction name="onRequest" output="true">
		<cfargument name="targetPage" type="string" required="true" />
		<cfset var rc = getCollection() />
		<cfset var handler = CreateObject("component","handlers.#listfirst(rc.event,'.')#").init(this) />
		<cfset var cachename = getValue("cachename") />
		<cfset var cache = "" />
		
		<cfif len(cachename)>
			<cfset cache = getCache().fetch(cachename) />
			<cfif not cache.status>
				<!--- we found cache for the current page, so we don't have to execute the page --->
				<cfoutput>#cache.content#</cfoutput>
				<cfreturn true />
			</cfif>
		</cfif>
		
		<cfinvoke component="#handler#" method="#listlast(rc.event,'.')#" event="#this#" />
		<cfparam name="rc.pagetitle" type="string" default="SimpleBlog" />
		
		<cfif len(trim(cachename))>
			<!--- we want to cache this page, but it's not cached yet, so we need to generate the output and store it --->
			<cfsavecontent variable="cache">
				<cfinclude template="layout.cfm" />
			</cfsavecontent>
			
			<cfset getCache().store(cachename,cache) />
			
			<cfoutput>#cache#</cfoutput>
		<cfelse>
			<cfinclude template="layout.cfm" />
		</cfif>
	</cffunction>
	
</cfcomponent>