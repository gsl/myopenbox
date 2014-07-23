<cfsetting enablecfoutputonly="yes">
<!--- 
/////////////////////////////////// MYOPENBOX LICENSE (BETA) //////////////////////////////////
// MyOpenbox authored by Tyler Silcox.
// Please send all questions, comments, and suggestions to MyOpenbox@gmail.com.
// Made in the U.S.A.
///////////////////////////////////////////////////////////////////////////////////////////////
--->

<cfif NOT StructKeyExists(application, "MyOpenbox")
	OR NOT StructKeyExists(application.MyOpenbox, "IsFWReinit")
	OR application.MyOpenbox.IsFWReinit()>
	<cflock name="myopenbox_create_#hash(getBaseTemplatePath())#" type="exclusive" timeout="5" throwontimeout="true">
		<cfif NOT StructKeyExists(application, "MyOpenbox")
			OR NOT StructKeyExists(application.MyOpenbox, "IsFWReinit")
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

<cfinclude template="act.actionstack.cfm">

<!--- i include the PreParse Phase --->
<cfif StructKeyExists(application.MyOpenbox.Phases, "PreParse")
	AND NOT StructKeyExists(application.MyOpenbox.Phases.Init[1], "IsInitialized")>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/#application.MyOpenbox.Parameters.CacheFilePrefix#phase.preparse.cfm">
</cfif>

<cfif application.MyOpenbox.Parameters.ProcessingMode EQ "Deployment" AND (application.MyOpenbox.IsFWReparse() OR application.MyOpenbox.IsFWReinit())>
	<cfset application.MyOpenbox.CreateAllCircuitAndFuseactionFiles() />
</cfif>

<!--- i apply application Routes --->
<cfif StructKeyExists(application.MyOpenbox, "Routes") AND NOT IsDefined("ThisTag")>
	<cfscript>
	variables.items = structnew();
	
	// Get path_info
	variables.items["pathInfo"] = cgi.path_info;
	
	variables.items["scriptName"] = trim(reReplacenocase(cgi.script_name,"[/\\]index\.cfm",""));
	
	// Clean ContextRoots
	if( len(getContextRoot()) ){
		//variables.items["pathInfo"] = replacenocase(variables.items["pathInfo"],getContextRoot(),"");
		variables.items["scriptName"] = replacenocase(variables.items["scriptName"],getContextRoot(),"");
	}	
	// Clean up the path_info from index.cfm and nested pathing
	variables.items["pathInfo"] = trim(reReplacenocase(variables.items["pathInfo"],"[/\\]index\.cfm",""));
	
	// Clean the scriptname from the pathinfo inccase this is a nested application
	if( len( variables.items["scriptName"] ) ){
		variables.items["pathInfo"] = replaceNocase(variables.items["pathInfo"], variables.items["scriptName"],'');
	}
	
	// clean 1 or > / in front of route in some cases, scope = one by default
	variables.items["pathInfo"] = reReplaceNoCase(variables.items["pathInfo"], "^/+", "/");
	</cfscript>
	
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/#application.MyOpenbox.Parameters.CacheFilePrefix#routes.cfm">
	<cfset variables._FoundRoute=application.MyOpenbox.Routes.findRoute(items["pathInfo"]) />
	<cfset StructAppend(attributes, variables._FoundRoute, false) />
	<cfif StructKeyExists(variables._FoundRoute, "Vars")>
		<cfloop from="1" to="#ArrayLen(variables._FoundRoute.Vars)#" step="1" index="_i">
			<cfif Len(variables._FoundRoute.Vars[_i].Scope) GT 0>
				<cfset setVariable(variables._FoundRoute.Vars[_i].Scope & "." & variables._FoundRoute.Vars[_i].Name, variables._FoundRoute.Vars[_i].Value) />
			<cfelse>
				<cfset setVariable("attributes." & variables._FoundRoute.Vars[_i].Name, variables._FoundRoute.Vars[_i].Value) />
			</cfif>
		</cfloop>
	</cfif>
	<cfset StructDelete(variables, "Items") />
	<cfset StructDelete(variables, "_FoundRoute") />
	<cfset StructDelete(variables, "_i") />
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

/*
try {
	formUtil = CreateObject('component', 'FormUtilities').init();
	formUtil.buildFormCollections(attributes);
} catch (Any e) {}
*/
</cfscript>

<cfscript>
// i validate and configure the target FuseAction
application.MyOpenbox.RunFuseAction(attributes[application.MyOpenbox.Parameters.FuseActionVariable]);
</cfscript>

<!--- i apply application Settings --->
<cfif StructKeyExists(application.MyOpenbox, "Settings")>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/#application.MyOpenbox.Parameters.CacheFilePrefix#settings.cfm">
	<cfset YourOpenbox["Settings"]=Duplicate(application.MyOpenbox.Settings)>
</cfif>

<!--- i include the YourOpenbox request file --->
<cfinclude template="act.youropenbox.cfm" />

<!--- i include the Init Phase --->
<cfif StructKeyExists(application.MyOpenbox.Phases, "Init") 
	AND NOT StructKeyExists(application.MyOpenbox.Phases.Init[1], "IsInitialized")>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/#application.MyOpenbox.Parameters.CacheFilePrefix#phase.init.cfm">
	<cfset application.MyOpenbox.Phases.Init[1]["IsInitialized"]=True>
</cfif>

<!--- i include the PreProcess Phase --->
<cfif StructKeyExists(application.MyOpenbox.Phases, "PreProcess")>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/#application.MyOpenbox.Parameters.CacheFilePrefix#phase.preprocess.cfm">
</cfif>

<!--- i include the TargetFuseAction file --->
<cfif
	StructKeyExists(application.Myopenbox.Circuits, ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))
	AND StructKeyExists(application.Myopenbox.Circuits[ListFirst(attributes[application.MyOpenbox.Parameters.FuseActionVariable], ".")].Fuseactions, ListLast(attributes[application.MyOpenbox.Parameters.FuseActionVariable], "."))
>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/#application.MyOpenbox.Parameters.CacheFilePrefix#fuseaction.#LCase(attributes[application.MyOpenbox.Parameters.FuseActionVariable])#.cfm">
</cfif>

<!--- i include the PostProcess Phase --->
<cfif StructKeyExists(application.MyOpenbox.Phases, "PostProcess")>
	<cfinclude template="#application.MyOpenbox.Parameters.Cache.Folder#/#application.MyOpenbox.Parameters.CacheFilePrefix#phase.postprocess.cfm">
</cfif>

<cfsetting enablecfoutputonly="no">