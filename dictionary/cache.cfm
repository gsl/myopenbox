<cfscript>
if(application.MyOpenbox.Parameters.EnableCachebox AND StructKeyExists(arguments.Command.XMLAttributes, "cache.name")){
	LocalVars.Attributes.IsCache=true;
	LocalVars.Attributes.Cache=StructNew();

	LocalVars.Attributes.Cache.Name=arguments.Command.XMLAttributes["cache.name"];
	
	if(StructKeyExists(arguments.Command.XMLAttributes, "cache.agent")){
		LocalVars.Attributes.Cache.Agent=arguments.Command.XMLAttributes["cache.agent"];
	} else {
		LocalVars.Attributes.Cache.Agent="Default";
	}

	LocalVars.Type.IsSingleVariable=true;
	if(StructKeyExists(arguments.Command.XMLAttributes, "cache.variable")){
		LocalVars.Attributes.Cache.Variable=arguments.Command.XMLAttributes["cache.variable"];
	} else {
		LocalVars.Attributes.Cache.Variable="";
	}
	if(ListLen(LocalVars.Attributes.Cache.Variable) GT 1) {
		LocalVars.Type.IsSingleVariable=false;
		LocalVars.Attributes.Cache.VariableStruct="";
		for(LocalVars.Item in ListToArray(LocalVars.Attributes.Cache.Variable)){
			LocalVars.Attributes.Cache.VariableStruct=LocalVars.Attributes.Cache.VariableStruct & "," & LocalVars.Item & "=" & LocalVars.Item;
		}
		LocalVars.Attributes.Cache.VariableStruct="{" & Right(LocalVars.Attributes.Cache.VariableStruct, Len(LocalVars.Attributes.Cache.VariableStruct)-1) & "}";
	}

	LocalVars.Attributes.Cache.Arguments=StructNew();
	for(LocalVars.i IN arguments.Command.XMLAttributes){
		LocalVars.SearchFor="cache.arguments.";
		if(Len(LocalVars.i) GT Len(LocalVars.SearchFor) AND Left(LocalVars.i, Len(LocalVars.SearchFor)) EQ LocalVars.SearchFor){
			LocalVars.Attributes.Cache.Arguments[Right(LocalVars.i, Len(LocalVars.i)-Len(LocalVars.SearchFor))]=arguments.Command.XMLAttributes[LocalVars.i];
		}
	}

	if(StructKeyExists(arguments.Command.XMLAttributes, "cache.condition")){
		LocalVars.Attributes.Cache.Condition=arguments.Command.XMLAttributes["cache.condition"];
	} else {
		LocalVars.Attributes.Cache.Condition="";
	}
} else {
	LocalVars.Attributes.IsCache=false;
}

// i set defaults for Type
LocalVars.Type.IsWrapper=false;
// if this Content call is a wrapper for another verb, i set Type modifers
if(ListLen(arguments.Command.XMLName, ".") GT 1){
	LocalVars.Type.IsWrapper=true;
	LocalVars.CallCommands.XMLName=ListGetAt(arguments.Command.XMLName, 2, ".");
	LocalVars.CallCommands.XMLAttributes=arguments.Command.XMLAttributes;
	if(StructKeyExists(arguments.Command, "XMLChildren")) {
		LocalVars.CallCommands.XMLChildren=arguments.Command.XMLChildren;
	}
	if(StructKeyExists(arguments.Command, "XMLText")) {
		LocalVars.CallCommands.XMLText=arguments.Command.XMLText;
	}
}
</cfscript>

<cfscript>
if(LocalVars.Attributes.IsCache) {
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset YourOpenbox.ThisVerb.CacheEnabled=(NOT StructKeyExists(url, 'no-cache')"));
	if(Len(LocalVars.Attributes.Cache.Condition) GT 0) {
		GeneratedContent.append(JavaCast("string", " AND (" & LocalVars.Attributes.Cache.Condition & ")"));
	}
	GeneratedContent.append(JavaCast("string", ") />" & NewLine));
	if(NOT StructIsEmpty(LocalVars.Attributes.Cache.Arguments)){
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset YourOpenbox.ThisVerb.CacheArgs=StructNew() />" & NewLine));
		for(LocalVars.i IN LocalVars.Attributes.Cache.Arguments){
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset YourOpenbox.ThisVerb.CacheArgs[""" & LocalVars.i & """]=""" & LocalVars.Attributes.Cache.Arguments[LocalVars.i] & """ />" & NewLine));
		}
	}
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif YourOpenbox.ThisVerb.CacheEnabled>" & NewLine));
	arguments.Level=arguments.Level+1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset YourOpenbox.ThisVerb.CacheTimer=GetTickCount() />" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset YourOpenbox.ThisVerb.CheckCache=application.MyOpenbox.GetCacheAgent(""" & LocalVars.Attributes.Cache.Agent & """).fetch(""" & LocalVars.Attributes.Cache.Name & """"));
		if(NOT StructIsEmpty(LocalVars.Attributes.Cache.Arguments)){
			GeneratedContent.append(JavaCast("string", ", YourOpenbox.ThisVerb.CacheArgs"));
		}
	GeneratedContent.append(JavaCast("string", ") />" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset YourOpenbox.ThisVerb.CacheTimer=GetTickCount()-YourOpenbox.ThisVerb.CacheTimer />" & NewLine));
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif NOT YourOpenbox.ThisVerb.CacheEnabled OR YourOpenbox.ThisVerb.CheckCache.Status>" & NewLine));
	arguments.Level=arguments.Level+1;
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif YourOpenbox.ThisVerb.CacheEnabled>" & NewLine));
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cftrace text=""Cache miss " & LocalVars.Attributes.Cache.Agent & ":" & LocalVars.Attributes.Cache.Name & " in ##NumberFormat(YourOpenbox.ThisVerb.CacheTimer, ""9,999"")##ms"" />" & NewLine));
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));

	if(Len(LocalVars.Attributes.Cache.Variable) EQ 0) {
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfsavecontent variable=""YourOpenbox.ThisVerb.Content"">" & NewLine));
	}
}

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _PushToVerbStack() />" & NewLine));

if(LocalVars.Type.IsWrapper){
	// ...i render the "wrapped" tag
	LocalVars.temp=RenderCommand(arguments.Type, LocalVars.CallCommands, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1);
	GeneratedContent.append(JavaCast("string", LocalVars.temp));
// else
} else {
	// ...i render the subcommand(s)
	LocalVars.temp=RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1);
	GeneratedContent.append(JavaCast("string", LocalVars.temp));
}
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _PopVerbStack() />" & NewLine));


if(LocalVars.Attributes.IsCache) {
	if(Len(LocalVars.Attributes.Cache.Variable) EQ 0) {
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfsavecontent>" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfoutput>" & "##YourOpenbox.ThisVerb.Content##" & "<" & "/cfoutput>" & NewLine));
	}
	if(Len(LocalVars.Attributes.Cache.Condition) GT 0) {
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif " & LocalVars.Attributes.Cache.Condition & ">" & NewLine));
		arguments.Level=arguments.Level+1;
	}
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset application.MyOpenbox.GetCacheAgent(""" & LocalVars.Attributes.Cache.Agent & """).store(""" & LocalVars.Attributes.Cache.Name & """"));
	if(Len(LocalVars.Attributes.Cache.Variable) GT 0) {
		if(LocalVars.Type.IsSingleVariable) {
			GeneratedContent.append(JavaCast("string", ", " & LocalVars.Attributes.Cache.Variable));
		} else {
			GeneratedContent.append(JavaCast("string", ", " & LocalVars.Attributes.Cache.VariableStruct));
		}
	} else {
		GeneratedContent.append(JavaCast("string", ", YourOpenbox.ThisVerb.Content"));
	}
	if(NOT StructIsEmpty(LocalVars.Attributes.Cache.Arguments)){
		GeneratedContent.append(JavaCast("string", ", YourOpenbox.ThisVerb.CacheArgs"));
	}
	GeneratedContent.append(JavaCast("string", ") />" & NewLine));
	if(Len(LocalVars.Attributes.Cache.Condition) GT 0) {
		arguments.Level=arguments.Level-1;
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
	}
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
	arguments.Level=arguments.Level+1;
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cftrace text=""Cache hit " & LocalVars.Attributes.Cache.Agent & ":" & LocalVars.Attributes.Cache.Name & " in ##NumberFormat(YourOpenbox.ThisVerb.CacheTimer, ""9,999"")##ms"" />" & NewLine));
	if(Len(LocalVars.Attributes.Cache.Variable) GT 0) {
		if(LocalVars.Type.IsSingleVariable) {
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & LocalVars.Attributes.Cache.Variable & "=YourOpenbox.ThisVerb.CheckCache.Content" & "/>" & NewLine));
		} else {
			for(LocalVars.Item in ListToArray(LocalVars.Attributes.Cache.Variable)){
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & LocalVars.Item & "=YourOpenbox.ThisVerb.CheckCache.Content." & LocalVars.Item & " />" & NewLine));
			}
		}
	} else {
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfoutput>" & "##YourOpenbox.ThisVerb.CheckCache.Content##" & "<" & "/cfoutput>" & NewLine));
	}
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
}
</cfscript>