<cfscript>
// if the inner data is commented
if(Len(arguments.Command.XMLComment)){
	// i set the value equal to the commented string
	LocalVars.Attributes.Value=arguments.Command.XMLComment;
// ...otherwise, i'll just use the XMLText
} else {
	LocalVars.Attributes.Value=arguments.Command.XMLText;
}

// i check for this.Tasks
if(NOT StructKeyExists(this, "Tasks")) this.Tasks=StructNew();

// i create the Task
if(arguments.Type EQ "Phase"){
	if(StructIsEmpty(arguments.Circuit)){
		if(NOT StructKeyExists(this.Tasks, "_Phases")) this.Tasks._Phases=StructNew();
		if(NOT StructKeyExists(this.Tasks._Phases, arguments.PhaseName)){
			this.Tasks._Phases[arguments.PhaseName]=ArrayNew(1);
		}
		ArrayAppend(this.Tasks._Phases[arguments.PhaseName], LocalVars.Attributes.Value);
	} else {
		if(NOT StructKeyExists(this.Tasks, arguments.Circuit.Name)){
			this.Tasks[arguments.Circuit.Name]["_Phases"]=StructNew();
		}
		if(NOT StructKeyExists(this.Tasks[arguments.Circuit.Name]["_Phases"], arguments.PhaseName)){
			this.Tasks[arguments.Circuit.Name]["_Phases"][arguments.PhaseName]=ArrayNew(1);
		}
		ArrayAppend(this.Tasks[arguments.Circuit.Name]["_Phases"][arguments.PhaseName], LocalVars.Attributes.Value);
	}
	
} else if(arguments.Type EQ "FuseAction"){
	if(NOT StructKeyExists(this.Tasks, arguments.Circuit.Name)){
		this.Tasks[arguments.Circuit.Name]=StructNew();
	}
	if(NOT StructKeyExists(this.Tasks[arguments.Circuit.Name], arguments.FuseAction.Name)){
		this.Tasks[arguments.Circuit.Name][arguments.FuseAction.Name]=ArrayNew(1);
	}
	ArrayAppend(this.Tasks[arguments.Circuit.Name][arguments.FuseAction.Name], LocalVars.Attributes.Value);
}
</cfscript>