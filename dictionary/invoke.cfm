<cfscript>
// i set any include arguments
LocalVars.Arguments="";
for(LocalVars.i=1; LocalVars.i LTE ArrayLen(arguments.Command.XMLChildren); LocalVars.i=LocalVars.i + 1){
	if(arguments.Command.XMLChildren[LocalVars.i]["XMLName"] EQ "argument"){
		LocalVars.Attributes=StructNew();
		LocalVars.Attributes.Name=arguments.Command.XMLChildren[LocalVars.i]["XMLAttributes"]["name"];
		if(StructKeyExists(arguments.Command.XMLChildren[LocalVars.i]["XMLAttributes"], "value")){
			LocalVars.Attributes.Value=arguments.Command.XMLChildren[LocalVars.i]["XMLAttributes"]["value"];
		} else {
			LocalVars.Attributes.Value=arguments.Command.XMLChildren[LocalVars.i]["XMLText"];
		}
		LocalVars.Arguments=ListAppend(LocalVars.Arguments, LocalVars.Attributes.Name & "=""" & LocalVars.Attributes.Value & """");
	} else {
		// THROW ERROR - invalid subelement of invoke
	}
	
}
// i set the invoke statement
LocalVars.AssignmentStatement=arguments.Command.XMLAttributes.variable & "." & arguments.Command.XMLAttributes.method & "(" & LocalVars.Arguments & ")";

// i insert the invoke commands
if(StructKeyExists(arguments.Command.XMLAttributes, "returnvariable")){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & arguments.Command.XMLAttributes.returnvariable & "=" & LocalVars.AssignmentStatement & ">" & NewLine));
} else {
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & LocalVars.AssignmentStatement & ">" & NewLine));
}
</cfscript>