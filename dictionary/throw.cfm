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
if(StructKeyExists(arguments.Command.XMLAttributes, "detail")){
	LocalVars.Attributes.Detail=arguments.Command.XMLAttributes.detail;
} else {
	LocalVars.Attributes.Detail="";
}
if(StructKeyExists(arguments.Command.XMLAttributes, "errorcode")){
	LocalVars.Attributes.ErrorCode=arguments.Command.XMLAttributes.errorcode;
} else {
	LocalVars.Attributes.ErrorCode="";
}
</cfscript>

<cfscript>
// i insert the Dump statement
GeneratedContent.Append(JavaCast("string", Indent(arguments.Level) & "<" & "cfthrow type=""" & LocalVars.Attributes.Type & """ message=""" & LocalVars.Attributes.Message & """ Detail=""" & LocalVars.Attributes.Detail & """ errorcode=""" & LocalVars.Attributes.ErrorCode & """>" & NewLine));
</cfscript>