<cfscript>
LocalVars.Mathod="";
if(ListLen(arguments.Command.XMLName, ".") GTE 2){
	LocalVars.Method = UCase(ListGetAt(arguments.Command.XMLName, 2, "."));
}
if(StructKeyExists(arguments.Command.XMLAttributes, "in")){
	LocalVars.Method=arguments.Command.XMLAttributes["in"];
}
if(StructKeyExists(arguments.Command.XMLAttributes, "delimiter")){
	LocalVars.Delimiter=arguments.Command.XMLAttributes["delimiter"];
} else {
	LocalVars.Delimiter=",";
}

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif ListFindNoCase(""" & LocalVars.Method & """, YourOpenbox.Request.Method, """ & LocalVars.Delimiter & """)" & ">" & NewLine));
GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
</cfscript>
