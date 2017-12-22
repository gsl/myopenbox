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
</cfscript>

<cfscript>
if(Len(LocalVars.Attributes.OptPath) GT 0){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif application.MyOpenbox.FileExists(""" & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) & """)>" & NewLine));

	// i include the template
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cftimer label=""VERB:Include:" & this.Parameters.Cache.RootPath & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) &  """>" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) & """ /></cfoutput>" & NewLine));
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "/cftimer>" & NewLine));

	if(Len(LocalVars.Attributes.Fallback) GT 0){
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelseif application.MyOpenbox.FileExists(""" & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) & """)>" & NewLine));
	// i include the template
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cftimer label=""VERB:Include:" & this.Parameters.Cache.RootPath & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) &  """>" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.OptPath & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) & """ /></cfoutput>" & NewLine));
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "/cftimer>" & NewLine));
	
	}
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
	arguments.Level=arguments.Level+1;
}

// i check if the file exists before including the file if Required is False (w/out Cache.RootPath because ExpandPath is calculating from the base template)
if(NOT LocalVars.Attributes.Required OR Len(LocalVars.Attributes.Fallback) GT 0){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif application.MyOpenbox.FileExists(""" & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) & """)>" & NewLine));
	arguments.Level=arguments.Level+1;
}

// i include the template
// GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cftimer label=""VERB:Include:" & this.Parameters.Cache.RootPath & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) &  """>" & NewLine));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Template) & """ /></cfoutput>" & NewLine));
// GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cftimer>" & NewLine));

if(Len(LocalVars.Attributes.Fallback) GT 0){
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
	arguments.Level=arguments.Level+1;
	
	if(NOT LocalVars.Attributes.Required){
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif application.MyOpenbox.FileExists(""" & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) & """)>" & NewLine));
		arguments.Level=arguments.Level+1;
	}
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cftimer label=""VERB:Include:" & this.Parameters.Cache.RootPath & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) &  """>" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfoutput><cfinclude template=""" & this.Parameters.Cache.RootPath & LocalVars.Attributes.Path & this.AppendDefaultFileExtension(LocalVars.Attributes.Fallback) & """ /></cfoutput>" & NewLine));
	// GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cftimer>" & NewLine));
	
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
</cfscript>