<!--- <verb version="1.0">
	<author>MyOpenbox</author>
	<description></description>
	<syntax><![CDATA[<call phase="" />]]></syntax>
	<relationships family="">
		<associated /><dependencies /><prereqs />
	</relationships>
</verb> --->

<cfscript>
// GeneratedContent.append(JavaCast("string", "<" & "cfset YourOpenbox[""CallerPhase""][""Name""]=""" & arguments.PhaseName & """>" & NewLine));

/* I had to set all the phases to delayed/dynamic creation because some custom phases did not exist on at parse time, so i need to check when and where the Phases are parssed in the execution plan and see if we can create files on parsing or if they need to stay how they are (which could cause issues on de) */
// if(Find("##", arguments.Command.XMLAttributes.phase)){
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset YourOpenbox.ThisPhase.AndThen="""" />" & NewLine));

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif StructKeyExists(application.MyOpenbox.Phases, """ & arguments.Command.XMLAttributes.phase & """)>" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfscript>" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "if(NOT StructKeyExists(application.MyOpenbox.Phases[""" & arguments.Command.XMLAttributes.phase & """][1], ""TimeStamp"")){" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 2) & "// i run/create the Phase file" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 2) & "application.MyOpenbox.RunPhase(""" & arguments.Command.XMLAttributes.phase & """, application.MyOpenbox.Phases[""" & arguments.Command.XMLAttributes.phase & """]);" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "}" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "/cfscript>" & NewLine));
	GeneratedContent.append(JavaCast("string", NewLine));
	
	// i insert the phase include
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "!--- i include the called Phase file --->" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "phase.##LCase(""" & arguments.command.xmlattributes.phase & """)##.cfm"">" & NewLine));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
GeneratedContent.append(JavaCast("string", NewLine));

if(ArrayLen(arguments.Command.XMLChildren) GT 0) {
	GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level)));
}

// } else {
// 	// i create the Phase cache file if necessary
// 	if(NOT StructKeyExists(this.Phases[arguments.Command.XMLAttributes.phase][1], "TimeStamp")){
// 		CreatePhaseFile(arguments.Command.XMLAttributes.phase, this.Phases[arguments.Command.XMLAttributes.phase]);
// 	}
// 	// i insert the phase include
// 	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i include the called Phase file --->" & NewLine));
// 	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "phase." & lcase(arguments.command.xmlattributes.phase) & ".cfm"">" & NewLine));
// 	GeneratedContent.append(JavaCast("string", NewLine));
// }

// GeneratedContent.append(JavaCast("string", "<" & "cfset YourOpenbox[""CallerPhase""][""Name""]=""" & NEED2FINGHANDLE & """>" & NewLine));
</cfscript>