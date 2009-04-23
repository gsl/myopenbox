<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "delimiters")){
	LocalVars.Attributes.Delimiters=arguments.Command.XMLAttributes.delimiters;
} else {
	LocalVars.Attributes.Delimiters=",";
}
</cfscript>

<cfscript>
GeneratedContent.append(Indent(arguments.Level) & "<" & "cfcase value=""" & arguments.Command.XMLAttributes.value & """ delimiters=""" & LocalVars.Attributes.Delimiters & """>" & NewLine);
// i render the subcommands
GeneratedContent.append(RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1));
GeneratedContent.append(Indent(arguments.Level) & "<" & "/cfcase>" & NewLine);
</cfscript>