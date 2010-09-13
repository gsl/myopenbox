<cfscript>
LocalVars.Attributes.Output=arguments.Command.XMLText;

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfscript>" & LocalVars.Attributes.Output & "<" & "/cfscript>" & NewLine));
</cfscript>