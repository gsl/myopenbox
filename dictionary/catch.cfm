<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "type")){
	LocalVars.Attributes.Type=arguments.Command.XMLAttributes.type;
} else {
	LocalVars.Attributes.Type="Any";
}
</cfscript>

<cfscript>
GeneratedContent.Append(JavaCast("string", Indent(arguments.Level) & "<" & "cfcatch type=""" & LocalVars.Attributes.Type & """>" & NewLine));
GeneratedContent.Append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.Append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfcatch>" & NewLine));
</cfscript>