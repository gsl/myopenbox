<cfscript>
GeneratedContent.append(JavaCast("string", Indent(arguments.Level - 1) & "<" & "cfelseif " & arguments.Command.XMLAttributes.condition & ">" & NewLine));
GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level)));
</cfscript>