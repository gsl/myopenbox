<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "output")){
	LocalVars.Attributes.Output=arguments.Command.XMLAttributes.output;
} else {
	LocalVars.Attributes.Output=arguments.Command.XMLText;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "addnewline") AND arguments.Command.XMLAttributes.addnewline){
	LocalVars.Attributes.AddNewLine=1;
} else {
	LocalVars.Attributes.AddNewLine=0;
}

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & LocalVars.Attributes.Output & RepeatString("<br />", LocalVars.Attributes.AddNewLine) & NewLine));
</cfscript>