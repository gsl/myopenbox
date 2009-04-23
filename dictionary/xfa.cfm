<cfscript>
// if the Value attribute is supplied
if(StructKeyExists(arguments.Command.XMLAttributes, "value")){
	LocalVars.Attributes.Value=arguments.Command.XMLAttributes.value;
// ...or if the tag contains a value
} else if(Len(arguments.Command.XMLText)){
	LocalVars.Attributes.Value=arguments.Command.XMLText;
// ...otherwise, i use the supplied name for the value (notice how this behavior differs from the SetVariable derived Verbs)
} else {
	LocalVars.Attributes.Value=arguments.Command.XMLAttributes.name;
}
// i set OverWrite
if(StructKeyExists(arguments.Command.XMLAttributes, "overwrite")){
	LocalVars.Attributes.Overwrite=arguments.Command.XMLAttributes.overwrite;
} else {
	LocalVars.Attributes.Overwrite=True;
}

// i insert the GetQualifiedFuseAction() function
if(StructIsEmpty(arguments.Circuit)){
	LocalVars.Attributes.Value="application.MyOpenbox.GetQualifiedFuseAction(""" & LocalVars.Attributes.Value & """)";
} else {
	LocalVars.Attributes.Value="application.MyOpenbox.GetQualifiedFuseAction(""" & LocalVars.Attributes.Value & """, YourOpenbox.ThisCircuit)";
}

// i create and insert the tag(s)
if(LocalVars.Attributes.Overwrite){
	// i insert the Overwrite call
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset variables.XFAs." & arguments.Command.XMLAttributes.name & "=" & LocalVars.Attributes.Value & ">" & NewLine));
} else {
	// i insert the param validator/setter for this XFA
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfparam name=""variables.XFAs." & arguments.Command.XMLAttributes.name & """ type=""string"" default=""##" & LocalVars.Attributes.Value & "##"">" & NewLine));
}

</cfscript>