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
</cfscript>

<cfscript>
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cflock name=""" & arguments.Command.XMLAttributes.name & """ type=""" & LocalVars.Attributes.Type & """ timeout=""" & LocalVars.Attributes.Timeout & """ throwontimeout=""" & LocalVars.Attributes.ThrowOnTimeout & """>" & NewLine));
// i render the subcommands
GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cflock>" & NewLine));
</cfscript>