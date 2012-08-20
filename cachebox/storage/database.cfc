<cfcomponent displayname="CacheBox.storage.database" extends="default" output="false" 
hint="I cache content to a database server - I can only be used for agents that store strings, not objects">
	<cfset instance.context = 1 />
	<cfset instance.dsn = "" />
	<cfset instance.usr = "" />
	<cfset instance.pwd = "" />
	<cfset instance.tablename = "cachebox" />
	<cfset instance.keycolumn = "cachename" />
	<cfset instance.contentcolumn = "cachevalue" />
	<cfset instance.contenttype = "longvarchar" />
	<cfset instance.debug = "false" />
	<cfset instance.settings = "database.xml.cfm" />
	<cfset this.description = "Saves cached content to a database table" />
	
	<cffunction name="isReady" access="public" output="false" returntype="boolean">
		<cfreturn iif(len(instance.dsn),true,false) />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		
		<cftry>
			<cfquery datasource="#instance.dsn#" username="#instance.usr#" password="#instance.pwd#" debug="#instance.debug#">
				insert into #instance.tablename# (#instance.keycolumn#,#instance.contentcolumn#) 
				values ( 
					<cfqueryparam value="#arguments.cachename#" cfsqltype="cf_sql_varchar" />,
					<cfqueryparam value="#arguments.content#" cfsqltype="cf_sql_#instance.contenttype#" />
				) 
			</cfquery>
			<cfcatch>
				<!--- 
					we're assuming for the moment that the error was generated 
					because of a duplicate insert, in which case we can ignore the error 
				---> 
			</cfcatch>
		</cftry>
		
		<cfreturn "" />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="any">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfset var result = getStruct( status = 1, content = "" ) />
		<cfset var qry = 0 />
		
		<cftry>
			<cfquery name="qry" datasource="#instance.dsn#" username="#instance.usr#" password="#instance.pwd#" debug="#instance.debug#">
				select #instance.contentcolumn# as contentvalue from #instance.tablename# 
				where #instance.keycolumn# = <cfqueryparam value="#arguments.cachename#" cfsqltype="cf_sql_varchar" />
			</cfquery>
			<cfset result = getStruct( status = iif(qry.recordcount,0,1), content = qry.contentvalue ) />
			
			<cfcatch>
				<!--- unable to fetch the content --->
			</cfcatch>
		</cftry>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		
		<cfquery datasource="#instance.dsn#" username="#instance.usr#" password="#instance.pwd#" debug="#instance.debug#">
			delete from #instance.tablename# 
			where #instance.keycolumn# = <cfqueryparam value="#arguments.cachename#" cfsqltype="cf_sql_varchar" />
		</cfquery>
	</cffunction>
	
	<cffunction name="getConfigForm" access="public" output="false" returntype="string">
		<cfset var result = "" />
		<cfset var x = 0 />
		
		<cfsavecontent variable="result">
			<cfoutput>
				<form>
					<input type="text" name="dsn" label="Datasource" value="#instance.dsn#" />
					<input type="text" name="usr" label="Username" value="#instance.usr#" />
					<input type="text" name="pwd" label="Password" value="#instance.pwd#" />
					<input type="text" name="tablename" label="Table Name" value="#instance.tablename#" />
					<input type="text" name="keycolumn" label="Key Column" value="#instance.keycolumn#" />
					<input type="text" name="contentcolumn" label="Content Column" value="#instance.contentcolumn#" />
					<select type="text" name="contenttype" label="Content Type">
						<cfloop index="x" list="longvarchar,clob">
							<option value="#x#" <cfif instance.contenttype is x>selected="selected"</cfif>>#ucase(x)#</option>
						</cfloop>
					</select>
					<input type="checkbox" name="debug" label="Debug Queries" value="#instance.debug#" <cfif instance.debug>checked="checked"</cfif> />
				</form>
			</cfoutput>
		</cfsavecontent>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>

