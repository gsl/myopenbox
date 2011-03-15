<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "label")){
	LocalVars.Attributes.Label=arguments.Command.XMLAttributes.label;
} else {
	LocalVars.Attributes.Label="";
}
if(StructKeyExists(arguments.Command.XMLAttributes, "expand")){
	LocalVars.Attributes.Expand=arguments.Command.XMLAttributes.expand;
} else {
	LocalVars.Attributes.Expand=true;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "metainfo") AND IsBoolean(arguments.Command.XMLAttributes.metainfo)){
	LocalVars.Attributes.MetaInfo=arguments.Command.XMLAttributes.metainfo;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "show") AND Len(arguments.Command.XMLAttributes.show)){
	LocalVars.Attributes.Show=arguments.Command.XMLAttributes.show;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "hide") AND Len(arguments.Command.XMLAttributes.hide)){
	LocalVars.Attributes.Hide=arguments.Command.XMLAttributes.hide;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "showudfs") AND IsBoolean(arguments.Command.XMLAttributes.showudfs)){
	LocalVars.Attributes.ShowUdfs=arguments.Command.XMLAttributes.showudfs;
}
</cfscript>

<cfscript>
// i insert the Dump statement
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfdump var=""" & arguments.Command.XMLAttributes.Var & """ label=""" & LocalVars.Attributes.Label & """ expand=""" & LocalVars.Attributes.Expand & """"));
if(StructKeyExists(LocalVars.Attributes, "MetaInfo")){
	GeneratedContent.append(JavaCast("string", " metainfo=""" & LocalVars.Attributes.MetaInfo & """"));
}
if(StructKeyExists(LocalVars.Attributes, "Show")){
	GeneratedContent.append(JavaCast("string", " show=""" & LocalVars.Attributes.Show & """"));
}
if(StructKeyExists(LocalVars.Attributes, "Hide")){
	GeneratedContent.append(JavaCast("string", " hide=""" & LocalVars.Attributes.Hide & """"));
}
if(StructKeyExists(LocalVars.Attributes, "ShowUdfs")){
	GeneratedContent.append(JavaCast("string", " showudfs=""" & LocalVars.Attributes.ShowUdfs & """"));
}
GeneratedContent.append(JavaCast("string", " />" & NewLine));
</cfscript>