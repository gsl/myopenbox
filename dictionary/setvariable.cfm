<cfscript>
if(StructKeyExists(arguments.Command.XMLAttributes, "type")){
	LocalVars.Attributes.Type=arguments.Command.XMLAttributes.type;
} else {
	LocalVars.Attributes.Type="any";
}
if(StructKeyExists(arguments.Command.XMLAttributes, "value")){
	LocalVars.Attributes.Value=arguments.Command.XMLAttributes.value;
} else {
	LocalVars.Attributes.Value=arguments.Command.XMLText;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "overwrite")){
	LocalVars.Attributes.Overwrite=arguments.Command.XMLAttributes.overwrite;
} else {
	LocalVars.Attributes.Overwrite=True;
}
if(StructKeyExists(arguments.Command.XMLAttributes, "quote")){
	LocalVars.Attributes.Quote=arguments.Command.XMLAttributes.quote;
} else {
	LocalVars.Attributes.Quote=True;
}

// i set the variable/scope prefix
switch(arguments.Command.XMLName){
	case "attribute" :
		LocalVars.VariablePrefix="attributes.";
		break;
	case "crv" :
		LocalVars.VariablePrefix="variables.CRVs.";
		break;
	case "fav" :
		LocalVars.VariablePrefix="variables.FAVs.";
		break;
	case "set" :
		LocalVars.VariablePrefix="";
		break;
}

if(LocalVars.Attributes.Quote){
	LocalVars.Quote = """";
} else {
	LocalVars.Quote = "";
}

// i validate Type
/* if(NOT ListFindNoCase("Any,Array,Binary,Boolean,CreditCard,Date,Email,Eurodate,Float,GUId,Integer,Numeric,Query,RegEx,SSN,String,Struct,Telephone,Time,URL,UUId,USDate,VariableName,XML,ZipCode", LocalVars.Attributes.Type)){
	// ERROR: i throw an error if Type is not valid
} */

// i create and insert the tag(s)
if(StructKeyExists(arguments.Command.XMLAttributes, "collection")){
	
	if(StructKeyExists(arguments.Command.XMLAttributes, "name")){
		if(NOT LocalVars.Attributes.Overwrite){
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif NOT StructKeyExists(" & replace(LocalVars.VariablePrefix, ".", "") & ", """ & arguments.Command.XMLAttributes.name & """)>" & NewLine));
			arguments.Level = arguments.Level + 1;
		}
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & LocalVars.VariablePrefix & "" & arguments.Command.XMLAttributes.name & " = " & arguments.Command.XMLAttributes.collection & ">" & NewLine));
		if(NOT LocalVars.Attributes.Overwrite){
			arguments.Level = arguments.Level - 1;
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
		}
	} else {
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset StructAppend(" & replace(LocalVars.VariablePrefix, ".", "") & ", " & arguments.Command.XMLAttributes.Collection & ", """ & LocalVars.Attributes.Overwrite & """)>" & NewLine));
	}
	
} else if(StructKeyExists(arguments.Command.XMLAttributes, "name")){
	
	if(LocalVars.Attributes.Overwrite){
		// i insert the Overwrite call
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & "=" & LocalVars.Quote & LocalVars.Attributes.Value & LocalVars.Quote & ">" & NewLine));
		if(LocalVars.Attributes.Type NEQ "any"){
			GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfparam name=""" & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & """ type=""" & LocalVars.Attributes.Type & """ default=""##" & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & "##"">" & NewLine));
		}
	} else {
		// i insert the param validator/setter
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfparam name=""" & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & """ type=""" & LocalVars.Attributes.Type & """ default=""" & LocalVars.Attributes.Value & """>" & NewLine));
	}
// i handle structure appending (NEEDS A OVERWRITE ATTRIBUTE...but named something else bc of existing attribute)
} else {
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & LocalVars.Quote & LocalVars.Attributes.Value & LocalVars.Quote & ">" & NewLine));
}
</cfscript>