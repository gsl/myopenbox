<cfcomponent displayname="CacheBox.storage.redis" extends="default" output="false" 
hint="I store the content via an externally configured redis server using cfredis">
	<cfset instance.context = 1 />
	<cfset instance.isReady = false />
	<cfset instance.settings = "redis.xml.cfm" />
	<cfset this.description = "External storage using a redis server with cfredis" />
	<cfset instance.factoryClass = "cfredis.redisfactory" />
	<cfset instance.server = "127.0.0.1" />
	<cfset instance.port = "6379" />
	<cfset instance.timeout = 2000 />
	<cfset instance.password = "" />
	<cfset instance.redis = 0 />
	
	<cffunction name="readConfig" access="private" output="false">
		<!--- I set the isReady flag after changes to the config values --->
		<cfset super.readConfig() />
		<cfset variables.Connect() />
	</cffunction>
	
	<cffunction name="connect" access="private" output="false" 
	hint="I create a connection to a cfredis object">
		<cfset var factory = 0 />
		
		<cfif len(trim(instance.factoryclass)) and len(trim(instance.server))>
			<cftry>
				<cfset factory = CreateObject('component',instance.factoryClass).init() />
				<cfset instance.redis = factory.GetPool(instance.server, instance.port, instance.timeout, instance.password) />
				
				<!--- we have the CFC object -- make sure we're able to connect to the redis server for fetch operations as well --->
				<cfif instance.redis.Ping() NEQ "PONG">
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
		<!--- <cftimer label="Store Redis: #arguments.cachename#"> --->
		<cfscript>
		instance.redis.set(arguments.cachename, ToBase64(ObjectSave(arguments.content)));
		</cfscript>
		<!--- </cftimer> --->
		<cfreturn "" />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var result = getStruct( status = 0 ) />
		
		<!--- <cftimer label="Fetch Redis: #arguments.cachename#"> --->
		<cfset result.content = instance.redis.get(arguments.cachename) />
		<!--- </cftimer> --->
		<!--- redis returns an empty string on a miss result(?) --->
		<cfif IsNull(result.content)>
			<!--- <cftrace text="Fetch Redis: Miss: #arguments.cachename#" /> --->
			<cfset result.status = 1 />
			<cfset result.content = "" />
		<cfelse>
			<!--- <cftrace text="Fetch Redis: Hit: #arguments.cachename#" /> --->
			<cfset result.content = ObjectLoad(ToBinary(result.content)) />
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<!--- <cftimer label="Delete Redis: #arguments.cachename#"> --->
		<cfset instance.redis.del(arguments.cachename) />
		<!--- </cftimer> --->
	</cffunction>
	
	<cffunction name="getConfigForm" access="public" output="false" returntype="string">
		<cfset var result = "" />
		<cfset var x = 0 />
		
		<cfsavecontent variable="result">
			<cfoutput>
				<form>
					<head>
						This storage type requires an installed copy of <a href="https://github.com/MWers/cfredis" target="_blank">cfredis</a>. 
					</head>
					<input type="text" name="server" label="Server" value="#instance.server#" />
					<input type="text" name="port" label="Port" value="#instance.port#" />
					<input type="text" name="timeout" label="Timeout in ms" value="#instance.timeout#" />
					<input type="text" name="password" label="Password" value="#instance.password#" />
					<input type="text" name="factoryclass" label="Factory" value="#instance.factoryclass#" />
					<cfif instance.isReady>
						<foot>
							<h3>Redis Info</h3>
							<pre>#HTMLEditFormat(instance.redis.info())#</pre>
						</foot>
					</cfif>
				</form>
			</cfoutput>
		</cfsavecontent>
		
		<cfreturn result />
	</cffunction>
</cfcomponent>

