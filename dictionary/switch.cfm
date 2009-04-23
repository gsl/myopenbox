<cfscript>
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfswitch expression=""" & arguments.Command.XMLAttributes.expression & """>" & NewLine));
// i render the subcommands
GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfswitch>" & NewLine));
</cfscript>