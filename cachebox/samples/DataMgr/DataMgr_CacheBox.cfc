<!--- 2.2.0.2 (Build 151) --->
<!--- Last Updated: 2009-09-15 --->
<!--- Created by Isaac Dealey 2009-09-15 --->

<!--- NOTE: Change the extends attribute to match your database, for example, 
if you use the MySQL version of DataMgr, change the extends attribute to DataMgr_MySQL
-- download the full DataMgr distribution at http://www.bryantwebconsulting.com/docs/datamgr/ --->

<cfcomponent displayname="Data Manager (CacheBox)" extends="DataMgr_MSSQL" 
hint="I add caching features to Steve Bryant's DataMgr.cfc">
	
	<cfset this.superGetRecord = super.getRecord />
	<cfset this.superGetRecords = super.getRecords />
	
	<cffunction name="init" access="public" returntype="DataMgr" output="no" hint="I instantiate and return this object.">
		<cfargument name="datasource" type="string" required="yes" />
		<cfargument name="database" type="string" required="no" />
		<cfargument name="username" type="string" required="no" />
		<cfargument name="password" type="string" required="no" />
		<cfargument name="SmartCache" type="boolean" default="false" />
		<!--- these arguments let us create the necessary cachebox objects within the DataMgr tool --->
		<cfargument name="CacheAgentName" type="string" default="" />
		<cfargument name="CacheContext" type="string" default="server" />
		
		<cfset var AgentName = arguments.CacheAgentName />
		
		<cfif not len(trim(agentname))>
			<cfset AgentName = "DataMgr." & rereplace(datasource,"\W","","ALL") & "." & rereplace(database,"\W","","ALL") />
		</cfif>
		
		<cfset variables.CacheBox = CreateObject("component","cacheboxagent").init(AgentName,Cachecontext) />
		<cfset variables.CacheBox = CreateObject("component","cacheboxnanny").init(variables.CacheBox) />
		
		<cfreturn super.init(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="setCacheDate" access="public" returntype="void" output="no">
		<cfset super.setCacheDate() />
		<!--- setting the cachedate invalidates all the existing cached queries, so we should reset the CacheBox Agent also --->
		<cfset variables.CacheBox.reset() />
	</cffunction>
	
	<cffunction name="getRecords" access="public" returntype="query" output="no" hint="I get a recordset based on the data given.">
		<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record." />
		<cfargument name="data" type="struct" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key." />
		<cfargument name="orderBy" type="string" default="" />
		<cfargument name="maxrows" type="numeric" required="no" />
		<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned." />
		<cfargument name="advsql" type="struct" hint="A structure of sqlarrays for each area of a query (SELECT,FROM,WHERE,ORDER BY)." />
		<cfargument name="filters" type="array" />
		<cfargument name="cachedafter" type="string" required="false" default="#variables.cachedate#" />
		<cfargument name="cachedwithin" type="numeric" required="false" default="0" />
		<cfargument name="cachename" type="string" required="false" default="" />
		
		<cfif variables.smartcache and not len(trim(arguments.cachename))>
			<cfset arguments.cachename = "getRecords" />
		</cfif>
		
		<cfreturn variables.CacheBox.runMethod( 
			component=this,
			method="superGetRecords",
			args=arguments,
			cachename=arguments.cachename,
			cachedafter=arguments.cachedafter,
			cachedwithin=arguments.cachedwithin) />
	</cffunction>
	
	<cffunction name="getRecord" access="public" returntype="query" output="no" hint="I get a recordset based on the primary key value(s) given.">
		<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
		<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key. Every primary key field should be included.">
		<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
		<cfargument name="cachedafter" type="string" required="false" default="#variables.cachedate#" hint="a date after which the record should be cached">
		<cfargument name="cachedwithin" type="numeric" required="false" default="0" hint="the number of days to cache the result - use CreateTimeSpan() for a proper value">
		
		<cfset var ii = 0><!--- A generic counter --->
		<cfset var pkfields = getPKFields(arguments.tablename)>
		<cfset var fields = getUpdateableFields(arguments.tablename)>
		<cfset var in = arguments.data>
		<cfset var totalfields = 0><!--- count of fields --->
		<cfset var DataString = "">
		
		<!--- Figure count of fields --->
		<cfloop index="ii" from="1" to="#ArrayLen(pkfields)#" step="1">
			<cfif StructKeyExists(in,pkfields[ii].ColumnName) AND isOfType(in[pkfields[ii].ColumnName],pkfields[ii].CF_DataType)>
				<cfset totalfields = totalfields + 1>
			</cfif>
		</cfloop>
		<cfloop index="ii" from="1" to="#ArrayLen(fields)#" step="1">
			<cfif StructKeyExists(in,fields[ii].ColumnName) AND isOfType(in[fields[ii].ColumnName],fields[ii].CF_DataType)>
				<cfset totalfields = totalfields + 1>
			</cfif>
		</cfloop>
		
		<!--- Make sure at least one field is passed in --->
		<cfif totalfields EQ 0>
			<cfloop collection="#arguments.data#" item="ii">
				<cfif isSimpleValue(arguments.data[ii])>
					<cfset DataString = ListAppend(DataString,"#ii#=#arguments.data[ii]#",";")>
				<cfelse>
					<cfset DataString = ListAppend(DataString,"#ii#=(complex)",";")>
				</cfif>
			</cfloop>
			<cfthrow message="The data argument of getRecord must contain at least one field from the #arguments.tablename# table. To get all records, use the getRecords method." detail="(data passed in: #DataString#)" type="DataMgr" errorcode="NeedWhereFields">
		</cfif>
		
		<cfreturn getRecords(
			tablename=arguments.tablename,
			data=in,
			fieldlist=arguments.fieldlist,
			cachename=iif(variables.SmartCache,de("getRecord"),de("")),
			cachedafter=arguments.cachedafter, 
			cachedwithin=arguments.cachedwithin) />
	</cffunction>

</cfcomponent>