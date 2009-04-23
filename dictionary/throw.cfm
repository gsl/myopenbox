<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "type")){
	LocalVars.Attributes.Type=arguments.Command.XMLAttributes.type;
} else {
	LocalVars.Attributes.Type="";
}
if(StructKeyExists(arguments.Command.XMLAttributes, "message")){
	LocalVars.Attributes.Message=arguments.Command.XMLAttributes.message;
} else {
	LocalVars.Attributes.Message="";
}
</cfscript>

<cfscript>
// i insert the Dump statement
GeneratedContent.Append(JavaCast("string", Indent(arguments.Level) & "<" & "cfthrow type=""" & LocalVars.Attributes.Type & """ Message=""" & LocalVars.Attributes.Message & """>" & NewLine));
</cfscript>