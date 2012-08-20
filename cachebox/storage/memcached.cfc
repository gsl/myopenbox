<cfcomponent displayname="CacheBox.storage.memcached" extends="default" output="false" 
hint="I store the content via an externally configured memcached server using cfmemcached">
	<cfset instance.context = 1 />
	<cfset instance.isReady = false />
	<cfset instance.settings = "memcached.xml.cfm" />
	<cfset this.description = "External storage using a memcached server with cfmemcached" />
	<cfset instance.factoryClass = "memcached.memcachedfactory" />
	<cfset instance.serverList = "127.0.0.1:11211" />
	<cfset instance.defaultTimeout = 61 />
	<cfset instance.defaultUnit = "SECONDS" />
	<cfset instance.memcached = 0 />
	
	<cffunction name="readConfig" access="private" output="false">
		<!--- I set the isReady flag after changes to the config values --->
		<cfset super.readConfig() />
		<cfset variables.Connect() />
	</cffunction>
	
	<cffunction name="connect" access="private" output="false" 
	hint="I create a connection to a cfmemcached object">
		<cfset var factory = 0 />
		
		<cfif len(trim(instance.factoryclass)) and len(trim(instance.serverList))>
			<cftry>
				<cfset factory = CreateObject('component',instance.factoryClass).init(
																			servers=trim(rereplace(instance.serverList,"\s+"," ","ALL")), 
																			defaultTimeout=instance.defaultTimeout,
																			defaultUnit=instance.defaultUnit) />
				<cfset instance.memcached = factory.getMemcached() />
				
				<!--- we have the CFC object -- make sure we're able to connect to the memcached server for fetch operations as well --->
				<cfif structIsEmpty(instance.memcached.getVersions())>
					<cfset instance.isReady = false />
					<cfreturn />
				</cfif>
				
				<!--- everything is a-okay --->
				<cfset instance.isReady = true />
				<cfreturn />
				
				<cfcatch></cfcatch>
			</cftry>
		</cfif>
		
		<cfset instance.isReady = false />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset instance.memcached.set(arguments.cachename,arguments.content) />
		<cfreturn "" />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var result = getStruct( status = 0 ) />
		
		<cfset result.content = instance.memcached.get(arguments.cachename) />
		<!--- memcached returns an empty string on a miss result(?) --->
		<cfif not isDefined("result.content") or (isSimpleValue(result.content) and not len(trim(result.content)))>
			<cfset result.status = 1 />
			<cfset result.content = "" />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset instance.memcached.delete(arguments.cachename) />
	</cffunction>
	
	<cffunction name="getConfigForm" access="public" output="false" returntype="string">
		<cfset var result = "" />
		<cfset var x = 0 />
		
		<cfsavecontent variable="result">
			<cfoutput>
				<form>
					<head>
						This storage type requires an installed copy of <a href="http://cfmemcached.riaforge.org" target="_blank">cfmemcached</a>. 
					</head>
					<textarea name="serverlist" label="Servers" size="3">#rereplacenocase(instance.serverlist,"\s+",chr(13) & chr(10),"ALL")#</textarea>
					<input type="text" name="defaulttimeout" label="Default Timeout" value="#instance.defaulttimeout#" />
					<select type="text" name="defaultunit" label="Timeout Unit">
						<cfloop index="x" list="MILLISECONDS,NANOSECONDS,MICROSECONDS,SECONDS">
							<option value="#x#" <cfif instance.defaultunit is x>selected="selected"</cfif>>#ucase(x)#</option>
						</cfloop>
					</select>
					<input type="text" name="factoryclass" label="Factory" value="#instance.factoryclass#" />
				</form>
			</cfoutput>
		</cfsavecontent>
		
		<cfreturn result />
	</cffunction>
</cfcomponent>

