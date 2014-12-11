<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "template")){
	LocalVars.Attributes.Template=arguments.Command.XMLAttributes.template;
} else {
	LocalVars.Attributes.Template="";
}

if(StructKeyExists(arguments.Command.XMLAttributes, "fallback")){
	LocalVars.Attributes.Fallback=arguments.Command.XMLAttributes.fallback;
} else {
	LocalVars.Attributes.Fallback="";
}

if(StructKeyExists(arguments.Command.XMLAttributes, "path")){
	LocalVars.Attributes.Path=arguments.Command.XMLAttributes.path;
} else if(NOT StructIsEmpty(arguments.Circuit)){
	LocalVars.Attributes.Path=arguments.Circuit.DirectoryPath;
} else {
	LocalVars.Attributes.Path="";
}

if(StructKeyExists(arguments.Command.XMLAttributes, "optpath")){
	LocalVars.Attributes.OptPath=arguments.Command.XMLAttributes.optpath;
} else if(NOT StructIsEmpty(arguments.Circuit) AND StructKeyExists(arguments.Circuit, "OptPath")){
	LocalVars.Attributes.OptPath=arguments.Circuit.OptPath;
} else if (NOT StructIsEmpty(arguments.Circuit) AND StructKeyExists(application.MyOpenbox.Parameters, "OptPath") AND Len(application.MyOpenbox.Parameters.OptPath) GT 0) {
	LocalVars.Attributes.OptPath=application.MyOpenbox.Parameters.OptPath; 
} else {
	LocalVars.Attributes.OptPath="";
}

if(StructKeyExists(arguments.Command.XMLAttributes, "required")){
	LocalVars.Attributes.Required=arguments.Command.XMLAttributes.required;
} else {
	LocalVars.Attributes.Required=true;
}

if(application.MyOpenbox.Parameters.EnableCachebox AND StructKeyExists(arguments.Command.XMLAttributes, "cache.name")){
	LocalVars.Attributes.IsCache=true;
	LocalVars.Attributes.Cache=StructNew();
	LocalVars.Attributes.Cache.Name=arguments.Command.XMLAttributes["cache.name"];
	if(StructKeyExists(arguments.Command.XMLAttributes, "cache.agent")){
		LocalVars.Attributes.Cache.Agent=arguments.Command.XMLAttributes["cache.agent"];
	} else {
		LocalVars.Attributes.Cache.Agent="Default";
	}
	if(StructKeyExists(arguments.Command.XMLAttributes, "cache.variable")){
		LocalVars.Attributes.Cache.Variable=arguments.Command.XMLAttributes["cache.variable"];
	} else {
		LocalVars.Attributes.Cache.Variable="";
	}
	LocalVars.Attributes.Cache.Arguments=StructNew();
	for(LocalVars.i IN arguments.Command.XMLAttributes){
		LocalVars.SearchFor="cache.arguments.";
		if(Len(LocalVars.i) GT Len(LocalVars.SearchFor) AND Left(LocalVars.i, Len(LocalVars.SearchFor)) EQ LocalVars.SearchFor){
			LocalVars.Attributes.Cache.Arguments[Right(LocalVars.i, Len(LocalVars.i)-Len(LocalVars.SearchFor))]=arguments.Command.XMLAttributes[LocalVars.i];
		}
	}
} else {
	LocalVars.Attributes.IsCache=false;
}
</cfscript>

<cfscript>

if(LocalVars.Attributes.IsCache) {
	if(NOT StructIsEmpty(LocalVars.Attributes.Cache.Arguments)){
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _CacheArgs=StructNew() />" & NewLine));
		for(LocalVars.i IN LocalVars.Attributes.Cache.Arguments){
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _CacheArgs[""" & LocalVars.i & """]=""" & LocalVars.Attributes.Cache.Arguments[LocalVars.i] & """ />" & NewLine));
		}
	}
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _CheckCache=application.MyOpenbox.GetCacheAgent(""" & LocalVars.Attributes.Cache.Agent & """).fetch(""" & LocalVars.Attributes.Cache.Name & """"));
		if(NOT StructIsEmpty(LocalVars.Attributes.Cache.Arguments)){
			GeneratedContent.append(JavaCast("string", ", _CacheArgs"));
		}
	GeneratedContent.append(JavaCast("string", ") />" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif StructKeyExists(url, 'no-cache') OR _CheckCache.Status>" & NewLine));
	arguments.Level=arguments.Level+1;
}

if(Len(LocalVars.Attributes.OptPath) GT 0){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif FileExists(ExpandPath(""" & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) & """))>" & NewLine));
	// i include the template
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) & """></cfoutput>" & NewLine));
	if(Len(LocalVars.Attributes.Fallback) GT 0){
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelseif FileExists(ExpandPath(""" & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) & """))>" & NewLine));
	// i include the template
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) & """></cfoutput>" & NewLine));
	
	}
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
	arguments.Level=arguments.Level+1;
}

// i check if the file exists before including the file if Required is False (w/out Cache.RootPath because ExpandPath is calculating from the base template)
if(NOT LocalVars.Attributes.Required OR Len(LocalVars.Attributes.Fallback) GT 0){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif FileExists(ExpandPath(""" & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) & """))>" & NewLine));
	arguments.Level=arguments.Level+1;
}

// i include the template
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) & """></cfoutput>" & NewLine));

if(Len(LocalVars.Attributes.Fallback) GT 0){
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
	arguments.Level=arguments.Level+1;
	
	if(NOT LocalVars.Attributes.Required){
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif FileExists(ExpandPath(""" & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) & """))>" & NewLine));
		arguments.Level=arguments.Level+1;
	}
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) & """></cfoutput>" & NewLine));
	
	if(NOT LocalVars.Attributes.Required){
		arguments.Level=arguments.Level-1;
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
	}
}

// i insert the closing cfif tag if template is not required
if(NOT LocalVars.Attributes.Required OR Len(LocalVars.Attributes.Fallback) GT 0){
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
}


if(Len(LocalVars.Attributes.OptPath) GT 0){
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
}

if(LocalVars.Attributes.IsCache) {
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset application.MyOpenbox.GetCacheAgent(""" & LocalVars.Attributes.Cache.Agent & """).store(""" & LocalVars.Attributes.Cache.Name & """, " & LocalVars.Attributes.Cache.Variable));
	if(NOT StructIsEmpty(LocalVars.Attributes.Cache.Arguments)){
		GeneratedContent.append(JavaCast("string", ", _CacheArgs"));
	}
	GeneratedContent.append(JavaCast("string", ") />" & NewLine));
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
	arguments.Level=arguments.Level+1;
	if(Len(LocalVars.Attributes.Cache.Variable) GT 0) {
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & LocalVars.Attributes.Cache.Variable & "=_CheckCache.Content" & "/>" & NewLine));
	} else {
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfoutput>" & "#_CheckCache.Content#" & "<" & "/cfoutput>" & NewLine));
	}
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
}
</cfscript>

<!---
<cfif StructKeyExists(arguments.Command.XMLAttributes, "template") AND arguments.Command.XMLAttributes["template"] EQ "qry.getnodecontents.cache">
	<cfdump var="#GeneratedContent.ToString()#" label="#GetCurrentTemplatePath()#" />
	<cfdump var="#LocalVars#" label="#GetCurrentTemplatePath()#" />
	<cfdump var="#arguments.Command.XMLAttributes#" label="#GetCurrentTemplatePath()#" /><cfabort />
</cfif>
--->
