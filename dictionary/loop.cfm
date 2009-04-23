<!--- Conditional loop --->
<cfif StructKeyExists(arguments.Command.XMLAttributes, "condition")>
	
	<!--- i insert the cfloop tag with the Condition attribute --->
	<cfset GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfloop condition=""" & arguments.Command.XMLAttributes.condition & """>" & NewLine))>
	
<!--- Index loop --->
<cfelseif StructKeyExists(arguments.Command.XMLAttributes, "index") 
	AND StructKeyExists(arguments.Command.XMLAttributes, "from") 
	AND StructKeyExists(arguments.Command.XMLAttributes, "to")>
	
	<cfscript>
	// i set default value(s) for optional attributes
	if(StructKeyExists(arguments.Command.XMLAttributes, "step")){
		LocalVars.Attributes.Step=arguments.Command.XMLAttributes.step;
	} else {
		LocalVars.Attributes.Step=1;
	}
	// i insert the cfloop tag with the Index, From, To, and Step attributes
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfloop index=""" & arguments.Command.XMLAttributes.index & """ from=""" & arguments.Command.XMLAttributes.from & """ to=""" & arguments.Command.XMLAttributes.to & """ step=""" & LocalVars.Attributes.Step & """>" & NewLine));
	</cfscript>

<!--- List loop --->
<cfelseif StructKeyExists(arguments.Command.XMLAttributes, "index") 
	AND StructKeyExists(arguments.Command.XMLAttributes, "list")>
	
	<cfscript>
	// i set default value(s) for optional attributes
	if(StructKeyExists(arguments.Command.XMLAttributes, "delimiters")){
		LocalVars.Attributes.Delimiters=arguments.Command.XMLAttributes.delimiters;
	} else {
		LocalVars.Attributes.Delimiters=",";
	}
	// i insert the cfloop tag with the Item and Collection attributes
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfloop index=""" & arguments.Command.XMLAttributes.index & """ list=""" & arguments.Command.XMLAttributes.list & """ delimiters=""" & LocalVars.Attributes.Delimiters & """>" & NewLine));
	</cfscript>
	
<!--- Structure loop --->
<cfelseif StructKeyExists(arguments.Command.XMLAttributes, "item") 
	AND StructKeyExists(arguments.Command.XMLAttributes, "collection")>
	
	<!--- i insert the cfloop tag with the Item and Collection attributes --->
	<cfset GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfloop item=""" & arguments.Command.XMLAttributes.item & """ collection=""" & arguments.Command.XMLAttributes.collection & """>" & NewLine))>

<!--- Query loop --->
<cfelseif StructKeyExists(arguments.Command.XMLAttributes, "query")>
	
	<cfscript>
	// i set default value(s) for optional attributes
	if(StructKeyExists(arguments.Command.XMLAttributes, "startrow")){
		LocalVars.Attributes.StartRow=arguments.Command.XMLAttributes.startrow;
	} else {
		LocalVars.Attributes.StartRow=1;
	}
	if(StructKeyExists(arguments.Command.XMLAttributes, "endrow")){
		LocalVars.Attributes.EndRow=arguments.Command.XMLAttributes.endrow;
	} else {
		LocalVars.Attributes.EndRow="##" & arguments.Command.XMLAttributes.query & ".RecordCount##";
	}
	// i insert the cfloop tag with the Query, StartRow, and EndRow attributes
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfloop query=""" & arguments.Command.XMLAttributes.query & """ startrow=""" & LocalVars.Attributes.StartRow & """ endrow=""" & LocalVars.Attributes.EndRow & """>" & NewLine));
	</cfscript>

<cfelse>
	<!--- THROW ERROR -- invalid loop call ---><cfoutput>THROW ERROR</cfoutput><cfabort>
</cfif>

<cfscript>
// i render the subcommands
GeneratedContent.append(JavaCast("string", RenderCommands(arguments.Type, arguments.Command.XMLChildren, arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level + 1)));
GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfloop>" & NewLine));
</cfscript>