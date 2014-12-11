
<!--- To enable logging, copy this component to the /cachebox/settings directory 
One installed, logging settings may be changed without restarting the ColdFusion service --->

<cfcomponent output="false" hint="I control logging for all loggable cache events">
	<!--- where are log files saved --->
	<cfset instance.logPath = "/logs" />
	
	<!--- number of minutes between logging history snapshots - 0 to disable snapshot logging --->
	<cfset instance.historyLogInterval = 20 />
	
	<!--- number of days or bytes before the history log is rotated and the number of log files to keep before deleting --->
	<cfset instance.historyRotation.Days = 0 /><!--- 0 = no rotation by date --->
	<cfset instance.historyRotation.Size = 0 /><!--- 0 = no rotation by size --->
	<cfset instance.historyRotation.Keep = 3 /><!--- maximum number of logs must be 1 or more if rotation is enabled --->
	
	<!--- flag to log automatic (transient) configuration of agents --->
	<cfset instance.logAutoConfig = 1 />
	
	<!--- flag to log changes to agents from the management application --->
	<cfset instance.logManual = 1 />
	
	<!--- flag to log cluster syncronization of agents --->
	<cfset instance.logClusterSync = 1 />
	
	<!--- number of days or bytes before the agent log is rotated and the number of log files to keep before deleting --->
	<cfset instance.agentRotation.Days = 0 /><!--- 0 = no rotation by date --->
	<cfset instance.agentRotation.Size = 0 /><!--- 0 = no rotation by size --->
	<cfset instance.agentRotation.Keep = 3 /><!--- maximum number of logs must be 1 or more if rotation is enabled --->
	
	<!--- formatting for log files --->
	<cfset instance.logExt = "log.cfm" /><!--- file extension for log files --->
	<cfset instance.logHeaders = 1 /><!--- include headers in log files --->
	<cfset instance.logDelimiter = chr(9) /><!--- tab delimited --->
	<cfset instance.logQualifier = chr(34) /><!--- double quotes --->
	<cfset instance.logQuoteElements = "CHAR" /><!--- only quote non-numeric fields - change to "ALL" to quote all fields or "NONE" for unquoted logs --->
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="config" type="any" required="true" />
		<cfset structAppend( instance, arguments, true ) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="onMissingMethod" access="public" returntype="boolean" 
	hint="I future-proof the application against the addition of new logging methods not yet supported">
		<cfreturn false />
	</cffunction>
	
	<cffunction name="getConfig" access="private" output="false">
		<cfreturn instance.config />
	</cffunction>
	
	<cffunction name="historyLogReady" access="private" output="false" returntype="boolean">
		<cfargument name="lastLogTime" type="string" required="true" />
		<cfset var minutes = iif( isDate( lastLogTime ), 
						"DateDiff( 'n' , lastLogTime , now() )", -1) />
		
		<!--- if we don't log history, then we don't need to check the time --->
		<cfif instance.historyLogInterval eq 0><cfreturn 0 /></cfif>
		
		<!--- if minutes is less than zero, this is the first log, otherwise we need to respect the log interval --->
		<cfreturn iif(minutes lt 0 or minutes gte instance.historyLogInterval, 1, 0)>
	</cffunction>
	
	<cffunction name="history" access="public" output="false" returntype="boolean">
		<cfargument name="snapshot" type="struct" required="true" />
		<cfargument name="lastLogTime" type="string" required="false" default="" />
		
		<!--- this lock prevents a race condition in which there might be multiple history logs at the same time --->
		<cflock name="CacheBox.Log.History" type="exclusive" timeout="10">
			<cfif historyLogReady( lastLogTime )>
				<cfreturn appendHistorySnapshot( snapshot ) />
			</cfif>
		</cflock>
		
		<cfreturn false />
	</cffunction>
	
	<cffunction name="appendHistorySnapshot" access="private" output="false" returntype="boolean">
		<cfargument name="snapshot" type="struct" required="true" />
		<cfset var lp = getLogPath("history") />
		<cfset var data = [ formatTime( snapshot.time ) , snapshot.occupancy, snapshot.freememory, snapshot.cachedelta, snapshot.memdelta ] />
		<cfset checkLogRotation( lp , instance.historyRotation ) />
		<cfreturn appendLog( lp , data , "time,occupancy,freememory,cachedelta,memdelta" ) />
	</cffunction>
	
	<cffunction name="getContextName" access="private" output="false" returntype="string">
		<cfargument name="short" type="string" required="true" />
		<cfswitch expression="#trim(short)#">
			<cfcase value="CLU"><cfreturn "CLUSTER" /></cfcase>
			<cfcase value="SRV"><cfreturn "SERVER" /></cfcase>
			<cfcase value="APP"><cfreturn "APPLICATION" /></cfcase>
		</cfswitch>
	</cffunction>
	
	<cffunction name="appendAgentLog" access="private" output="false" returntype="boolean">
		<cfargument name="settings" type="struct" required="true" />
		<cfargument name="logType" type="string" required="true" />
		<cfargument name="logNote" type="string" required="false" default="" />
		<cfset var loc = StructNew() />
		<cfset loc.lp = getLogPath("agent") />
		<cfset loc.agent = listToArray( settings.agentid , "|" ) />
		<cfset loc.context = getContextName(loc.agent[1]) />
		<cfset loc.appname = iif( loc.context is "CLUSTER" , de("") , "loc.agent[2]") />
		<cfset loc.agentname = iif( loc.context is "CLUSTER" , "loc.agent[2]" , "loc.agent[3]") />
		<cfset loc.storage = iif( structKeyExists( settings , "storagetype" ) , "trim(settings.storageType)" , de("") ) />
		<cfset loc.evict = iif( structKeyExists( settings , "evictPolicy" ) , "trim(settings.evictPolicy)" , de("") ) />
		<cfset loc.threshold = iif( structKeyExists( settings , "evictAfter" ) , "val(settings.evictAfter)" , 0 ) />
		<cfset loc.data = [ formatTime( now() ) , ucase(trim(logType)) , loc.context , loc.appname , loc.agentname , loc.storage, loc.evict , loc.threshold, logNote ] />
		<cfset checkLogRotation( loc.lp , instance.agentRotation ) />
		<cfreturn appendLog( loc.lp , loc.data , "time,logtype,context,appname,agentname,storage,evictpolicy,threshold,lognote" ) />
	</cffunction>
	
	<cffunction name="syncAgent" access="public" output="false" returntype="boolean">
		<cfargument name="serverid" type="string" required="true" />
		<cfargument name="settings" type="struct" required="true" />
		<cfif instance.logClusterSync>
			<cfreturn appendAgentLog( settings , "SYNC" , "SERVER=#serverid#" ) />
		</cfif>
		<cfreturn false />
	</cffunction>
	
	<cffunction name="manual" access="public" output="false" returntype="boolean">
		<cfargument name="settings" type="struct" required="true" />
		<cfargument name="recommendedby" type="string" required="false" default="" />
		<cfset var note = rereplace( "PERM=#settings.permanent# RECOMMENDEDBY=#recommendedby#" , "\w+=(\s|$)" , " " , "ALL") />
		<cfif instance.logManual>
			<cfreturn appendAgentLog( settings , "MAN", trim(note) ) />
		</cfif>
		<cfreturn false />
	</cffunction>
	
	<cffunction name="autoConfig" access="public" output="false" returntype="boolean">
		<cfargument name="settings" type="struct" required="true" />
		<cfset var note = "RECOMMENDEDBY=#settings.recommendedby#" />
		<cfif instance.logAutoConfig>
			<cfreturn appendAgentLog( settings , "AUTO" , note ) />
		</cfif>
		<cfreturn false />
	</cffunction>
	
	<cffunction name="getErrorLogPath" access="private" output="false" returntype="string">
		<cfreturn "errors/" & dateformat(now(), "YYYY-MM-DD") & "-" & timeformat(now(), "HH-mm-ss") & "-#randrange(10,99)#." & instance.logExt />
	</cffunction>
	
	<cffunction name="error" access="public" output="false" returntype="boolean">
		<cfargument name="errorData" type="any" required="true" />
		<cfset var content = "" />
		<cftry>
			<cfsavecontent variable="content"><cfdump var="#errorData#" /></cfsavecontent>
			<cffile action="write" file="#getLogDir()#/#getErrorLogPath()#" output="#content#" />
			<cfreturn true />
			<cfcatch>
				<cfreturn false />
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="appendLog" access="public" output="false" returntype="boolean">
		<cfargument name="logPath" type="string" required="true" />
		<cfargument name="logData" type="any" required="true" />
		<cfargument name="headers" type="string" required="false" default="" />
		<cfset var logDir = getLogDir() />
		<cfset var lp = logDir & "/" & logPath />
		
		<cftry>
			<cflock name="#lp#" type="exclusive" timeout="10">
				<cfif not FileExists( lp )>
					<cfif not instance.logHeaders><cfset arguments.headers = "" /></cfif>
					<cffile action="write" file="#lp#" output="#formatHeaders( arguments.headers )#" />
				</cfif>
				
				<cffile action="append" file="#lp#" output="#formatLogEntry( logData )#" />
			</cflock>
			
			<cfreturn true />
			
			<cfcatch><cfset this.error(cfcatch) /></cfcatch>
		</cftry>
		
		<cfreturn false />
	</cffunction>
	
	<cffunction name="formatTime" access="private" output="false" returntype="string">
		<cfargument name="time" type="string" required="true" />
		<cfif isDate( time )><cfreturn getHTTPTimeString( time ) /></cfif>
		<cfreturn "" />
	</cffunction>
	
	<cffunction name="formatHeaders" access="private" output="false" returntype="string">
		<cfargument name="headers" type="string" required="true" />
		<cfreturn formatLogEntry( listChangeDelims( ucase(headers) , instance.logDelimiter , "," ) ) />
	</cffunction>
	
	<cffunction name="formatLogEntry" access="private" output="false" returntype="string">
		<cfargument name="logData" type="any" required="true" />
		<cfset var quoted = instance.logQuoteElements />
		
		<cfif isArray(logData)><cfset logData = ArrayToList( logData , instance.logDelimiter ) /></cfif>
		
		<cfif quoted is not "NONE">
			<cfset logData = listQualify( logData , instance.logQualifier , instance.logDelimiter, instance.logQuoteElements, true ) />
		</cfif>
		
		<cfreturn logData />
	</cffunction>
	
	<cffunction name="checkLogRotation" access="private" output="false" returntype="boolean">
		<cfargument name="logPath" type="string" required="true" />
		<cfargument name="settings" type="struct" required="true" />
		<cfset var loc = StructNew() />
		<cfset loc.rotate = false />
		<cfset loc.path = getLogDir() & "/" & logPath />
		
		<cfif settings.days or settings.size>
			<cflock name="#loc.path#" type="exclusive" timeout="10">
				<cfif fileExists(loc.path)>
					<cfset loc.rotate = (settings.size and getLogSize(loc.path) gte settings.size) 
							or (settings.days and getLogDays(loc.path) gte settings.days) />
					
					<cfif loc.rotate>
						<cfset rotateLog( loc.path , settings.keep ) />
					</cfif>
				</cfif>
			</cflock>
		</cfif>
		
		<cfreturn loc.rotate />
	</cffunction>
	
	<cffunction name="getLogSize" access="private" output="false" returntype="numeric">
		<cfargument name="logPath" type="string" required="true" />
		<cfreturn CreateObject("java", "java.io.File").init(logPath).length() />
	</cffunction>
	
	<cffunction name="getLogDays" access="private" output="false" returntype="numeric">
		<cfargument name="logPath" type="string" required="true" />
		<cfset var created = getFirstLogDate(logPath) />
		<cfif not isDate(created)><cfreturn 0 /></cfif>
		<cfreturn datediff( "d" , dateformat(created) , dateformat(now()) ) />
	</cffunction>
	
	<cffunction name="getFirstLogDate" access="private" output="false">
		<cfargument name="logPath" type="any" required="true" />
		<cfset var rex = "^\W*\w+,\s+(\d+\s+\w+\s+\d{4}).*$" />
		<cfset var f = fileOpen(logPath) />
		<cfset var lq = instance.logQualifier />
		<cfset var ld = instance.logDelimiter />
		<cfset var line = "" />
		
		<cfloop condition="not FileIsEOF(f)">
			<cfset line = fileReadLine(f) />
			<cfif refindnocase( rex , line )>
				<cfset line = rereplace( line , rex , "\1" ) />
				<cfif isDate(line)>
					<cfbreak />
				</cfif>
			</cfif>
		</cfloop>
		
		<cfset fileClose(f) />
		
		<cfreturn line />
	</cffunction>
	
	<cffunction name="rotateLog" access="private" output="false">
		<cfargument name="logPath" type="string" required="true" />
		<cfargument name="keep" type="numeric" required="true" />
		<cfset var fp = rotationPath( logPath , keep ) />
		<cfset var fp2 = "" />
		
		<cfif fileExists( fp )><cfset fileDelete( fp ) /></cfif>
		
		<cfloop condition="keep gt 1">
			<cfset fp2 = rotationPath( logPath , keep-1 ) />
			<cfif fileExists(fp2)>
				<cffile action="rename" source="#fp2#" destination="#fp#" />
			</cfif>
			<cfset fp = fp2 />
			<cfset keep -= 1 />
		</cfloop>
		
		<cffile action="rename" source="#logPath#" destination="#fp#" />
	</cffunction>
	
	<cffunction name="rotationPath" access="private" output="false" returntype="string">
		<cfargument name="logPath" type="string" required="true" />
		<cfargument name="num" type="numeric" required="true" />
		<cfreturn rereplace( logPath , "(\.\w+)$", ".#num#\1" ) />
	</cffunction>
	
	<cffunction name="getLogPath" access="private" output="false" returntype="string">
		<cfargument name="logType" type="string" required="true" />
		<cfreturn logType & "." & instance.logExt />
	</cffunction>
	
	<cffunction name="getLogDir" access="public" output="false" returntype="string">
		<cfreturn getDirectoryFromPath(getConfig().getFingerprint()) & instance.logPath />
	</cffunction>
	
</cfcomponent>