<!--- 
	*** DO NOT MODIFY THIS FILE *** 
	*** DO NOT MODIFY THIS FILE *** 
	*** DO NOT MODIFY THIS FILE *** 
	
	To customize your CacheBox installation, create a config.cfc in this directory like this: 
	<cfcomponent extends="defaultconfig">
		... custom settings here ... 
	</cfcomponent>
--->

<cfcomponent output="false" hint="I provide the default Application.cfc settings for a CacheBox Management Application">
	<cfinclude template="instance.cfm" />
	<cfinclude template="getstruct.cfm" />
	<cfset instance.passwordfile = instance.configdir & "password.cfm" />
	
	<cffunction name="getApplicationSettings" access="public" output="false" 
	hint="I set application-specific settings for the reporting and management application, such as mappings and timeouts">
		<cfset var result = structNew() />
		<cfset result.mappings["/cachebox"] = getDirectoryFromPath(getCurrentTemplatePath()) />
		<cfset result.name = lcase(right(rereplace(rereplace(result.mappings["/cachebox"],"[[:punct:]]$",""),"[[:punct:][:space:]]+","_","ALL"),65)) />
		<cfset result.applicationTimeout = CreateTimeSpan(0,0,20,0) />
		<cfset result.sessionTimeout = CreateTimeSpan(0,0,20,0) />
		<cfset result.clientmanagement = false />
		<cfset result.sessionmanagement = true />
		<cfreturn result />
	</cffunction>
	
	<cffunction name="onApplicationStart" access="public">
	</cffunction>
	
	<cffunction name="onApplicationEnd" access="public" output="false">
		<cfargument name="applicationScope" type="struct" required="true" />
	</cffunction>
	
	<cffunction name="onRequestStart" access="public">
		<cfargument name="targetPage" type="string" required="true" />
		<cfset setEncoding("form","UTF-8") />
		<cfset setEncoding("url","UTF-8") />
		
		<cfif refindnocase("\.cfm$",cgi.script_name) 
		and comparenocase(getFileFromPath(targetPage),getFileFromPath(instance.pollingURL))>
			<!--- 
				if this is not a webservice request and it's not a cache monitoring request, 
				then someone is trying to access the management application - load it and apply session security
			--->
			<cfset setFrontController() />
			<cfset applyRequestSecurity(targetPage) />
			<cfset request.pageEvents = getStruct( onload = "window.focus();" ) />
		</cfif>
	</cffunction>
	
	<cffunction name="onRequestEnd" access="public">
	</cffunction>
	
	<cffunction name="onSessionStart" access="public">
		<cfset session.authenticated = false />
	</cffunction>
	
	<cffunction name="onSessionEnd" access="public" output="false">
		<cfargument name="applicationScope" type="struct" required="true" />
		<cfargument name="sessionScope" type="struct" required="true" />
	</cffunction>
	
	<cffunction name="applyRequestSecurity" access="private" output="true" 
	hint="If the user isn't logged in, I show them the login form to prevent unauthorized access">
		<cfargument name="targetPage" type="string" required="true" />
		
		<cfif not session.authenticated>
			<cfset showLogin(targetPage) />
		</cfif>
	</cffunction>
	
	<cffunction name="isPasswordSet" access="public" output="false" returntype="boolean">
		<cfreturn FileExists(instance.passwordfile) />
	</cffunction>
	
	<cffunction name="formatPassword" access="private" output="false">
		<cfargument name="password" type="string" required="true" />
		<cfreturn hash(trim(password)) />
	</cffunction>
	
	<cffunction name="savePassword" access="public" output="false">
		<cfargument name="password" type="string" required="true" />
		<cfif len(trim(password))>
			<cffile action="write" charset="UTF-8" addnewline="false" 
				file="#instance.passwordfile#" output="#formatPassword(arguments.password)#" />
		<cfelse>
			<cfthrow type="CacheBox.Password.Required" message="the CacheBox Service must have a password" />
		</cfif>
	</cffunction>
	
	<cffunction name="readPassword" access="private" output="false">
		<cfset var result = "" />
		<cffile action="read" file="#instance.passwordfile#" variable="result" charset="UTF-8" />
		<cfreturn trim(result) />
	</cffunction>
	
	<cffunction name="authenticate" access="private" output="false" returntype="boolean">
		<cfargument name="password" type="string" required="true" />
		<cfif not len(trim(arguments.password))>
			<cfreturn false />
		<cfelseif isPasswordSet()>
			<cfreturn iif(compare(formatPassword(arguments.password),readPassword()),false,true) />
		<cfelse>
			<cfset savePassword(arguments.password) />
			<cfreturn true />
		</cfif>
	</cffunction>
	
	<cffunction name="showLogin" access="private" output="true">
		<cfargument name="targetPage" type="string" required="true" />
		<cfset var controller = request.frontController />
		<cfset var loginform = "" />
		<cfset var rc = 0 />
		<cfset var x = 0 />
		
		<cfset rc = duplicate(url) />
		<cfset structAppend(rc,form,true) />
		<cfparam name="rc.event" type="string" default="home" />
		<cfparam name="rc.password" type="string" default="" />
		
		<!--- check to see if the user supplied a password --->
		<cfset session.authenticated = authenticate(rc.password)>
		<!--- if the user supplied the correct password, continue on with the request --->
		<cfif session.authenticated>
			<cfreturn />
		</cfif>
		
		<cfsavecontent variable="loginform">
			<cfoutput>
				<div id="login">
					<cfset Controller.warn("Invalid Password.",len(trim(rc.password))) />
					<cfset Controller.confirm("Choose a password for the CacheBox Management Application.",not isPasswordSet()) />
					
					<form name="frmLogin" action="#cgi.script_name#?#cgi.query_string#" method="post">
						<div>Password: <input type="password" name="password" tabindex="1" /></div>
						<div><button type="submit">Log In</button></div>
						
						<!--- allow form variables to pass through to the following page --->
						<cfloop item="x" collection="#form#">
							<cfif x is not "password">
								<input type="hidden" name="#x#" value="#htmleditformat(form[x])#" />
							</cfif>
						</cfloop>
					</form>
				</div>
			</cfoutput>
		</cfsavecontent>
		
		<cfset Controller.showLayout("login", loginForm, getStruct( onload = "document.forms.frmLogin.password.focus();" )) />
		
		<cfabort />
	</cffunction>
	
	<cffunction name="setFrontController" access="private" output="false" hint="I create the front-controller for the reporting and management application">
		<cfset request.frontController = CreateObject("component","frontcontroller").init(this) />
	</cffunction>
		
</cfcomponent>

