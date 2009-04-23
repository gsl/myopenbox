<cfscript>
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfdefaultcase>" & NewLine));
// i render the subcommands
GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfdefaultcase>" & NewLine));
</cfscript>