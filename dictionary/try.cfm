<cfscript>
GeneratedContent.Append(JavaCast("string", Indent(arguments.Level) & "<" & "cftry>" & NewLine));
GeneratedContent.Append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.Append(JavaCast("string", Indent(arguments.Level) & "<" & "/cftry>" & NewLine));
</cfscript>