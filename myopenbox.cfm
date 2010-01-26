<cfsetting enablecfoutputonly="yes">
<!--- 
/////////////////////////////////// MYOPENBOX LICENSE (BETA) //////////////////////////////////
// MyOpenbox authored by Tyler Silcox.
// Please send all questions, comments, and suggestions to MyOpenbox@gmail.com.
// Made in the U.S.A.
///////////////////////////////////////////////////////////////////////////////////////////////
--->

<cfif NOT StructKeyExists(application, "MyOpenbox")
	OR application.MyOpenbox.IsFWReinit()>
	<cflock name="myopenbox_create_#hash(getBaseTemplatePath())#" type="exclusive" timeout="5" throwontimeout="true">
		<cfif NOT StructKeyExists(application, "MyOpenbox")
			OR application.MyOpenbox.IsFWReinit()>
			<cfset StructDelete(application, "MyOpenbox")>
			<cfset application.MyOpenbox=CreateObject("component", "myopenbox").Init()>
		</cfif>
	</cflock>
</cfif>

<cfscript>
// i run|configure MyOpenbox
application.MyOpenbox.RunMyOpenbox();

// i create the attributes "scope" and determine the value of the target FuseAction
attributes=application.MyOpenbox.SetAttributes(variables, GetBaseTagList());
</cfscript>

<!--- i apply application Routes --->
<cfif StructKeyExists(application.MyOpenbox, "Routes") AND NOT IsDefined("ThisTag")>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/routes.cfm">
	<cfset StructAppend(attributes, application.MyOpenbox.Routes.findRoute(Replace(cgi.Path_Info, GetDirectoryFromPath(cgi.Script_Name), "")), false) />
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
<cfinclude template="udf.youropenbox.cfm">
<cfinclude template="act.youropenbox.cfm" />

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
<cfif
	StructKeyExists(application.Myopenbox.Circuits, ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))
	AND StructKeyExists(application.Myopenbox.Circuits[ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], ".")].Fuseactions, ListLast(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))
>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/fuseaction.#LCase(attributes[application.MyOpenbox.Parameters.FuseActionVariable])#.cfm">
</cfif>

<!--- i include the PostProcess Phase --->
<cfif StructKeyExists(application.MyOpenbox.Phases, "PostProcess")>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/phase.postprocess.cfm">
</cfif>

<cfsetting enablecfoutputonly="no">