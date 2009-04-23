<cfif arguments.Type EQ "Phase" 
	AND NOT StructIsEmpty(arguments.Circuit) 
	AND ListFindNoCase(this.Parameters.CircuitRelatedPhases, arguments.PhaseName)>
	
	<cfif StructKeyExists(arguments.Circuit, "ParentName") 
		AND StructKeyExists(this.Circuits[arguments.Circuit.ParentName], "Phases") 
		AND StructKeyExists(this.Circuits[arguments.Circuit.ParentName]["Phases"], arguments.PhaseName)>
	
		<cfscript>
		// i create the Circuit cache files if necessary
		if(NOT StructKeyExists(this.Circuits[arguments.Circuit.ParentName], "TimeStamp")){
			CreateCircuitFiles(this.Circuits[arguments.Circuit.ParentName]);
		}
		
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- CALLSUPER --->" & NewLine));
		
		// i insert the PushToActionStack function
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i process the YourOpenbox, Circuit, and FuseAction variables --->" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _PushToActionStack()>" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfscript>" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "// i set IsSuperCall" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "YourOpenbox.IsSuperCall=True;" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "// i set the Parent Circuit variables" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "YourOpenbox.ThisCircuit=application.MyOpenbox.GetCircuit(""" & arguments.Circuit.ParentName & """);" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "if(StructKeyExists(_YourOpenbox.Circuits, """ & arguments.Circuit.ParentName & """) AND StructKeyExists(_YourOpenbox.Circuits." & arguments.Circuit.ParentName & ", ""CRVs"")){" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "CRVs=_YourOpenbox.Circuits." & arguments.Circuit.ParentName & ".CRVs;" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "} else {" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level + 1) & "CRVs=StructNew();" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "}" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfscript>" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		if(StructKeyExists(this.Circuits[arguments.Circuit.ParentName], "Settings")){
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i apply the Parent Circuit Settings --->" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfinclude template=""settings." & lcase(arguments.circuit.parentname) & ".cfm"">" & NewLine));
			GeneratedContent.append(JavaCast("string", NewLine));
		}
		
		// i insert the include for the phase file
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i include the Super Phase file --->" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfinclude template=""phase." & lcase(arguments.phasename) & "." & LCase(arguments.Circuit.ParentName) & ".cfm"">" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		// i insert the PopActionStack function
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- i reinstate ThisPhase's, ThisCircuit's and ThisFuseAction's values from the ActionStack --->" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset _PopActionStack()>" & NewLine));
		
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "!--- End CALLSUPER --->" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		</cfscript>
	
	</cfif>
	
<cfelse>
	<!--- !THROW ERROR - CallSuper command not valid in this context! --->
</cfif>