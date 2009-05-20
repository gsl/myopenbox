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
if(StructKeyExists(arguments.Command.XMLAttributes, "checkdefault")){
	LocalVars.Attributes.CheckDefault=arguments.Command.XMLAttributes.checkdefault;
} else {
	LocalVars.Attributes.CheckDefault="";
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
if(StructKeyExists(arguments.Command.XMLAttributes, "name")){
	if(structKeyExists(arguments.Command.XMLAttributes, "collection")){
		GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset structAppend(" & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & ", " & arguments.Command.XMLAttributes.Collection & ", " & LocalVars.Attributes.Overwrite & ")>" & NewLine));
	} else {
		if(LocalVars.Attributes.Overwrite){
			// i insert the Overwrite call
			if(Len(LocalVars.Attributes.CheckDefault) GT 0) {
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif IsDefined(""" & LocalVars.Attributes.CheckDefault & """)>" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfset " & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & "=" & LocalVars.Attributes.CheckDefault & ">" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfset " & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & "=" & LocalVars.Quote & LocalVars.Attributes.Value & LocalVars.Quote & ">" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
			} else {
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & "=" & LocalVars.Quote & LocalVars.Attributes.Value & LocalVars.Quote & ">" & NewLine));
			}
			if(LocalVars.Attributes.Type NEQ "any"){
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfparam name=""" & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & """ type=""" & LocalVars.Attributes.Type & """ default=""##" & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & "##"">" & NewLine));
			}
		} else {
			// i insert the param validator/setter
			if(Len(LocalVars.Attributes.CheckDefault) GT 0) {
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfif IsDefined(""" & LocalVars.Attributes.CheckDefault & """)>" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfparam name=""" & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & """ type=""" & LocalVars.Attributes.Type & """ default=""##" & LocalVars.Attributes.CheckDefault & "##"">" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfelse>" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level+1) & "<" & "cfparam name=""" & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & """ type=""" & LocalVars.Attributes.Type & """ default=""" & LocalVars.Attributes.Value & """>" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "/cfif>" & NewLine));
			} else {
				GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfparam name=""" & LocalVars.VariablePrefix & arguments.Command.XMLAttributes.name & """ type=""" & LocalVars.Attributes.Type & """ default=""" & LocalVars.Attributes.Value & """>" & NewLine));
			}
		}
	}
// i handle structure appending (NEEDS A OVERWRITE ATTRIBUTE...but named something else bc of existing attribute)
} else if(structKeyExists(arguments.Command.XMLAttributes, "collection")){
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset structAppend(" & left(LocalVars.VariablePrefix, len(LocalVars.VariablePrefix) - 1) & ", " & arguments.Command.XMLAttributes.Collection & ", " & LocalVars.Attributes.Overwrite & ")>" & NewLine));
} else {
	GeneratedContent.append(JavaCast("string", Indent(arguments.Level) & "<" & "cfset " & LocalVars.Quote & LocalVars.Attributes.Value & LocalVars.Quote & ">" & NewLine));
}
</cfscript>