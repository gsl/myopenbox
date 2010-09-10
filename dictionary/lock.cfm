<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "type")){
	LocalVars.Attributes.Type=arguments.Command.XMLAttributes.type;
} else {
	LocalVars.Attributes.Type="Exclusive";
}
if(StructKeyExists(arguments.Command.XMLAttributes, "timeout")){
	LocalVars.Attributes.Timeout=arguments.Command.XMLAttributes.timeout;
} else {
	LocalVars.Attributes.Timeout=10;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "throwontimeout")){
	LocalVars.Attributes.ThrowOnTimeout=arguments.Command.XMLAttributes.throwontimeout;
} else {
	LocalVars.Attributes.ThrowOnTimeout=true;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "condition")){
	LocalVars.Attributes.Condition=arguments.Command.XMLAttributes.condition;
} else {
	LocalVars.Attributes.Condition="";
}
</cfscript>

<cfscript>
if(Len(LocalVars.Attributes.Condition) GT 0) {
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif " & LocalVars.Attributes.Condition & ">" & NewLine));
	arguments.Level=arguments.Level+1;
}
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cflock name=""" & arguments.Command.XMLAttributes.name & """ type=""" & LocalVars.Attributes.Type & """ timeout=""" & LocalVars.Attributes.Timeout & """ throwontimeout=""" & LocalVars.Attributes.ThrowOnTimeout & """>" & NewLine));
arguments.Level=arguments.Level+1;

// i render the subcommands
if(Len(LocalVars.Attributes.Condition) GT 0) {
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif " & LocalVars.Attributes.Condition & ">" & NewLine));
	arguments.Level=arguments.Level+1;
}

GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level)));

if(Len(LocalVars.Attributes.Condition) GT 0) {
	arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
}
arguments.Level=arguments.Level-1;
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cflock>" & NewLine));
if(Len(LocalVars.Attributes.Condition) GT 0) {
arguments.Level=arguments.Level-1;
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
}
</cfscript>