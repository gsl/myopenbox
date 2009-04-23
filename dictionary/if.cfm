<cfscript>
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif " & arguments.Command.XMLAttributes.condition & ">" & NewLine));
GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
</cfscript>