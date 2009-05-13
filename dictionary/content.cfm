<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "append")){
	LocalVars.Attributes.Append=arguments.Command.XMLAttributes.append;
} else {
	LocalVars.Attributes.Append=true;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "force")){
	LocalVars.Attributes.Force=arguments.Command.XMLAttributes.force;
} else {
	LocalVars.Attributes.Force=false;
}

// i set defaults for Type
LocalVars.Type.IsWrapper=false;
// if this Content call is a wrapper for another verb, i set Type modifers
if(arguments.Command.XMLName EQ "content.call"){
	LocalVars.Type.IsWrapper=true;
	LocalVars.CallCommands.XMLName="call";
	LocalVars.CallCommands.XMLAttributes=arguments.Command.XMLAttributes;
} else if(arguments.Command.XMLName EQ "content.do"){
	LocalVars.Type.IsWrapper=true;
	LocalVars.CallCommands.XMLName="do";
	LocalVars.CallCommands.XMLAttributes=arguments.Command.XMLAttributes;
	LocalVars.CallCommands.XMLChildren=arguments.Command.XMLChildren;
} else if(arguments.Command.XMLName EQ "content.include"){
	LocalVars.Type.IsWrapper=true;
	LocalVars.CallCommands.XMLName="include";
	LocalVars.CallCommands.XMLAttributes=arguments.Command.XMLAttributes;
} else if(arguments.Command.XMLName EQ "content.write"){
	LocalVars.Type.IsWrapper=true;
	LocalVars.CallCommands.XMLName="write";
	LocalVars.CallCommands.XMLText=arguments.Command.XMLText;
	LocalVars.CallCommands.XMLAttributes=arguments.Command.XMLAttributes;
} else if(arguments.Command.XMLName EQ "content.dump"){
	LocalVars.Type.IsWrapper=true;
	LocalVars.CallCommands.XMLName="dump";
	LocalVars.CallCommands.XMLText=arguments.Command.XMLText;
	LocalVars.CallCommands.XMLAttributes=arguments.Command.XMLAttributes;
}

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- CONTENT --->" & NewLine));
// i insert the _PushToContentStack function
if(StructKeyExists(arguments.Command.XMLAttributes, "variable")){
	// ...if variable is declared, i will include it
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _PushToContentStack(ContentVariableName=""" & arguments.Command.XMLAttributes.variable & """, IsForce=" & LocalVars.Attributes.Force & ")>" & NewLine));
} else {
	// ...otherwise i leave it to MOBX to determine
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _PushToContentStack(IsForce=" & LocalVars.Attributes.Force & ")>" & NewLine));
}
GeneratedContent.append(JavaCast("string", NewLine));

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i save the generated content into the a temporary ContentKey --->" & NewLine));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfsavecontent variable=""##YourOpenbox.ThisContentVariable.Name##"">" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "<" & "cfscript>" & NewLine));
	// i insert the append decision statements
	if(LocalVars.Attributes.Append){
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "// i append the current ContentVariable if it exists" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "if(" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 2) & "_YourOpenbox.ContentStack[ArrayLen(_YourOpenbox.ContentStack)][""IsContentChange""]" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 2) & "AND NOT _YourOpenbox.ContentStack[ArrayLen(_YourOpenbox.ContentStack)][""PushToDimension""]" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 2) & "AND IsDefined(YourOpenbox.ThisContentVariable.Name)" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "){" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 2) & "WriteOutput(Evaluate(YourOpenbox.ThisContentVariable.Name));" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "}" & NewLine));
	}
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "<" & "/cfscript>" & NewLine));
	GeneratedContent.append(JavaCast("string", NewLine));
	// if this is a wrapper command call
	if(LocalVars.Type.IsWrapper){
		// ...i render the "wrapped" tag
		LocalVars.temp=RenderCommand(arguments.Type, LocalVars.CallCommands, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1);
		GeneratedContent.append(JavaCast("string", LocalVars.temp));
	// else
	} else {
		// ...i render the subcommand(s)
		LocalVars.temp=RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1);
		GeneratedContent.append(JavaCast("string", LocalVars.temp));
	}
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfsavecontent>" & NewLine));
GeneratedContent.append(JavaCast("string", NewLine));

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _PopContentStack()>" & NewLine));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- End CONTENT --->" & NewLine));
GeneratedContent.append(JavaCast("string", NewLine));
</cfscript>