<cfscript>
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
} else {
	LocalVars.Attributes.OptPath="";
}

if(StructKeyExists(arguments.Command.XMLAttributes, "required")){
	LocalVars.Attributes.Required=arguments.Command.XMLAttributes.required;
} else {
	LocalVars.Attributes.Required=true;
}
</cfscript>

<cfscript>

if(Len(LocalVars.Attributes.OptPath) GT 0){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif FileExists(ExpandPath(""" & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(arguments.Command.XMLAttributes.template) & """))>" & NewLine));
	// i include the template
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(arguments.Command.XMLAttributes.template) & """></cfoutput>" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
	arguments.Level=arguments.Level+1;
}

// i check if the file exists before including the file if Required is False (w/out Cache.RootPath because ExpandPath is calculating from the base template)
if(NOT LocalVars.Attributes.Required){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif FileExists(ExpandPath(""" & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(arguments.Command.XMLAttributes.template) & """))>" & NewLine));
	arguments.Level=arguments.Level+1;
}

// i include the template
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(arguments.Command.XMLAttributes.template) & """></cfoutput>" & NewLine));

// i insert the closing cfif tag if template is not required
if(NOT LocalVars.Attributes.Required){
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
}


if(Len(LocalVars.Attributes.OptPath) GT 0){
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
}
</cfscript>