<cfcomponent>
	
	<cffunction name="onApplicationStart">
		<!--- i create the MyOpenbox object (if necessary) --->
		<cfset application.MyOpenbox=CreateObject("component", "myopenbox").Init()>
	</cffunction>
	
	<cffunction name="onRequestStart" 
		returnType="void">
		<cfargument name="targetPage" type="string" />
		
		<cfif (
				StructKeyExists(url, "FWReinit") AND IsDefined("application.Myopenbox.Parameters.FWReinit")
				AND url.FWReinit EQ application.Myopenbox.Parameters.FWReinit
			)>
				<cfset StructDelete(application, "MyOpenbox") />
				<cfset this.onApplicationStart() />
		</cfif>
		
		<cfif ListFirst(ListLast(cgi.Script_Name, "/"), ".") EQ "cfg"><cfabort></cfif>
		<cfset request.Context=GetPageContext().GetRequest() />
		
		<cfscript>
		// i run|configure MyOpenbox
		application.MyOpenbox.RunMyOpenbox();
		// i create the attributes "scope" and determine the value of the target FuseAction
		attributes=application.MyOpenbox.SetAttributes(variables, GetBaseTagList());
		</cfscript>
		
		<!--- i apply application Routes --->
		<cfif StructKeyExists(application.MyOpenbox, "Routes")>
			<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/routes.cfm">
			<cfset StructAppend(attributes, application.MyOpenbox.Routes.findRoute(cgi.Path_Info), false) />
		</cfif>
		
		<cfscript>
		if(StructKeyExists(attributes, "Circuit") AND StructKeyExists(attributes, "Fuse")) {
			attributes[application.MyOpenbox.Parameters.FuseActionVariable]=attributes.Circuit & "." & attributes.Fuse;
		} else if (StructKeyExists(attributes, "Circuit")) {
			attributes[application.MyOpenbox.Parameters.FuseActionVariable]=attributes.Circuit & "." & "Home";
		} else if(StructKeyExists(attributes, "Fuse")) {
			attributes[application.MyOpenbox.Parameters.FuseActionVariable]="Home" & "." & attributes.Fuse;
		}
		StructDelete(attributes, "Circuit");
		StructDelete(attributes, "Fuse");
		if(NOT StructKeyExists(attributes, application.MyOpenbox.Parameters.FuseActionVariable)){
			attributes[application.MyOpenbox.Parameters.FuseActionVariable]=application.MyOpenbox.Parameters.DefaultFuseAction;
		}
		
		try {
			formUtil = CreateObject('component', 'FormUtilities').init();
			formUtil.buildFormCollections(attributes);
		} catch (Any e) {}
		</cfscript>
		<!-- i  validate and configure the target FuseAction --->
		<cfset application.MyOpenbox.RunFuseAction(attributes[application.MyOpenbox.Parameters.FuseActionVariable]) />
<!---
		<cfif
			StructKeyExists(application.Myopenbox.Circuits, ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))
			AND StructKeyExists(application.Myopenbox.Circuits[ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], ".")].Fuseactions, ListLast(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))
		>
			<cfset application.MyOpenbox.RunFuseAction(attributes[application.MyOpenbox.Parameters.FuseActionVariable]) />
		</cfif>
--->
		
		<!--- i apply application Settings --->
		<cfif StructKeyExists(application.MyOpenbox, "Settings")>
			<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/settings.cfm">
			<cfset YourOpenbox["Settings"]=Duplicate(application.MyOpenbox.Settings)>
		</cfif>
		
		<!--- i include the YourOpenbox request file --->
		<cfinclude template="youropenbox.cfm">
		
		<!--- i include the Init Phase --->
		<cfif StructKeyExists(application.MyOpenbox.Phases, "Init") 
			AND NOT StructKeyExists(application.MyOpenbox.Phases.Init[1], "IsInitialized")>
			<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/phase.init.cfm">
			<cfset application.MyOpenbox.Phases.Init[1]["IsInitialized"]=True>
		</cfif>
		
		<!--- i include the PreProcess Phase --->
		<cfif StructKeyExists(application.MyOpenbox.Phases, "PreProcess")>
			<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/phase.preprocess.cfm">
		</cfif>
		
	</cffunction>
	
	<cffunction name="onRequest" 
		returnType="void">
		<cfargument name="targetPage" type="string" />
		
		<!--- i include the TargetFuseAction file --->
		<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/fuseaction.#LCase(attributes[application.MyOpenbox.Parameters.FuseActionVariable])#.cfm">
		
<!---
		<cfif
			StructKeyExists(application.Myopenbox.Circuits, ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))
			AND StructKeyExists(application.Myopenbox.Circuits[ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], ".")].Fuseactions, ListLast(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))
		>
			<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/fuseaction.#LCase(attributes[application.MyOpenbox.Parameters.FuseActionVariable])#.cfm">
		<cfelseif
			StructKeyExists(application.Myopenbox.Circuits, ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))
			AND StructKeyExists(application.MyOpenbox.Circuits[ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], ".")].Phases, "OnMissing")
		>
			<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/phase.onmissing.#LCase(ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))#.cfm">
		<cfelseif StructKeyExists(application.MyOpenbox.Phases, "OnMissing")>
			<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/phase.onmissing.cfm">
		<cfelse>
			<cfthrow type="MyOpenbox" message="The FuseAction supplied is invalid." detail="Please check the value of FuseAction to make sure it exists and/or is a valid fully qualified FuseAction." extendedinfo="FuseAction = #attributes[application.MyOpenbox.Parameters.FuseActionVariable]#" />
		</cfif>
--->
	</cffunction>
	
	<cffunction name="onRequestEnd" 
		returnType="void">
		<cfargument name="targetPage" type="string" />
		
		<!--- i include the PostProcess Phase --->
		<cfif StructKeyExists(application.MyOpenbox.Phases, "PostProcess")>
			<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/phase.postprocess.cfm">
		</cfif>
		
		<cfif IsDefined("onRequest") and IsDebugMode()>
			<cfset copyColdFireVariables() />
		</cfif>	
	</cffunction>
	
	<cffunction name="onSessionStart" 
		returnType="void">
				
		<cfif NOT StructKeyExists(cookie, "CFId")
			OR NOT StructKeyExists(cookie, "CFId")>
			<cfcookie name="CFId" value="#session.CFId#">
			<cfcookie name="CFToken" value="#session.CFToken#">
		</cfif>
		
	</cffunction>
	
	<cffunction name="copyColdFireVariables" returntype="void" output="no" access="private" hint="Copies variables scoped variables defined in the ColdFire variables tab to the request scope so they are available to the coldfire.cfm debugging template.">
		<cfset var varArray = [] />
		<cfset var requestData = GetHttpRequestData() />
		<cfset var i = 0 />
		
		<cfif structKeyExists(requestData.headers,"x-coldfire-variables")>
			<cfset varArray = DeserializeJSON(requestData.headers["x-coldfire-variables"]) />
			<cfset request.__coldFireVariableValues__ = {} />
		</cfif>
		
		<cfloop array="#varArray#" index="varName">
			<cfif CompareNoCase(Left(varName,10),"variables.") eq 0
				OR (Find(".",varName) eq 0 AND ListFindNoCase("application,cgi,client,cookie,form,request,server,url",varName) eq 0)>
				<cfif IsDefined(varName)>
					<cfset request.__coldFireVariableValues__[varName] = evaluate(varName) />
				</cfif>
			</cfif>		
		</cfloop>	
	
	</cffunction>
	
</cfcomponent>