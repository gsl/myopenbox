<cfscript>
// i create the file contents
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- DO --->" & NewLine));

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfscript>" & NewLine));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "// i set the target of this Do command (DoFuseAction)" & NewLine));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "_YourOpenbox.Temp.DoFuseAction=StructNew();" & NewLine));
// i process the Action differently if it is dynamic
if(Find("##", arguments.Command.XMLAttributes.action)){
	if(StructIsEmpty(arguments.Circuit)){
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "_YourOpenbox.Temp.DoFuseAction.FQName=""" & arguments.Command.XMLAttributes.action & """;" & NewLine));
	} else {
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "_YourOpenbox.Temp.DoFuseAction.FQName=application.MyOpenbox.GetQualifiedFuseAction(""" & arguments.Command.XMLAttributes.action & """, YourOpenbox.ThisCircuit);" & NewLine));
	}
	GeneratedContent.append(JavaCast("string", NewLine));
	
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "// i run the RunFuseAction method on the target FuseAction" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "application.MyOpenbox.RunFuseAction(_YourOpenbox.Temp.DoFuseAction.FQName);" & NewLine));
	GeneratedContent.append(JavaCast("string", NewLine));
} else {
	LocalVars.DoFuseAction=GetQualifiedFuseAction(arguments.Command.XMLAttributes.action, arguments.Circuit);
	RunFuseAction(LocalVars.DoFuseAction);
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "_YourOpenbox.Temp.DoFuseAction.FQName=""" & LocalVars.DoFuseAction & """;" & NewLine));
}
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfscript>" & NewLine));
GeneratedContent.append(JavaCast("string", NewLine));

// i process any subcommands
if(ArrayLen(arguments.Command.XMLChildren)){	
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i set PassThroughs variables --->" & NewLine));
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _YourOpenbox.Temp.DoFuseAction.PassThroughs=StructNew()>" & NewLine));
	
	// i loop through the XMLChildren
	for(LocalVars.i=1; LocalVars.i LTE ArrayLen(arguments.Command.XMLChildren); LocalVars.i=LocalVars.i + 1){
		// i set the CurrentNode
		LocalVars.CurrentNode=arguments.Command.XMLChildren[LocalVars.i];
		
		// i reset Attributes
		LocalVars.Attributes=StructNew();
		// i determine the value of Value
		if(StructKeyExists(arguments.Command.XMLAttributes, "value")){
			LocalVars.Attributes.Value=arguments.Command.XMLAttributes.value;
		} else if(Len(LocalVars.CurrentNode.XMLText)) {
			LocalVars.Attributes.Value=LocalVars.CurrentNode.XMLText;
		} else {
			// THROW ERROR - Value not defined
			LocalVars.Attributes.Value="";
		}
		
		// i create and insert the tag(s)
		switch(LocalVars.CurrentNode.XMLName){
			case "attribute" :
				if(structKeyExists(LocalVars.CurrentNode.XMLAttributes, "collection")){
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset structAppend(attributes," & LocalVars.CurrentNode.XMLAttributes.collection & ")>" & NewLine));
				} else {
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset attributes." & LocalVars.CurrentNode.XMLAttributes.name & "=""" & LocalVars.Attributes.Value & """>" & NewLine));
				}
				break;
			case "crv" :
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif YourOpenbox.ThisCircuit.Name EQ ListFirst(_YourOpenbox.Temp.DoFuseAction.FQName, ""."")>" & NewLine));
				if(structKeyExists(LocalVars.CurrentNode.XMLAttributes, "collection")){
					// if the collection value is set to 'CRVs', this will write out as: structAppend(CRVs, CRVs)
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "<" & "cfset structAppend(CRVs, " & LocalVars.CurrentNode.XMLAttributes.collection & ")>" & NewLine));
				} else {
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "<" & "cfset CRVs." & LocalVars.CurrentNode.XMLAttributes.name & "=""" & LocalVars.Attributes.Value & """>" & NewLine));
				}
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
				
				
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "<" & "cfif NOT structKeyExists(_YourOpenbox.Circuits, ListFirst(_YourOpenbox.Temp.DoFuseAction.FQName, "".""))>" & NewLine));
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 2) & "<" & "cfset _YourOpenbox.Circuits[ListFirst(_YourOpenbox.Temp.DoFuseAction.FQName, ""."")][""CRVs""] = structNew()>" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "<" & "/cfif>" & NewLine));
				
				
				if(structKeyExists(LocalVars.CurrentNode.XMLAttributes, "collection")){
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "<" & "cfset structAppend(_YourOpenbox.Circuits[ListFirst(_YourOpenbox.Temp.DoFuseAction.FQName, ""."")][""CRVs""], " & LocalVars.CurrentNode.XMLAttributes.collection & ")>" & NewLine));
				} else {
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "<" & "cfset _YourOpenbox.Circuits[ListFirst(_YourOpenbox.Temp.DoFuseAction.FQName, ""."")][""CRVs""][""" & LocalVars.CurrentNode.XMLAttributes.name & """]=""" & LocalVars.Attributes.Value & """>" & NewLine));
				}
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
				break;
			case "fav" :
				if(structKeyExists(LocalVars.CurrentNode.XMLAttributes, "collection")){
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif NOT structKeyExists(_YourOpenbox.Temp.DoFuseAction.PassThroughs, ""FAVs"")>" & NewLine));
					
						GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "<" & "cfset _YourOpenbox.Temp.DoFuseAction.PassThroughs.FAVs=StructNew()>" & NewLine));
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset structAppend(_YourOpenbox.Temp.DoFuseAction.PassThroughs.FAVs, " & LocalVars.CurrentNode.XMLAttributes.collection & ")>" & NewLine));
				} else {
					GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _YourOpenbox.Temp.DoFuseAction.PassThroughs.FAVs[""" & LocalVars.CurrentNode.XMLAttributes.name & """]=""" & LocalVars.Attributes.Value & """>" & NewLine));
				}
				break;
			case "xfa" :
				GeneratedContent.append(JavaCast("string", Replace(RenderCommand(arguments.Type, LocalVars.CurrentNode, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level), "XFAs.", "_YourOpenbox.Temp.DoFuseAction.PassThroughs.XFAs.")));
				break;
			default :
				// THROW ERROR -- verb not recognized as a DO subcommand
				break;
		}
	}
}

// i insert the PushToActionStack function
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i process the YourOpenbox, Circuit, and FuseAction variables --->" & NewLine));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _PushToActionStack(_YourOpenbox.Temp.DoFuseAction)>" & NewLine));
GeneratedContent.append(JavaCast("string", NewLine));


GeneratedContent.append(JavaCast("string", "<" & "cfset _YourOpenbox.cfcatch=StructNew() />" & NewLine));
GeneratedContent.append(JavaCast("string", "<" & "cftry>" & NewLine));

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i include the FuseAction file --->" & NewLine));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "fuseaction.##LCase(_YourOpenbox.Temp.DoFuseAction.FQName)##.cfm"">" & NewLine));
GeneratedContent.append(JavaCast("string", NewLine));

GeneratedContent.append(JavaCast("string", "<" & "cfcatch type=""Any"">" & NewLine));
GeneratedContent.append(JavaCast("string", Indent() & "<" & "cfset _YourOpenbox.cfcatch=cfcatch />" & NewLine));
GeneratedContent.append(JavaCast("string", "<" & "/cfcatch>" & NewLine));
GeneratedContent.append(JavaCast("string", "<" & "/cftry>" & NewLine));

// i insert the PopActionStack function
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i reinstate ThisPhase's, ThisCircuit's and ThisFuseAction's values from the ActionStack --->" & NewLine));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _PopActionStack()>" & NewLine));

GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- End DO --->" & NewLine));
GeneratedContent.append(JavaCast("string", NewLine));

// i check for a value from a thrown exception and rethrow it, since cf8 doesn't have cffinally
GeneratedContent.append(JavaCast("string", "<" & "cfif NOT StructIsEmpty(_YourOpenbox.cfcatch)>" & NewLine));
GeneratedContent.append(JavaCast("string", Indent() & "<" & "cfthrow object=""##_YourOpenbox.cfcatch##"" />" & NewLine));
GeneratedContent.append(JavaCast("string", "<" & "/cfif>" & NewLine));
</cfscript>