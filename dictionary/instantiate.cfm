<cfscript>
// i create any Invoke subelements as chained methods
LocalVars.ChainedMethods="";
// i loop through any children elements
if(ArrayLen(arguments.Command.XMLChildren)){
	for(LocalVars.i=1; LocalVars.i LTE ArrayLen(arguments.Command.XMLChildren); LocalVars.i=LocalVars.i + 1){
		if(arguments.Command.XMLChildren[LocalVars.i]["XMLName"] EQ "invoke"){
			// i set any include arguments
			LocalVars.Arguments="";
			for(LocalVars.j=1; LocalVars.j LTE ArrayLen(arguments.Command.XMLChildren[LocalVars.i]["XMLChildren"]); LocalVars.j=LocalVars.j + 1){
				if(arguments.Command.XMLChildren[LocalVars.i]["XMLChildren"][LocalVars.j]["XMLName"] EQ "argument"){
					LocalVars.Attributes=StructNew();
					LocalVars.Attributes.Name=arguments.Command.XMLChildren[LocalVars.i]["XMLChildren"][LocalVars.j]["XMLAttributes"]["name"];
					if(StructKeyExists(arguments.Command.XMLChildren[LocalVars.i]["XMLChildren"][LocalVars.j]["XMLAttributes"], "value")){
						LocalVars.Attributes.Value=arguments.Command.XMLChildren[LocalVars.i]["XMLChildren"][LocalVars.j]["XMLAttributes"]["value"];
					} else {
						LocalVars.Attributes.Value=arguments.Command.XMLChildren[LocalVars.i]["XMLChildren"][LocalVars.j]["XMLText"];
					}
					LocalVars.Arguments=ListAppend(LocalVars.Arguments, LocalVars.Attributes.Name & "=""" & LocalVars.Attributes.Value & """");
				} else {
					// THROW ERROR - invalid subelement of invoke
				}
			}
			// i set the invoke statement
			LocalVars.AssignmentStatement=arguments.Command.XMLChildren[LocalVars.i]["XMLAttributes"]["method"] & "(" & LocalVars.Arguments & ")";
		} else {
			// THROW ERROR - invalid subelement of instantiate
		}
		LocalVars.ChainedMethods=ListAppend(LocalVars.ChainedMethods, LocalVars.AssignmentStatement, ".");
	}
	LocalVars.ChainedMethods="." & LocalVars.ChainedMethods;
}

// i insert the CreateObject statement
switch(arguments.Command.XMLAttributes.type){
	case "CFC" : case "Component" :
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & arguments.Command.XMLAttributes.variable & "=CreateObject(""component"", """ & arguments.Command.XMLAttributes.path & """)" & LocalVars.ChainedMethods & ">" & NewLine));
		break;
	case "Webservice" :
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & arguments.Command.XMLAttributes.variable & "=CreateObject(""webservice"", """ & arguments.Command.XMLAttributes.path & """)>" & NewLine));
		break;
}
</cfscript>