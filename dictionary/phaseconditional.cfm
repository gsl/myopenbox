<cfif arguments.Command.XMLName EQ "AndThen">
	<cfset GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif YourOpenbox.ThisPhase.AndThen EQ 1>" & NewLine))>
<cfelseif arguments.Command.XMLName EQ "NoAndThen">
	<cfset GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif YourOpenbox.ThisPhase.AndThen EQ 0>" & NewLine))>
</cfif>

<cfscript>
// i render the subcommands
GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
</cfscript>