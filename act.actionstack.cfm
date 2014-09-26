<cfscript>
// i set YourOpenbox defaults
YourOpenbox["IsTargetCall"]=True;
YourOpenbox["IsSuperCall"]=False;
</cfscript>

<cfscript>
// i set _YourOpenbox defaults
_YourOpenbox.ActionStack=ArrayNew(1);
_YourOpenbox.Circuits=StructNew();
_YourOpenbox.ContentStack=ArrayNew(1);
</cfscript>

<cffunction name="_PushToActionStack" 
	hint="." 
	output="no" 
	returntype="void">
	
	<cfargument name="DoFuseAction" type="struct" default="#StructNew()#">
	<cfargument name="IsSetSuper" type="boolean" default="false">
	
	<cfscript>
	// i initialize the local vars
	var i=0;
	</cfscript>
	
	<cfif StructKeyExists(_YourOpenbox, "cfcatch") AND NOT StructIsEmpty(_YourOpenbox.cfcatch)>
		<cfthrow object="#_YourOpenbox.cfcatch#" />
	</cfif>
	
	<cfscript>
	// i insert a new row into the ActionStack
	ArrayAppend(_YourOpenbox.ActionStack, StructNew());
	i=ArrayLen(_YourOpenbox.ActionStack);
	
	// i include PassThrough variables (if assigned)
	if(StructKeyExists(arguments.DoFuseAction, "PassThroughs")){
		_YourOpenbox.ActionStack[i]["PassThroughs"]=arguments.DoFuseAction.PassThroughs;
	}
	
	// i process the YourOpenbox, Circuit, and FuseAction variables
	if(StructKeyExists(YourOpenbox, "ThisPhase")){
		_YourOpenbox.ActionStack[i]["ThisPhase"]=YourOpenbox.ThisPhase;
	}
	if(StructKeyExists(YourOpenbox, "CallerCircuit")){
		_YourOpenbox.ActionStack[i]["CallerCircuit"]=YourOpenbox.CallerCircuit;
		StructDelete(YourOpenbox, "CallerCircuit");
	}
	if(StructKeyExists(YourOpenbox, "CallerFuseAction")){
		_YourOpenbox.ActionStack[i]["CallerFuseAction"]=YourOpenbox.CallerFuseAction;
		StructDelete(YourOpenbox, "CallerFuseAction");
	}	
	if(StructKeyExists(YourOpenbox, "ThisCircuit")){
		_YourOpenbox.ActionStack[i]["ThisCircuit"]=YourOpenbox.ThisCircuit;
		_YourOpenbox.Circuits[YourOpenbox.ThisCircuit.Name]["CRVs"]=CRVs;
		YourOpenbox.CallerCircuit=YourOpenbox.ThisCircuit;
		StructDelete(YourOpenbox, "ThisCircuit");
		StructDelete(variables, "CRVs");
	}	
	if(StructKeyExists(YourOpenbox, "ThisFuseAction")){
		_YourOpenbox.ActionStack[i]["ThisFuseAction"]=YourOpenbox.ThisFuseAction;
		_YourOpenbox.ActionStack[i]["FAVs"]=FAVs;
		_YourOpenbox.ActionStack[i]["XFAs"]=XFAs;
		YourOpenbox.CallerFuseAction=YourOpenbox.ThisFuseAction;
		StructDelete(YourOpenbox, "ThisFuseAction");
		StructDelete(variables, "FAVs");
		StructDelete(variables, "XFAs");
	}
	_YourOpenbox.ActionStack[i]["IsTargetCall"]=YourOpenbox.IsTargetCall;
	_YourOpenbox.ActionStack[i]["IsSuperCall"]=YourOpenbox.IsSuperCall;
	YourOpenbox.IsTargetCall=False;
	</cfscript>
	
</cffunction>

<cffunction name="_PopActionStack" 
	hint="." 
	output="no" 
	returntype="void">
	
	<cfscript>
	// i initialize the local vars
	var i=ArrayLen(_YourOpenbox.ActionStack);
	</cfscript>
	
	<cfif StructKeyExists(_YourOpenbox, "cfcatch") AND NOT StructIsEmpty(_YourOpenbox.cfcatch)>
		<cfthrow object="#_YourOpenbox.cfcatch#" />
	</cfif>
	
	<cfscript>
	// i reinstate ThisPhase's, ThisCircuit's and ThisFuseAction's values from the ActionStack
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "ThisPhase")){
		YourOpenbox.ThisPhase=_YourOpenbox.ActionStack[i]["ThisPhase"];
	}
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "ThisCircuit")){
		YourOpenbox.ThisCircuit=_YourOpenbox.ActionStack[i]["ThisCircuit"];
		CRVs=_YourOpenbox.Circuits[YourOpenbox.ThisCircuit.Name]["CRVs"];
	}
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "ThisFuseAction")){
		YourOpenbox.ThisFuseAction=_YourOpenbox.ActionStack[i]["ThisFuseAction"];
		FAVs=_YourOpenbox.ActionStack[i]["FAVs"];
		XFAs=_YourOpenbox.ActionStack[i]["XFAs"];
	}
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "CallerCircuit")){
		YourOpenbox.CallerCircuit=_YourOpenbox.ActionStack[i]["CallerCircuit"];
	} else if(StructKeyExists(YourOpenbox, "CallerCircuit")){
		StructDelete(YourOpenbox, "CallerCircuit");
	}
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "CallerFuseAction")){
		YourOpenbox.CallerFuseAction=_YourOpenbox.ActionStack[i]["CallerFuseAction"];
	} else if(StructKeyExists(YourOpenbox, "CallerFuseAction")){
		StructDelete(YourOpenbox, "CallerFuseAction");
	}
	YourOpenbox.IsTargetCall=_YourOpenbox.ActionStack[i]["IsTargetCall"];
	YourOpenbox.IsSuperCall=_YourOpenbox.ActionStack[i]["IsSuperCall"];
	
	// i remove the instance from the ActionStack
	ArrayDeleteAt(_YourOpenbox.ActionStack, i);
	</cfscript>
	
</cffunction>

<cffunction name="_GetContentVariableName"
	hint="." 
	output="no" 
	returntype="string">
	
	<cfscript>
	if(StructKeyExists(YourOpenbox, "ThisContentVariable") AND StructKeyExists(YourOpenbox.ThisContentVariable, "Name")){
		return YourOpenbox.ThisContentVariable.Name;
	} else {
		return application.MyOpenbox.Parameters.DefaultContentVariable;
	}
	</cfscript>
	
</cffunction>

<cffunction name="_PushToContentStack" 
	hint="." 
	output="no" 
	returntype="void">
	
	<cfargument name="ContentVariableName" type="string" default="">
	<cfargument name="IsForce" type="boolean" default="false">
		
	<cfscript>
	// i initialize the local vars
	var i=0;
	var j=0;
	</cfscript>
	
	<cfscript>
	// i create a space for this ContentVariable
	ArrayAppend(_YourOpenbox.ContentStack, StructNew());
	
	// i set a position for this ContentVariable in the ContentStack
	i=ArrayLen(_YourOpenbox.ContentStack);
	
	// i set YourOpenbox.ThisContentVariable.Name
	if(Len(arguments.ContentVariableName)){
		YourOpenbox.ThisContentVariable.Name=arguments.ContentVariableName;
	} else {
		YourOpenbox.ThisContentVariable.Name=_GetContentVariableName();
	}
	
	// i set this dimension's properties
	_YourOpenbox.ContentStack[i]["ContentVariable"]["Name"]=YourOpenbox.ThisContentVariable.Name;
	_YourOpenbox.ContentStack[i]["IsContentChange"]=true;
	_YourOpenbox.ContentStack[i]["PushToDimension"]=0;
	
	// if force is False, i'll provide the opportunity to inherit another ContentVariable
	if(NOT arguments.IsForce){
		// i determine how to process the Content call
		if(
			i GT 1 
			AND _YourOpenbox.ContentStack[i - 1]["ContentVariable"]["Name"] EQ YourOpenbox.ThisContentVariable.Name
		){
			// i set IsContentChange to signal that i will be inherited by the current content variable
			_YourOpenbox.ContentStack[i]["IsContentChange"]=false;
		} else if(i GTE 3){
			// i loop through the ContentStack and check for identical ContentVariables
			for(j=i - 2; j GTE 1; j=j - 1){
				// if i find an identical ContentVariable
				if(_YourOpenbox.ContentStack[j]["ContentVariable"]["Name"] EQ YourOpenbox.ThisContentVariable.Name
					AND ListFindNoCase("FAVs", ListFirst(YourOpenbox.ThisContentVariable.Name, ".")) EQ 0){
					// ...i set a flag to the dimension below the last reference so that this ContentVariable's output will be inherited by the matching ContentVariable
					_YourOpenbox.ContentStack[i]["PushToDimension"]=j + 1;
					break;
				}
			}
		}
	}
	</cfscript>

</cffunction>

<cffunction name="_PopContentStack" 
	hint="." 
	output="yes" 
	returntype="void">
	
	<cfscript>
	// i initialize the local vars
	var i=ArrayLen(_YourOpenbox.ContentStack);
	</cfscript>

	<cfscript>
	// i reset ThisContentVariable or delete the current value
	if(_YourOpenbox.ContentStack[i]["IsContentChange"]){
		// if i should save the generated content into a different dimension of the ContentStack 
		if(_YourOpenbox.ContentStack[i]["PushToDimension"]){
			// ...i set the Content into the SecondaryContent of the PushToDimension position and reset ThisContentVariable
			_YourOpenbox.ContentStack[_YourOpenbox.ContentStack[i]["PushToDimension"]]["SecondaryContent"]=Evaluate(YourOpenbox.ThisContentVariable.Name);
			YourOpenbox.ThisContentVariable.Name=_YourOpenbox.ContentStack[i - 1]["ContentVariable"]["Name"];
		} else {
			// ...i set the generated content to the designated Variable and delete ThisContentVariable
			StructDelete(YourOpenbox, "ThisContentVariable");
		}
	} else {
		// i output the generated content directly and reset ThisContentVariable
		WriteOutput(Evaluate(YourOpenbox.ThisContentVariable.Name));
		YourOpenbox.ThisContentVariable.Name=_YourOpenbox.ContentStack[i - 1]["ContentVariable"]["Name"];
	}
	// i output the SecondaryContent (set from an inherited Content call)
	if(StructKeyExists(_YourOpenbox.ContentStack[i], "SecondaryContent")){
		WriteOutput(_YourOpenbox.ContentStack[i]["SecondaryContent"]);
	}
	// i remove the temporary generated content, the current dimension from the ContentStack, and the position in the ContentStack
	ArrayDeleteAt(_YourOpenbox.ContentStack, i);
	</cfscript>

</cffunction>

<cffunction name="_PushToPhaseStack" 
	hint="." 
	output="no" 
	returntype="void">
	
	<cfargument name="DoFuseAction" type="struct" default="#StructNew()#">
	<cfargument name="IsSetSuper" type="boolean" default="false">
	
	<cfscript>
	// i initialize the local vars
	var i=0;
	</cfscript>
	
	<cfscript>
	// i insert a new row into the ActionStack
	ArrayAppend(_YourOpenbox.ActionStack, StructNew());
	i=ArrayLen(_YourOpenbox.ActionStack);
	
	// i include PassThrough variables (if assigned)
	if(StructKeyExists(arguments.DoFuseAction, "PassThroughs")){
		_YourOpenbox.ActionStack[i]["PassThroughs"]=arguments.DoFuseAction.PassThroughs;
	}
	
	// i process the YourOpenbox, Circuit, and FuseAction variables
	if(StructKeyExists(YourOpenbox, "ThisPhase")){
		_YourOpenbox.ActionStack[i]["ThisPhase"]=YourOpenbox.ThisPhase;
	}
	if(StructKeyExists(YourOpenbox, "CallerCircuit")){
		_YourOpenbox.ActionStack[i]["CallerCircuit"]=YourOpenbox.CallerCircuit;
		StructDelete(YourOpenbox, "CallerCircuit");
	}
	if(StructKeyExists(YourOpenbox, "CallerFuseAction")){
		_YourOpenbox.ActionStack[i]["CallerFuseAction"]=YourOpenbox.CallerFuseAction;
		StructDelete(YourOpenbox, "CallerFuseAction");
	}	
	if(StructKeyExists(YourOpenbox, "ThisCircuit")){
		_YourOpenbox.ActionStack[i]["ThisCircuit"]=YourOpenbox.ThisCircuit;
		_YourOpenbox.Circuits[YourOpenbox.ThisCircuit.Name]["CRVs"]=CRVs;
		YourOpenbox.CallerCircuit=YourOpenbox.ThisCircuit;
		StructDelete(YourOpenbox, "ThisCircuit");
		StructDelete(variables, "CRVs");
	}	
	if(StructKeyExists(YourOpenbox, "ThisFuseAction")){
		_YourOpenbox.ActionStack[i]["ThisFuseAction"]=YourOpenbox.ThisFuseAction;
	}
	_YourOpenbox.ActionStack[i]["IsTargetCall"]=YourOpenbox.IsTargetCall;
	_YourOpenbox.ActionStack[i]["IsSuperCall"]=YourOpenbox.IsSuperCall;
	YourOpenbox.IsTargetCall=False;
	</cfscript>
	
</cffunction>

<cffunction name="_PopPhaseStack" 
	hint="." 
	output="no" 
	returntype="void">
	
	<cfscript>
	// i initialize the local vars
	var i=ArrayLen(_YourOpenbox.ActionStack);
	</cfscript>
	
	<cfscript>
	// i reinstate ThisPhase's, ThisCircuit's and ThisFuseAction's values from the ActionStack
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "ThisPhase")){
		YourOpenbox.ThisPhase=_YourOpenbox.ActionStack[i]["ThisPhase"];
	}
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "ThisCircuit")){
		YourOpenbox.ThisCircuit=_YourOpenbox.ActionStack[i]["ThisCircuit"];
		CRVs=_YourOpenbox.Circuits[YourOpenbox.ThisCircuit.Name]["CRVs"];
	}
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "ThisFuseAction")){
		YourOpenbox.ThisFuseAction=_YourOpenbox.ActionStack[i]["ThisFuseAction"];
	}
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "CallerCircuit")){
		YourOpenbox.CallerCircuit=_YourOpenbox.ActionStack[i]["CallerCircuit"];
	} else if(StructKeyExists(YourOpenbox, "CallerCircuit")){
		StructDelete(YourOpenbox, "CallerCircuit");
	}
	if(StructKeyExists(_YourOpenbox.ActionStack[i], "CallerFuseAction")){
		YourOpenbox.CallerFuseAction=_YourOpenbox.ActionStack[i]["CallerFuseAction"];
	} else if(StructKeyExists(YourOpenbox, "CallerFuseAction")){
		StructDelete(YourOpenbox, "CallerFuseAction");
	}
	YourOpenbox.IsTargetCall=_YourOpenbox.ActionStack[i]["IsTargetCall"];
	YourOpenbox.IsSuperCall=_YourOpenbox.ActionStack[i]["IsSuperCall"];
	
	// i remove the instance from the ActionStack
	ArrayDeleteAt(_YourOpenbox.ActionStack, i);
	</cfscript>
	
</cffunction>
