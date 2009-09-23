<cfsetting enablecfoutputonly="yes">

<!--- 
/////////////////////////////////// MYOPENBOX LICENSE (BETA) //////////////////////////////////
// MyOpenbox authored by Tyler Silcox.
// Please send all questions, comments, and suggestions to MyOpenbox@gmail.com.
// Made in the U.S.A.
///////////////////////////////////////////////////////////////////////////////////////////////
--->

<cfif StructKeyExists(application, "MyOpenbox") 
	AND application.MyOpenbox.Version.BuildNumber NEQ '039'>
	<cfset StructDelete(application, "MyOpenbox")>
</cfif>

<!--- i create the MyOpenbox object (if necessary) --->
<cfif NOT StructKeyExists(application, "MyOpenbox")>
	<cflock name="#Hash(GetCurrentTemplatePath())#_CreateMyOpenbox" timeout="10">
		<cfif NOT StructKeyExists(application, "MyOpenbox")>
			<cflock name="#Hash(GetCurrentTemplatePath())#_CreateMyOpenbox_inner" timeout="10">
				<cfif NOT StructKeyExists(application, "MyOpenbox")>
					<cfset application.MyOpenbox=CreateObject("component", "myopenbox").Init()>
				</cfif>
			</cflock>
		</cfif>
	</cflock>
</cfif>

<cfscript>
// i run|configure MyOpenbox
application.MyOpenbox.RunMyOpenbox();

// i create the attributes "scope" and determine the value of the target FuseAction
attributes=application.MyOpenbox.SetAttributes(variables, GetBaseTagList());
</cfscript>

<cfscript>
// i validate and configure the target FuseAction
application.MyOpenbox.RunFuseAction(attributes[application.MyOpenbox.Parameters.FuseActionVariable]);
</cfscript>

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

<!--- i include the TargetFuseAction file --->
<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/fuseaction.#LCase(attributes[application.MyOpenbox.Parameters.FuseActionVariable])#.cfm">

<!--- i include the PostProcess Phase --->
<cfif StructKeyExists(application.MyOpenbox.Phases, "PostProcess")>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/phase.postprocess.cfm">
</cfif>

<cfsetting enablecfoutputonly="no">