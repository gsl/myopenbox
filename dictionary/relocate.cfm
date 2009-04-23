<cfscript>
if(NOT StructKeyExists(arguments.Command.XMLAttributes, "url") AND Len(arguments.Command.XMLText)){
	arguments.Command.XMLAttributes.url=arguments.Command.XMLText;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "type")){
	LocalVars.Attributes.Type=arguments.Command.XMLAttributes.type;
} else {
	LocalVars.Attributes.Type="Client";
}
if(StructKeyExists(arguments.Command.XMLAttributes, "addtoken")){
	LocalVars.Attributes.AddToken=arguments.Command.XMLAttributes.addtoken;
} else {
	LocalVars.Attributes.AddToken=false;
}
</cfscript>

<cfscript>
if(LocalVars.Attributes.Type EQ "Client"){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cflocation url=""" & arguments.Command.XMLAttributes.url & """ addtoken=""" & LocalVars.Attributes.AddToken & """>" & NewLine));
} else if(LocalVars.Attributes.Type EQ "Server"){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset GetPageContext().Forward(""" & arguments.Command.XMLAttributes.url & """)>"));
} else {
	// THROW ERROR -- Type not recognizied
}
</cfscript>