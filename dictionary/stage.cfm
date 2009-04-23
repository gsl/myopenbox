<cfif arguments.Command.XMLName EQ "TargetCall">
	<cfset GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif YourOpenbox.IsTargetCall>" & NewLine))>
<cfelseif arguments.Command.XMLName EQ "SuperCall">
	<cfset GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif YourOpenbox.IsSuperCall>" & NewLine))>
<cfelseif arguments.Command.XMLName EQ "PrimaryCall">
	<cfset GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif YourOpenbox.IsTargetCall OR YourOpenbox.IsSuperCall>" & NewLine))>
<cfelseif arguments.Command.XMLName EQ "SecondaryCall">
	<cfset GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif NOT YourOpenbox.IsTargetCall AND NOT YourOpenbox.IsSuperCall>" & NewLine))>
</cfif>

<cfscript>
// i render the subcommands
GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
</cfscript>