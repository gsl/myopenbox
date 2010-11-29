<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "value")){
	LocalVars.Attributes.Value=arguments.Command.XMLAttributes.value;
} else {
	LocalVars.Attributes.Value=arguments.Command.XMLText;
}

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset YourOpenbox.ThisPhase.AndThen=" & LocalVars.Attributes.Value & ">" & NewLine));
</cfscript>