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

if(Find("##", arguments.Command.XMLAttributes.phase)){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfscript>" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "if(NOT StructKeyExists(application.MyOpenbox.Phases[""" & arguments.Command.XMLAttributes.phase & """][1], ""TimeStamp"")){" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "// i run/create the Phase file" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "application.MyOpenbox.RunPhase(""" & arguments.Command.XMLAttributes.phase & """, application.MyOpenbox.Phases[""" & arguments.Command.XMLAttributes.phase & """]);" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "}" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfscript>" & NewLine));
	GeneratedContent.append(JavaCast("string", NewLine));
	
	// i insert the phase include
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i include the called Phase file --->" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfinclude template=""phase.##LCase(""" & arguments.command.xmlattributes.phase & """)##.cfm"">" & NewLine));
	GeneratedContent.append(JavaCast("string", NewLine));
} else {
	// i create the Phase cache file if necessary
	if(NOT StructKeyExists(this.Phases[arguments.Command.XMLAttributes.phase][1], "TimeStamp")){
		CreatePhaseFile(arguments.Command.XMLAttributes.phase, this.Phases[arguments.Command.XMLAttributes.phase]);
	}
	// i insert the phase include
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i include the called Phase file --->" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfinclude template=""phase." & lcase(arguments.command.xmlattributes.phase) & ".cfm"">" & NewLine));
	GeneratedContent.append(JavaCast("string", NewLine));
}

// GeneratedContent.append(JavaCast("string", "<" & "cfset YourOpenbox[""CallerPhase""][""Name""]=""" & NEED2FINGHANDLE & """>" & NewLine));
</cfscript>