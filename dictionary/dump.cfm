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
</cfscript>

<cfscript>
// i insert the Dump statement
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfdump var=""" & arguments.Command.XMLAttributes.Var & """ label=""" & LocalVars.Attributes.Label & """ expand=""" & LocalVars.Attributes.Expand & """>" & NewLine));
</cfscript>