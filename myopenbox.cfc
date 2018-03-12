<cfcomponent displayname="MyOpenbox" 
	hint="I am the core file for the MyOpenbox framework.">
	
	<!--- 
	/////////////////////////////////// MYOPENBOX LICENSE (BETA) //////////////////////////////////
	// MyOpenbox authored by Tyler Silcox.
	// Please send all questions, comments, and suggestions to MyOpenbox@gmail.com.
	// Made in the U.S.A.
	///////////////////////////////////////////////////////////////////////////////////////////////
	 --->
	
	<cffunction name="Init" 
    	access="public" 
    	hint="I initialize this component." 
    	output="false" 
    	returntype="struct">
    	<cfargument name="Configuration" type="struct" default="#StructNew()#" />
    	
    	<cfscript>
		// i set the Version information
		this.Version.Number="0";
		this.Version.BuildNumber="067";
		this.Version.BuildDate="2017.10.26";
		this.Configuration=arguments.Configuration;
		this.Logs=StructNew();
		this.Logs.Actions=QueryNew("timestamp,action,type,time,info", "timestamp,varchar,varchar,integer,varchar");
		this.Cache=StructNew();
		this.Cache.Agents=StructNew();

		this.FileExistsCache=StructNew();
		</cfscript>
		
		<cfset this.LogAction("CFC Init()", "FW") />
		
		<cfparam name="this.Configuration.ApplicationRootPath" default="#GetDirectoryFromPath(GetCurrentTemplatePath())#../" />
		<cfparam name="this.Configuration.ApplicationConfigurationPath" default="#GetDirectoryFromPath(GetCurrentTemplatePath())#../" />
		<cfparam name="this.Configuration.ApplicationConfigurationFile" default="#this.Configuration.ApplicationConfigurationPath#cfg.myopenbox.cfm" />
		<cfparam name="this.Configuration.SetupConfigurationPath" default="#GetDirectoryFromPath(GetCurrentTemplatePath())#" />
		<cfparam name="this.Configuration.SetupConfigurationFile" default="#this.Configuration.SetupConfigurationPath#config.cfm" />
		
		<cfreturn this>
    
    </cffunction>
    
    <cffunction name="AddCacheAgent" access="public" output="false">
    	<cfargument name="name" default="Default" />
    	<cfargument name="agent" default="#NewCacheAgent().init(AgentName=arguments.Name, Context='application')#" />
    	<cfset this.Cache.Agents[arguments.Name]=arguments.agent />
    </cffunction>
    
    <cffunction name="NewCacheAgent" access="public" output="false">
    	<cfreturn CreateObject('component', 'cachebox.cacheboxagent') />
    </cffunction>
    
    <cffunction name="GetCacheAgent" access="public" output="false">
    	<cfargument name="name" default="" />
    	<cfreturn this.Cache.Agents[arguments.name] />
    </cffunction>
    
    <cffunction name="IsFWReinit" 
		access="public"
		output="false" 
		returntype="boolean">
		
		<cfparam name="form" default="#StructNew()#">
		<cfparam name="url"	 default="#StructNew()#">
		
		<cfreturn NOT IsDefined("application.Myopenbox.Parameters.FWReinit") OR (StructKeyExists(url, "FWReinit") AND IsDefined("application.Myopenbox.Parameters.FWReinit") AND url.FWReinit EQ application.Myopenbox.Parameters.FWReinit) OR (StructKeyExists(form, "FWReinit") AND IsDefined("application.Myopenbox.Parameters.FWReinit") AND form.FWReinit EQ application.Myopenbox.Parameters.FWReinit) />
	</cffunction>
	
	<cffunction name="IsFWReparse" 
		access="public"
		output="false" 
		returntype="boolean">
		
		<cfparam name="form" default="#StructNew()#">
		<cfparam name="url"	 default="#StructNew()#">
		
		<cfreturn (StructKeyExists(url, "FWReparse") AND IsDefined("application.Myopenbox.Parameters.FWReparse") AND url.FWReparse EQ application.Myopenbox.Parameters.FWReparse) OR (StructKeyExists(form, "FWReparse") AND IsDefined("application.Myopenbox.Parameters.FWReparse") AND form.FWReparse EQ application.Myopenbox.Parameters.FWReparse) />
	</cffunction>
	
	<cffunction name="IsFWAction" 
		access="public"
		output="false" 
		returntype="boolean">
		
		<cfparam name="form" default="#StructNew()#">
		<cfparam name="url"	 default="#StructNew()#">
		
		<cfreturn (StructKeyExists(url, "FWAction") AND IsDefined("application.Myopenbox.Parameters.FWReparse") AND url.FWAction EQ application.Myopenbox.Parameters.FWReparse) OR (StructKeyExists(form, "FWAction") AND IsDefined("application.Myopenbox.Parameters.FWReparse") AND form.FWAction EQ application.Myopenbox.Parameters.FWReparse) />
	</cffunction>
	
	<!--- cffunction name="RUNMYOPENBOX METHODS" --->
	
	<cffunction name="RunMyOpenbox" 
		access="public" 
		hint="I parse and create the MyOpenbox memory variables from the XML configuration files." 
		output="false" 
		returntype="void">
		
		<cfargument name="ApplicationConfigurationFile" type="string" default="#this.Configuration.ApplicationConfigurationFile#">
		
		<cfscript>
		// i initialize the local vars
		local.RawXML=Read(arguments.ApplicationConfigurationFile);
		local.HashKey=Hash(local.RawXML);
		</cfscript>
		
		<!--- i determine if i should parse the MyOpenbox --->
		<cfif NOT StructKeyExists(this, "Parameters") 
			OR this.Parameters.ProcessingMode EQ "Development" 
			OR NOT StructKeyExists(this, "ApplicationConfigurationFileHashKey")
			OR this.ApplicationConfigurationFileHashKey NEQ local.HashKey 
			OR (
				StructKeyExists(url, "FWReparse") 
				AND url.FWReparse EQ this.Parameters.FWReparse
			)>
			<!--- i lock the parsing of the MyOpenbox --->
			<cflock name="#Hash(GetCurrentTemplatePath() & "_RunMyOpenbox")#" timeout="10">
				<!--- i (re)determine if i should parse the MyOpenbox --->
				<cfif NOT StructKeyExists(this, "Parameters") 
					OR this.Parameters.ProcessingMode EQ "Development" 
					OR NOT StructKeyExists(this, "ApplicationConfigurationFileHashKey")
					OR this.ApplicationConfigurationFileHashKey NEQ local.HashKey 
					OR (
						StructKeyExists(url, "FWReparse") 
						AND url.FWReparse EQ this.Parameters.FWReparse
					)>
					<cflock name="#Hash(GetCurrentTemplatePath() & "_RunMyOpenbox_inner")#" timeout="10">
					
					<cfscript>
					// i create a TimeStamp
					this.TimeStamp=Now();
					// request.OpenboxReparseInitiated = true;
					// i parse the XML MyOpenbox configuration file(s)
					ParseApplicationConfigurationFiles(XMLParse(RawXML));
					// i create a Hash reference in this for checks against the MyOpenbox configuration file
					this.ApplicationConfigurationFileHashKey=local.HashKey;
					this.LogAction(action="MOBX Parsed", type="FW", info=local.HashKey);
					</cfscript>
<!---
					<cfif this.Parameters.ProcessingMode EQ "Deployment" AND (this.IsFWReparse() OR this.IsFWReinit())>
						<cfset CreateAllCircuitAndFuseactionFiles() />
					</cfif>
--->
					
					</cflock>
				</cfif>
			</cflock>
		</cfif>
		
		<cfscript>
		// i set the Log values
		if(this.Parameters.EnableLogs){
			this.Logs.MyOpenboxElapsedTime=Now() - this.TimeStamp;
			this.Logs.Requests.Total=this.Logs.Requests.Total + 1;
			this.Logs.Requests.LastRequested=Now();
		}
		</cfscript>
	
	</cffunction>
	
	<cffunction name="ParseApplicationConfigurationFiles" 
		access="private" 
		hint="I parse the MyOpenbox application and default setup configuration files." 
		output="true" 
		returntype="void">
		
		<cfargument name="ApplicationDeclarations" type="any">
		<cfargument name="SetupConfigurationFile" type="string" default="#this.Configuration.SetupConfigurationFile#">
		
		<cfscript>
		// i initialize the local vars
		var SetupDeclarations=XMLParse(Read(arguments.SetupConfigurationFile));
		var TickCount=GetTickCount();
		var i="";
		var CircuitRootArray=ArrayNew(1);
		</cfscript>
		
		<cfscript>
		// i set default Log values
		this.Logs.ProcessingTime=StructNew();
		
		// i set Parameters
		this.Parameters=ParseParameters(SetupDeclarations.XMLRoot.parameters, true);
		if(StructKeyExists(arguments.ApplicationDeclarations.XMLRoot, "parameters")){
			StructAppend(this.Parameters, ParseParameters(arguments.ApplicationDeclarations.XMLRoot.parameters));
		}
		
		// i check the EnableLogs Parameter
		if(this.Parameters.EnableLogs){
			this.Logs.Inventory.Circuits=0;
			this.Logs.Inventory.FuseActions=0;
			this.Logs.Requests.Total=0;
			this.Logs.Requests.FileBuilds=0;
		} else {
			StructDelete(this, "Logs");
		}
		
		// i set Verbs
		this.Verbs=ParseVerbs(SetupDeclarations.XMLRoot.verbs, true);
		if(StructKeyExists(arguments.ApplicationDeclarations.XMLRoot, "verbs")){
			StructAppend(this.Verbs, ParseVerbs(arguments.ApplicationDeclarations.XMLRoot.verbs));
		}
		
		// i set Phases
		if(StructKeyExists(arguments.ApplicationDeclarations.XMLRoot, "phases")){
			this.Phases=ParsePhases(arguments.ApplicationDeclarations.XMLRoot.phases);
		} else {
			this.Phases=StructNew();
		}
		this.CustomPhases=ArrayNew(1);
		
		this.Circuits=StructNew();
		// i set Circuits
		CircuitRootArray=ListToArray(this.Parameters.CircuitRootPaths, ",");
		for(i=1; i LTE ArrayLen(CircuitRootArray); i=i+1){
			StructAppend(this.Circuits, ParseCircuits(this.Configuration.ApplicationRootPath & CircuitRootArray[i], CircuitRootArray[i]), true);
		}
		
		//this.Circuits=ParseCircuits();
		
		// i create the application level Phases' files
		CreatePhaseFiles(this.Parameters.ApplicationPhases);
		
		// i create the Settings file
		if(StructKeyExists(arguments.ApplicationDeclarations.XMLRoot, "settings")){
			// i create an empty Settings struct for checking existence
			this.Settings=StructNew();
			// i create the file
			CreateSettingsFile(type="MyOpenbox", currentNode=arguments.ApplicationDeclarations.XMLRoot.settings, filePath=this.Configuration.ApplicationConfigurationPath);
		}
		
		// i create the Routes file
		this.Routes=CreateObject("component", "SES");
		this.Routes.configure();
		if(StructKeyExists(arguments.ApplicationDeclarations.XMLRoot, "routes")){
			// i create the file
			CreateRoutesFile("MyOpenbox", arguments.ApplicationDeclarations.XMLRoot.routes);
		}
		
		// i store the parsed Configuration XML
		if(this.Parameters.StoreXML){
			this.ConfigurationFile.XML=arguments.ApplicationDeclarations;
		}
		
		// i set a total ProcessingTime
		if(this.Parameters.EnableLogs){
			this.Logs.ProcessingTime.ParseConfigurationFiles=GetTickCount() - TickCount;
		}
		</cfscript>
	
	</cffunction>
	
	<cffunction name="ParseParameters" 
		access="private" 
		hint="I parse out the MyOpenbox Parameters." 
		output="false" 
		returntype="struct">
		
		<cfargument name="CurrentNode" type="any">
		<cfargument name="IsConfiguration" type="boolean" default="false">
		
		<cfscript>
		// i initialize the local vars 
		var Parameters=StructNew();
		var ParameterName="";
		var i=0;
		var ThrowError=0;
		var TickCount=GetTickCount();
		</cfscript>
		
		<cfscript>		
		// i parse Parameter elements
		for(i=1; i LTE ArrayLen(arguments.CurrentNode.XMLChildren); i=i + 1){
			// i run any necessary checks or provide a lookout for aliases
			switch(arguments.CurrentNode.Parameter[i]["XMLAttributes"]["name"]){
				case "ProcessingMode" :
					ParameterName="ProcessingMode";
					if(arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"] EQ "Development" OR arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"] EQ "1"){
						arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"]="Development";
					} else if(arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"] EQ "Production" OR arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"] EQ "0"){
						arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"]="Production";
					} else if(arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"] EQ "Deployment" OR arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"] EQ "-1"){
						arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"]="Deployment";
					} else {
						// i throw an error if you pass in a crappy value
						ThrowError=True;
					}
					break;
					
				case "DirectoryDelimiters" :
					ParameterName="Delimiters.Directory";
					break;
					
				case "NewLineDelimiters" :
					ParameterName="Delimiters.NewLine";
					break;
					
				case "TabDelimiters" :
					ParameterName="Delimiters.Tab";
					break;
					
				case "DefaultFileExtensionDelimiters" : case "ScriptFileDelimiter" :
					ParameterName="Delimiters.DefaultFileExtension";
					break;
					
				case "MaskedFileExtensionsDelimiters" : case "MaskedFileDelimiters" :
					ParameterName="Delimiters.MaskedFileExtensions";
					break;
				
				case "SelfFolder" :
					ParameterName="Self.Folder";
					break;
				case "SelfPath" :
					ParameterName="Self.Path";
					break;
				case "SelfRootPath" :
					ParameterName="Self.RootPath";
					break;
				
				case "CacheFolder" :
					ParameterName="Cache.Folder";
					break;
				case "CachePath" :
					ParameterName="Cache.Path";
					break;
				case "CachePathExpandPath" :
					ParameterName="Cache.PathExpandPath";
					break;
				case "CacheRootPath" :
					ParameterName="Cache.RootPath";
					break;
				
				case "DictionaryFolder" :
					ParameterName="Dictionary.Folder";
					break;
				case "DictionaryPath" :
					ParameterName="Dictionary.Path";
					break;
				case "DictionaryRootPath" :
					ParameterName="Dictionary.RootPath";
					break;
				
				case "ParseWithComments" :
					if(IsBoolean(arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"])){
						ParameterName="ParseWithComments";
					} else {
						// i throw an error if you pass in a crappy value
						ThrowError=True;
					}
					break;
				
				case "PrecedenceFormOrURL" :
					if(ListFindNoCase("form,url", arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"])){
						ParameterName="PrecedenceFormOrURL";
					} else {
						// i throw an error if you pass in a crappy value
						ThrowError=True;
					}
					break;
				
				case "StoreXML" :
					if(IsBoolean(arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"])){
						ParameterName="StoreXML";
					} else {
						// i throw an error if you pass in a crappy value
						ThrowError=True;
					}
					break;
				case "DashboardEnable" :
					ParameterName="Dashboard.Enable";
					break;
				
				default :
					ParameterName=arguments.CurrentNode.Parameter[i]["XMLAttributes"]["name"];
					break;
			}
			// i check for any errors
			if(ThrowError){
				Throw("MyOpenbox", "Error while processing MyOpenbox configuration parameter """ & arguments.CurrentNode.Parameter[i]["XMLAttributes"]["Name"] & """.", "Please make sure all required attributes are included and valid in each parameter in the MyOpenbox configuration file.");
			}
			// i set the Parameter
			if(
				StructKeyExists(arguments.CurrentNode.Parameter[i]["XMLAttributes"], "evaluate") 
				AND arguments.CurrentNode.Parameter[i]["XMLAttributes"]["evaluate"]
			){
				SetVariable("Parameters." & ParameterName, Evaluate(arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"]));
			} else {
				SetVariable("Parameters." & ParameterName, arguments.CurrentNode.Parameter[i]["XMLAttributes"]["value"]);
			}
		}
		
		// LOGS: i set a Logs.ProcessingTime value
		if(arguments.IsConfiguration){
			this.Logs.ProcessingTime.ParseParameters=GetTickCount() - TickCount;
		} else if(this.Parameters.EnableLogs){
			this.Logs.ProcessingTime.ParseParameters=GetTickCount() - TickCount + this.Logs.ProcessingTime.ParseParameters;
		}
		</cfscript>
		
		<cfreturn Parameters>
	
	</cffunction>
	
	<cffunction name="ParseVerbs" 
		access="private" 
		hint="I parse out the MyOpenbox configuration XML Verbs." 
		output="false" 
		returntype="struct">
		
		<cfargument name="CurrentNode" type="any">
		<cfargument name="IsConfiguration" type="boolean" default="false">
		
		<cfscript>
		// i initialize the local vars
		var Verbs=StructNew();
		var i=0;
		var TickCount=GetTickCount();
		</cfscript>
		
		<cfscript>
		// i loop through the children elements
		for(i=1; i LTE ArrayLen(arguments.CurrentNode.XMLChildren); i=i + 1){
			StructAppend(Verbs, ParseVerb(arguments.CurrentNode.XMLChildren[i], arguments.IsConfiguration));
		}
		
		// LOGS: i set a Logs.ProcessingTime value
		if(this.Parameters.EnableLogs){
			if(arguments.IsConfiguration){
				this.Logs.ProcessingTime.ParseVerbs=GetTickCount() - TickCount;
			} else {
				this.Logs.ProcessingTime.ParseVerbs=GetTickCount() - TickCount + this.Logs.ProcessingTime.ParseVerbs;
			}
		}
		</cfscript>
		
		<cfreturn Verbs>
		
	</cffunction>
	
	<cffunction name="ParseVerb" 
		access="private" 
		hint="." 
		output="false" 
		returntype="struct">
		
		<cfargument name="CurrentNode" type="any" default="">
		<cfargument name="IsConfiguration" type="boolean" default="false">
		
		<cfscript>
		// i initialize the local vars 
		var Verb=StructNew();
		var VerbName="";
		</cfscript>
		
		<cfscript>
		if(arguments.CurrentNode.XMLName NEQ "verb"){
			// THROW ERROR - invalid element in Verbs assignment
		}
		
		VerbName=arguments.CurrentNode.XMLAttributes.name;
		if(StructKeyExists(arguments.CurrentNode.XMLAttributes, "template")){
			Verb[VerbName]["Template"]=LCase(arguments.CurrentNode.XMLAttributes.template);
		} else {
			Verb[VerbName]["Template"]=LCase(VerbName);
		}
		if(StructKeyExists(arguments.CurrentNode.XMLAttributes, "path")){
			Verb[VerbName]["Path"]=arguments.CurrentNode.XMLAttributes.path;
		}
		if(NOT arguments.IsConfiguration){
			Verb[VerbName]["IsCustom"]=true;
		}
		</cfscript>
		
		<cfreturn Verb>
		
	</cffunction>
	
	<cffunction name="ParsePhases" 
		access="private" 
		hint="I parse out the MyOpenbox configuration XML Phases." 
		output="false" 
		returntype="struct">
		
		<cfargument name="CurrentNode" type="any">
		
		<cfscript>
		// i initialize the local vars 
		var Phases=StructNew();
		var PhaseName="";
		var i=0;
		var TickCount=GetTickCount();
		</cfscript>
		
		<cfscript>
		// i loop through the XMLChilden
		for(i=1; i LTE ArrayLen(arguments.CurrentNode.XMLChildren); i=i + 1){
			// i set PhaseName
			if(StructKeyExists(arguments.CurrentNode.XMLChildren[i].XMLAttributes, "title") AND NOT StructKeyExists(arguments.CurrentNode.XMLChildren[i].XMLAttributes, "name")){
				PhaseName=FilterString(arguments.CurrentNode.XMLChildren[i].XMLAttributes.title);
			} else {
				PhaseName=arguments.CurrentNode.XMLChildren[i].XMLAttributes.name;
			}
			
			Phases[PhaseName]=ArrayNew(1);
			Phases[PhaseName][1]["Commands"]=Duplicate(arguments.CurrentNode.XMLChildren[i]["XMLChildren"]);
		}
		// LOGS: i set a Logs.ProcessingTime value
		if(this.Parameters.EnableLogs){
			this.Logs.ProcessingTime.ParsePhases=GetTickCount() - TickCount;
		}
		</cfscript>
		
		<cfreturn Phases>
	
	</cffunction>
	
	<cffunction name="ParseCircuits" 
		access="private" 
		hint="I parse out the MyOpenbox circuits." 
		output="false" 
		returntype="struct">
		
		<cfargument name="TargetDirectory" default="#GetDirectoryFromPath(GetBaseTemplatePath())#" type="string">
		<cfargument name="DirectoryPath" default="" type="string">
		<cfargument name="ParentName" default="" type="string">
		
		<cfscript>
		// i initialize the local vars
		var Circuits=StructNew();
		var Circuit="";
		var CircuitName="";
		var GetDirectorys="";
		var ConfigFileName="";
		var XML=StructNew();
		var IsContinue=True;
		var IsParseCircuit=True;
		var TickCount=GetTickCount();
		</cfscript>
		
		<cfdirectory name="GetDirectorys" 
			action="list" 
			directory="#arguments.TargetDirectory#">
		
		<cfloop query="GetDirectorys">
			
			<cfif GetDirectorys.Type EQ "Dir" 
				AND Left(GetDirectorys.Name, 1) NEQ "_">
		
				<cfset ConfigFileName=GetDirectorys.Name & this.Parameters.Delimiters.Directory & "cfg.circuit.cfm">
				
				<!--- if this is a directory that doesn't start with a "_" and contains a cfg.circuit file --->
				<cfif FileExists(arguments.TargetDirectory & ConfigFileName)>
					<!--- i read the configuration file --->
					<cfset XML.Raw=Read(arguments.TargetDirectory & ConfigFileName)>
					
					<!--- i attempt to parse the configuration file --->
					<cftry>
						<cfset XML.Parsed=XMLParse(XML.Raw)>
						<cfcatch type="any">
							<cfset IsContinue=False>
							<cfset Throw("MyOpenbox", "Error occured while parsing Circuit configuration file.", "The configuration file : " & ConfigFileName & " contains invalid XML. " & CFCatch.Detail, "Your configuration file must conform to XML specifications.  Please make sure all tags and attribute values are closed and that you are using entities where necessary. For example, you must use ""&amp;"" for Ampersand characters.")>
						</cfcatch>
					</cftry>
					
					<cfscript>
					// i parse the Circuit
					if(IsContinue){
						// i call ParseCircuit()
						Circuit=ParseCircuit(XML.Parsed.Circuit);
						// i check for Name and make CF recognize Circuit.Name (it seems CFMX 6.1 has a issue with keys named "Name")
						if(StructKeyExists(Circuit, "Name")){
							CircuitName=Circuit.Name;
						} else {
							Throw("MyOpenbox", "Error while parsing Circuit XML file.", "The configuration file located at : " & arguments.TargetDirectory & ConfigFileName & " does not contain a Name or Title definition.", "You must set either Name or Title in the Circuit configuration file.");
						}
						// i make sure there are not any duplicate Circuit Names in this directory
						if(StructKeyExists(Circuits, CircuitName)){
							Throw("MyOpenbox", "Error while parsing Circuit XML file.", "The configuration file located at : " & arguments.TargetDirectory & ConfigFileName & " contains a Circuit Name and/or Title that are already in use.", "Duplicate Circuit Name: " & CircuitName);
						} else {
							// i set the parsed Circuit info
							Circuits[CircuitName]=Circuit;
						}
						// i set ParentName (if it is not already set in ParseCircuit)
						if(Len(arguments.ParentName) AND NOT StructKeyExists(Circuits[CircuitName], "ParentName")){
							Circuits[CircuitName]["ParentName"]=arguments.ParentName;
						}
						Circuits[CircuitName]["DateLastModified"]=GetDirectorys.DateLastModified;
						Circuits[CircuitName]["DirectoryPath"]=arguments.DirectoryPath & GetDirectorys.Name & "/";
						Circuits[CircuitName]["RootPath"]=RepeatString("../", ListLen(Circuits[CircuitName]["DirectoryPath"], "/"));
						Circuits[CircuitName]["ConfigFileName"]=ConfigFileName;
						
						// i set Inventory.Circuits + 1
						if(this.Parameters.EnableLogs){
							this.Logs.Inventory.Circuits=this.Logs.Inventory.Circuits + 1;
						}
						
						// i recurse the directory
						StructAppend(Circuits, ParseCircuits(arguments.TargetDirectory & GetDirectorys.Name & this.Parameters.Delimiters.Directory, arguments.DirectoryPath & GetDirectorys.Name & "/", CircuitName), "No");
					}
					</cfscript>
				</cfif>
			</cfif>
		
		</cfloop>
		
		<cfscript>
		// LOGS: i set a Logs.ProcessingTime value
		if(this.Parameters.EnableLogs){
			this.Logs.ProcessingTime.ParseCircuits=GetTickCount() - TickCount;
		}
		</cfscript>
		
		<cfreturn Circuits>
	
	</cffunction>
	
	<cffunction name="ParseCircuit" 
		access="private" 
		hint="I parse out each circuit's components." 
		output="false" 
		returntype="struct">
		
		<cfargument name="CircuitNode" type="any">
		
		<cfscript>
		// i initialize the local vars
		var Circuit=StructNew();
		var Attribute="";
		var CurrentNode="";
		var CurrentFuseAction="";
		var Phases="";
		var i=0;
		var j=0;
		</cfscript>
		
		<cfscript>
		// i set this Circuit's attributes
		Circuit["Access"]="Public";
		if(StructKeyExists(arguments.CircuitNode.XMLAttributes, "Access") AND ListFindNoCase(this.Parameters.AccessList, arguments.CircuitNode.XMLAttributes["Access"])){
			Circuit.Access=arguments.CircuitNode.XMLAttributes["Access"];
		}
		// i set Name and Title
		if(StructKeyExists(arguments.CircuitNode.XMLAttributes, "name") AND StructKeyExists(arguments.CircuitNode.XMLAttributes, "title")){
			Circuit["Name"]=arguments.CircuitNode.XMLAttributes["name"];
			Circuit["Title"]=arguments.CircuitNode.XMLAttributes["title"];
		} else if(StructKeyExists(arguments.CircuitNode.XMLAttributes, "title")){
			Circuit["Name"]=FilterString(arguments.CircuitNode.XMLAttributes["title"]);
			Circuit["Title"]=arguments.CircuitNode.XMLAttributes["title"];
		} else if(StructKeyExists(arguments.CircuitNode.XMLAttributes, "name")){
			Circuit["Name"]=arguments.CircuitNode.XMLAttributes["name"];
		} else {
			// [!]ERROR HANDLING[!] Throw("MyOpenbox", "Error while processing Circuit configuration file.", "The Title and/or Name attributes need to be declared in the root element of ???.", "I dunno?");
		}
		// i set Parent
		if(StructKeyExists(arguments.CircuitNode.XMLAttributes, "parent")){
			Circuit["ParentName"]=arguments.CircuitNode.XMLAttributes["parent"];
		}
		// i set any other attributes
		for(Attribute IN arguments.CircuitNode.XMLAttributes){
			// i prevent any attributes from overwriting the Reserved Circuit Attributes
			if(NOT ListFindNoCase(this.Parameters.ReservedCircuitAttributes, Attribute)){
				Circuit[Attribute]=arguments.CircuitNode.XMLAttributes[Attribute];
			}
		}
		// i set the XML into the Circuit
		if(this.Parameters.StoreXML) Circuit.XML=arguments.CircuitNode;
		
		// i check/set a empty struct for FuseActions and Phases
		Circuit["FuseActions"]=StructNew();
		
		// i set this Circuit's sub-elements defined values
		for(i=1; i LTE ArrayLen(arguments.CircuitNode.XMLChildren); i=i + 1){
			// i route the child elements of this Circuit
			switch(arguments.CircuitNode.XMLChildren[i]["XMLName"]){					
				// i parse FuseAction elements
				case "fuseaction" :
					StructAppend(Circuit.FuseActions, ParseFuseAction(arguments.CircuitNode.XMLChildren[i], Circuit));
					break;
						
				// i parse the FuseActions element
				case "fuseactions" :
					// i loop through the child elements
					for(j=1; j LTE ArrayLen(arguments.CircuitNode.XMLChildren[i].XMLChildren); j=j + 1){
						// i route the child elements
						switch(arguments.CircuitNode.XMLChildren[i].XMLChildren[j]["XMLName"]){
							case "fuseaction" :
								// i parse the FuseAction
								StructAppend(Circuit.FuseActions, ParseFuseAction(arguments.CircuitNode.XMLChildren[i].XMLChildren[j], Circuit));
								break;
						}
					}
					break;
				
				// i parse the Phases element
				case "phases" :
					Circuit["Phases"]=ParseCircuitPhases(arguments.CircuitNode.XMLChildren[i], Circuit.Name);
					break;
				
				// i save the Settings element
				case "settings" :
					// i create an empty Settings struct for checking existence
					Circuit["Settings"]=StructNew();
					// i save the XML for parsing during Circuit calls
					Circuit["SettingsXML"]=arguments.CircuitNode.XMLChildren[i];
					break;
			}
		}
		</cfscript>
		
		<cfreturn Circuit>
	
	</cffunction>
	
	<cffunction name="ParseFuseAction" 
		access="private" 
		hint="I parse out the MyOpenbox configuration XML Phases." 
		output="false" 
		returntype="struct">
		
		<cfargument name="CurrentNode" type="any">
		<cfargument name="Circuit" type="any">
		
		<cfscript>
		// i initialize the local vars
		var FuseAction=StructNew();
		var FuseActionName="";
		var Attribute="";
		</cfscript>
		
		<cfscript>
		// i set Name and Title
		if(StructKeyExists(arguments.CurrentNode.XMLAttributes, "title")){
			if(StructKeyExists(arguments.CurrentNode.XMLAttributes, "name")){
				FuseActionName=arguments.CurrentNode.XMLAttributes["name"];
			} else {
				FuseActionName=FilterString(arguments.CurrentNode.XMLAttributes["title"]);
			}
			FuseAction[FuseActionName]["Name"]=FuseActionName;
			FuseAction[FuseActionName]["Title"]=arguments.CurrentNode.XMLAttributes["title"];
		} else if(StructKeyExists(arguments.CurrentNode.XMLAttributes, "name")){
			FuseActionName=arguments.CurrentNode.XMLAttributes["name"];
			FuseAction[FuseActionName]["Name"]=FuseActionName;
		} else {
			// [!]ERROR HANDLING[!] Throw("MyOpenbox", "Error while processing Circuit configuration file.", "The Title and/or Name attributes need to be declared in the each FuseAction element of ???.", "I dunno?");
		}
		
		// i set this element's XML Commands
		FuseAction[FuseActionName]["Commands"]=arguments.CurrentNode["XMLChildren"];
		
		// i loop through this element's attributes
		for(Attribute IN arguments.CurrentNode.XMLAttributes){
			// i prevent any attributes from overwriting the Reserved FuseAction Attributes
			if(NOT ListFindNoCase(this.Parameters.ReservedFuseActionAttributes, Attribute)){
				FuseAction[FuseActionName][Attribute]=arguments.CurrentNode["XMLAttributes"][Attribute];
			}
		}
		
		// i set this element's Access to inherit this Circuit's Access if not defined or is an illegal value
		if(NOT StructKeyExists(FuseAction[FuseActionName], "Access") OR NOT ListFindNoCase(this.Parameters.AccessList, FuseAction[FuseActionName]["Access"])){
			FuseAction[FuseActionName]["Access"]=arguments.Circuit.Access;
		}
		
		// i set FuseActions
		if(this.Parameters.EnableLogs){
			this.Logs.Inventory.FuseActions=this.Logs.Inventory.FuseActions + 1;
		}
		</cfscript>
		
		<cfreturn FuseAction>
	
	</cffunction>
	
	<cffunction name="ParseCircuitPhases" 
		access="private" 
		hint="I parse out the MyOpenbox configuration XML Phases." 
		output="false" 
		returntype="struct">
		
		<cfargument name="PhaseDeclarations" type="any">
		<cfargument name="CircuitName" type="string">
		
		<cfscript>
		// i initialize the local vars 
		var CurrentNode="";
		var CurrentPhase=StructNew();
		var Phases=StructNew();
		var PhaseName="";
		var i=0;
		var Attribute="";
		</cfscript>
		
		<cfscript>
		// i loop through the XMLChilden
		for(i=1; i LTE ArrayLen(arguments.PhaseDeclarations.XMLChildren); i=i + 1){
			// i set a reference for the current node
			CurrentNode=arguments.PhaseDeclarations.XMLChildren[i];
			
			// i set PhaseName
			if(StructKeyExists(CurrentNode.XMLAttributes, "title") AND NOT StructKeyExists(CurrentNode.XMLAttributes, "name")){
				PhaseName=FilterString(CurrentNode.XMLAttributes.title);
			} else {
				PhaseName=CurrentNode.XMLAttributes.name;
			}
			
			// i set a reference to the Phase into the return Circuit Phases structure
			if(ListFindNoCase(this.Parameters.CircuitPhases, PhaseName)){
				Phases[PhaseName]["Attributes"]=CurrentNode["XMLAttributes"];
				Phases[PhaseName]["Commands"]=CurrentNode["XMLChildren"];
			} else {
				// if the target Phase does not exist yet
				if(NOT StructKeyExists(this.Phases, PhaseName) OR NOT IsArray(this.Phases[PhaseName])){
					// ...i create the empty array
					this.Phases[PhaseName]=ArrayNew(1);
					ArrayAppend(this.CustomPhases, PhaseName);
				}
				// i set the CircuitName
				this.Phases[PhaseName][ArrayLen(this.Phases[PhaseName]) + 1]["CircuitName"]=arguments.CircuitName;
				// i set the Commands					
				this.Phases[PhaseName][ArrayLen(this.Phases[PhaseName])]["Commands"]=CurrentNode["XMLChildren"];
			}
		}
		</cfscript>
		
		<cfreturn Phases>
	
	</cffunction>
	
	<cffunction name="CreateAllCircuitAndFuseactionFiles"
		access="public"
		output="false"
		returnType="void">
		<cfscript>
		var CircuitValue="";
		var FuseValue="";
		</cfscript>
		
		<cfloop collection="#this.Circuits#" item="CircuitValue">
			<cfset CreateCircuitFiles(this.Circuits[CircuitValue]) />
			<cfloop collection="#this.Circuits[CircuitValue]["Fuseactions"]#" item="FuseValue">
				<cfset CreateFuseActionFile(this.Circuits[CircuitValue], this.Circuits[CircuitValue]["Fuseactions"][FuseValue]) />
			</cfloop>
		</cfloop>
		<cfset CreatePhaseFiles(ArrayToList(this.CustomPhases, ",")) />
	</cffunction>
	
	<cffunction name="CreateCircuitFiles" 
		access="private" 
		hint="." 
		output="false" 
		returntype="void">
		
		<cfargument name="Circuit" type="struct">
		
		<cfscript>
		// i create the Settings file
		if(StructKeyExists(arguments.Circuit, "SettingsXML")){
			CreateSettingsFile("Circuit", arguments.Circuit.SettingsXML, arguments.Circuit.Name);
			StructDelete(arguments.Circuit, "SettingsXML");
		}
		// i create the Phase files
		if(StructKeyExists(arguments.Circuit, "Phases")){
			CreateCircuitPhaseFiles(arguments.Circuit);
		}
		// i set a TimeStamp to keep this Circuit current with MyOpenbox and to prevent duplicate/extra file writes
		arguments.Circuit["TimeStamp"]=this.TimeStamp;
		</cfscript>
		
	</cffunction>
	
	<cffunction name="ParseSettingValue" 
		access="private" 
		hint="." 
		output="false" 
		returntype="struct">
		
		<cfargument name="CurrentNode" type="any">
		
		<cfscript>
		var Setting=StructNew();
		var ThrowError=False;
		</cfscript>
				
		<cfscript>
		// i clear out the name/value holder Setting
		Setting=StructNew();
		// i check for Name
		if(StructKeyExists(arguments.CurrentNode["XMLAttributes"], "name")){
			Setting.Name=arguments.CurrentNode["XMLAttributes"]["name"];
		} else {
			ThrowError=True;
		}
		// i check for a Value
		if(StructKeyExists(arguments.CurrentNode["XMLAttributes"], "value")){
			Setting.Value=arguments.CurrentNode["XMLAttributes"]["value"];
		} else if(Len(arguments.CurrentNode["XMLText"])){
			Setting.Value=arguments.CurrentNode["XMLText"];
		} else {
			ThrowError=True;
		}
		// ERROR: i throw an error if necessary
		if(ThrowError){
			Throw("MyOpenbox", "Error while processing Settings.", "Please make sure all required attributes are included and valid in each Setting definition in the MyOpenbox configuration file.");
		}
		</cfscript>
		
		<cfreturn Setting>
		
	</cffunction>
	
	<cffunction name="CreateSettingsFile" 
		access="private" 
		hint="." 
		output="false" 
		returntype="void">
		
		<cfargument name="Type" type="string">
		<cfargument name="CurrentNode" type="any" default="">
		<cfargument name="CircuitName" type="string" default="">
		<cfargument name="FilePath" type="string" default="#GetDirectoryFromPath(GetBaseTemplatePath())#">
		
		<cfscript>
		// i initialize the local vars
		var GeneratedContent=CreateObject("java", "java.lang.StringBuffer").init();
		var ContainerVariable="";
		var FileName="";
		var Include=StructNew();
		var Setting=StructNew();
		var i=0;
		var ii=0;
		var NewLine=this.Parameters.Delimiters.NewLine;
		var TickCount=GetTickCount();
		</cfscript>
		
		<cfif this.Parameters.ProcessingMode NEQ "Deployment" OR (this.IsFWreparse() OR this.IsFWReinit())>
		
		<cfscript>
		if(arguments.Type EQ "MyOpenbox"){
			ContainerVariable=this.Parameters.MyOpenboxObjectVariable;
			FileName="settings";
		} else if(arguments.Type EQ "Circuit"){
			ContainerVariable=this.Parameters.MyOpenboxObjectVariable & ".Circuits." & arguments.CircuitName;
			FileName="settings." & arguments.CircuitName;
		}
		
		GeneratedContent.append(JavaCast("string", "<" & "cfsilent>" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "cfif StructIsEmpty(" & ContainerVariable & ".Settings)>" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "<" & "cflock name=""##Hash(GetCurrentTemplatePath())##_SetSettings"" timeout=""10"">" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(2) & "<" & "cfscript>" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(2) & "if(StructIsEmpty(" & ContainerVariable & ".Settings)){" & NewLine));
					GeneratedContent.append(JavaCast("string", Indent(3) & "// i create the designated Circuit's Settings" & NewLine));
					// i determine if arguments.CurrentNode is available
					if(IsXMLElem(arguments.CurrentNode) AND StructKeyExists(arguments.CurrentNode, "XMLChildren")){
						for(i=1; i LTE ArrayLen(arguments.CurrentNode.XMLChildren); i=i + 1){
							// if this is a Setting command
							if(arguments.CurrentNode.XMLChildren[i]["XMLName"] EQ "setting"){
								if(StructKeyExists(arguments.CurrentNode.XMLChildren[i]["XMLAttributes"], "include")){
									// i read and parse the settings file
									Include.FileName = arguments.FilePath & arguments.CurrentNode.XMLChildren[i]["XMLAttributes"]["include"] & ".cfm";
									Include.Raw = Read(Include.FileName);
									if(Len(Include.Raw)){
										Include.Parsed = XMLParse(Include.Raw);
										for(ii=1; ii LTE ArrayLen(Include.Parsed.XmlRoot.XMLChildren); ii=ii + 1){
											// i parse out the name and value
											Setting=ParseSettingValue(Include.Parsed.XmlRoot.XMLChildren[ii]);
											// i add the Setting definition to GeneratedContent
											GeneratedContent.append(JavaCast("string", Indent(3) & "SetVariable(""" & ContainerVariable & ".Settings." & Setting.Name & """, """ & Setting.Value & """);" & NewLine));
										}										
									}
								} else {
									// i parse out the name and value
									Setting=ParseSettingValue(arguments.CurrentNode.XMLChildren[i]);
									// i add the Setting definition to GeneratedContent
									GeneratedContent.append(JavaCast("string", Indent(3) & "SetVariable(""" & ContainerVariable & ".Settings." & Setting.Name & """, """ & Setting.Value & """);" & NewLine));
								}
							} else {
								// ERROR: i throw an error if necessary
								Throw("MyOpenbox", "Error while processing Settings.", "Please make sure only &lt;setting .../&gt; verbs are used in each Setting definition in the MyOpenbox configuration file.");
							}
						}
					}
				GeneratedContent.append(JavaCast("string", Indent(2) & "}" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(2) & "<" & "/cfscript>" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "<" & "/cflock>" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "/cfif>" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "/cfsilent>" & NewLine));
				
		// i set GeneratedContent to a string value so i can clean out any internal references
		GeneratedContent=GeneratedContent.ToString();
		// i replace any internal references in {}s
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{MyOpenbox}", this.Parameters.MyOpenboxObjectVariable, "all");
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{Circuits}", this.Parameters.MyOpenboxObjectVariable & ".Circuits", "all");
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{Parameters}", this.Parameters.MyOpenboxObjectVariable & ".Parameters", "all");
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{Phases}", this.Parameters.MyOpenboxObjectVariable & ".Phases", "all");
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{Settings}", ContainerVariable & ".Settings", "all");
		
		// i write the GeneratedContent to a file
		Write(FileName, GeneratedContent);
			
		// LOGS: i set a Logs.ProcessingTime value
		if(this.Parameters.EnableLogs){
			this.Logs.ProcessingTime.CreateSettingsFile[ListLast(ContainerVariable, ".")]=GetTickCount() - TickCount;
			this.Logs.Requests.FileBuilds=this.Logs.Requests.FileBuilds + 1;
		}
		</cfscript>
		
		</cfif>
		
	</cffunction>
	
	<cffunction name="CreateRoutesFile" 
		access="private" 
		hint="." 
		output="false" 
		returntype="void">
		
		<cfargument name="Type" type="string">
		<cfargument name="CurrentNode" type="any" default="">
		
		<cfscript>
		// i initialize the local vars
		var GeneratedContent=CreateObject("java", "java.lang.StringBuffer").init();
		var ContainerVariable="";
		var FileName="";
		var Route=StructNew();
		var i=0;
		var j=0;
		var NewLine=this.Parameters.Delimiters.NewLine;
		var ThrowError=False;
		var TickCount=GetTickCount();
		var Setting=StructNew();
		var att="";
		var v="";
		</cfscript>
		
		<cfif this.Parameters.ProcessingMode NEQ "Deployment" OR (this.IsFWreparse() OR this.IsFWReinit())>
		
		<cfscript>
		if(arguments.Type EQ "MyOpenbox"){
			ContainerVariable=this.Parameters.MyOpenboxObjectVariable;
			FileName="routes";
		}
		
		GeneratedContent.append(JavaCast("string", "<" & "cfsilent>" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "cfif ArrayLen(" & ContainerVariable & ".Routes.getRoutes()) EQ 0>" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "<" & "cflock name=""##Hash(GetCurrentTemplatePath())##_SetRoutes"" timeout=""10"">" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(2) & "<" & "cfscript>" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(2) & "if(ArrayLen(" & ContainerVariable & ".Routes.getRoutes()) EQ 0){" & NewLine));
					GeneratedContent.append(JavaCast("string", Indent(3) & "// i create the designated Routes" & NewLine));
					// i determine if arguments.CurrentNode is available
					if(IsXMLElem(arguments.CurrentNode) AND StructKeyExists(arguments.CurrentNode, "XMLChildren")){
						if(this.Parameters.EnableLogs){
							GeneratedContent.append(JavaCast("string", Indent(3) & "if(application.MyOpenbox.Parameters.EnableLogs) application.MyOpenbox.LogAction(""Adding Routes"");" ));

						}
						for(i=1; i LTE ArrayLen(arguments.CurrentNode.XMLChildren); i=i + 1){
							// if this is a Setting command
							if(arguments.CurrentNode.XMLChildren[i]["XMLName"] EQ "route"){
								// i clear out the name/value holder Setting
								Setting=StructNew();
								Setting.Vars=ArrayNew(1);
								// i check for Pattern
								if(StructKeyExists(arguments.CurrentNode.XMLChildren[i]["XMLAttributes"], "pattern")){
									Setting.Pattern=arguments.CurrentNode.XMLChildren[i]["XMLAttributes"]["pattern"];
								} else {
									ThrowError=True;
									Throw("MyOpenbox", "Error while processing Routes.", "No Pattern");
								}
								// i check for a Circuit
								if(StructKeyExists(arguments.CurrentNode.XMLChildren[i]["XMLAttributes"], "circuit")){
									Setting.Circuit=arguments.CurrentNode.XMLChildren[i]["XMLAttributes"]["circuit"];
								}
								// i check for a Fuse
								if(StructKeyExists(arguments.CurrentNode.XMLChildren[i]["XMLAttributes"], "fuse")){
									Setting.Fuse=arguments.CurrentNode.XMLChildren[i]["XMLAttributes"]["fuse"];
								}
								if(StructKeyExists(Setting, "Fuse") AND NOT StructKeyExists(Setting, "Circuit")) {
									ThrowError=True;
									Throw("MyOpenbox", "Error while processing Routes.", "Fuse with no circuit");
								}
								// set the vars for a route based on any attributes not already known
								for(att in arguments.CurrentNode.XMLChildren[i]["XMLAttributes"]) {
									if(NOT ListFindNoCase("circuit,fuse,pattern", att)) {
										v=StructNew();
										if(ListLen(att, ".") GT 1) {
											v.scope=Left(att, Len(att)-Len(ListLast(att, "."))-1);
											v.name=ListLast(att, ".");
										} else {
											v.scope="";
											v.name=att;
										}
										v.value=arguments.CurrentNode.XMLChildren[i]["XMLAttributes"][att];
										ArrayAppend(Setting.Vars, v);
									}
								}
								
								// ERROR: i throw an error if necessary
								if(ThrowError){
									Throw("MyOpenbox", "Error while processing Routes.", "Please make sure all required attributes are included and valid in each route definition in the MyOpenbox configuration file.");
								}
								
								// i add the Setting definition to GeneratedContent
								if(ArrayLen(Setting.Vars) GT 0) {
									GeneratedContent.append(JavaCast("string", "_vars=ArrayNew(1);" & NewLine));
									for(j=1; j LTE ArrayLen(Setting.Vars); j=j + 1) {
										GeneratedContent.append(JavaCast("string", "_var=StructNew();" & NewLine));
										GeneratedContent.append(JavaCast("string", "_var.Name=""" & Setting.Vars[j].Name & """;" & NewLine));
										GeneratedContent.append(JavaCast("string", "_var.Scope=""" & Setting.Vars[j].Scope & """;" & NewLine));
										GeneratedContent.append(JavaCast("string", "_var.Value=""" & Setting.Vars[j].Value & """;" & NewLine));
										GeneratedContent.append(JavaCast("string", "ArrayAppend(_vars, _var);" & NewLine));
									}
								}
								GeneratedContent.append(JavaCast("string", Indent(3) & ContainerVariable & ".Routes.addRoute(""" & Setting.Pattern) & """");
								if(StructKeyExists(Setting, "Circuit"))
									GeneratedContent.append(JavaCast("string", ",""" & Setting.Circuit & """"));
								if(StructKeyExists(Setting, "Fuse"))
									GeneratedContent.append(JavaCast("string", ",""" & Setting.Fuse & """"));
								if(ArrayLen(Setting.Vars) GT 0) {
									GeneratedContent.append(JavaCast("string", ", _vars"));
								}
								GeneratedContent.append(JavaCast("string", ");" & NewLine));
							} else {
								// ERROR: i throw an error if necessary
								Throw("MyOpenbox", "Error while processing Routes.", "Please make sure only &lt;route .../&gt; verbs are used in each Route definition in the MyOpenbox configuration file.");
							}
						}
					}
				GeneratedContent.append(JavaCast("string", Indent(2) & "}" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(2) & "<" & "/cfscript>" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "<" & "/cflock>" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "/cfif>" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "/cfsilent>" & NewLine));
		
/*
		GeneratedContent.append(JavaCast("string", "<" & "cfdump var=""##application.MyOpenbox.Routes.GetRoutes()##"" label=""##GetCurrentTemplatePath()##"" />" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "cfabort />" & NewLine));
*/
		
				
		// i set GeneratedContent to a string value so i can clean out any internal references
		GeneratedContent=GeneratedContent.ToString();
		// i replace any internal references in {}s
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{MyOpenbox}", this.Parameters.MyOpenboxObjectVariable, "all");
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{Circuits}", this.Parameters.MyOpenboxObjectVariable & ".Circuits", "all");
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{Parameters}", this.Parameters.MyOpenboxObjectVariable & ".Parameters", "all");
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{Phases}", this.Parameters.MyOpenboxObjectVariable & ".Phases", "all");
		GeneratedContent=ReplaceNoCase(GeneratedContent, "{Settings}", ContainerVariable & ".Settings", "all");
		
		// i write the GeneratedContent to a file
		Write(FileName, GeneratedContent);
			
		// LOGS: i set a Logs.ProcessingTime value
		if(this.Parameters.EnableLogs){
			this.Logs.ProcessingTime.CreateRoutesFile[ListLast(ContainerVariable, ".")]=GetTickCount() - TickCount;
			this.Logs.Requests.FileBuilds=this.Logs.Requests.FileBuilds + 1;
		}
		</cfscript>
		
		</cfif>
		
	</cffunction>
	
	<cffunction name="CreatePhaseFiles" 
		access="private" 
		hint="." 
		output="false" 
		returntype="void">
		
		<cfargument name="Phases" type="string">
		
		<cfscript>
		// i initialize the local vars
		var Phase="";
		</cfscript>
		
		<cfloop index="Phase" list="#arguments.Phases#">
			<cfscript>
			if(StructKeyExists(this.Phases, Phase)){
				CreatePhaseFile(Phase, this.Phases[Phase]);
			}
			</cfscript>
		</cfloop>
		
	</cffunction>
	
	<cffunction name="CreatePhaseFile" 
		access="private" 
		hint="." 
		output="false" 
		returntype="void">
		
		<cfargument name="PhaseName" type="string">
		<cfargument name="Phase" type="array">
		
		<cfscript>
		// i initialize the local vars
		var GeneratedContent=CreateObject("java", "java.lang.StringBuffer").init();
		var IsCircuitRelated=False;
		var i=0;
		var NewLine=this.Parameters.Delimiters.NewLine;
		var TickCount=GetTickCount();
		var temp="";
		</cfscript>
		
		<cfscript>
		if(this.Parameters.ProcessingMode NEQ "Deployment" OR (this.IsFWreparse() OR this.IsFWReinit())){
			GeneratedContent.append(JavaCast("string", "<" & "cfset YourOpenbox.ThisPhase.Name=""" & arguments.PhaseName & """>" & NewLine));
			GeneratedContent.append(JavaCast("string", NewLine));
			
			// i loop through the Command chunks
			for(i=1; i LTE ArrayLen(arguments.Phase); i=i + 1){
				// i determine if this Phase should be run at a Specific Circuit
				if(StructKeyExists(arguments.Phase[i], "CircuitName")){
					IsCircuitRelated=True;
					
					// i create the Circuit cache files if necessary
					if(NOT StructKeyExists(this.Circuits[arguments.Phase[i]["CircuitName"]], "TimeStamp")){
						CreateCircuitFiles(this.Circuits[arguments.Phase[i]["CircuitName"]]);
					}
				} else {
					IsCircuitRelated=False;
				}
				
				// i insert the PushToPhaseStack function
				GeneratedContent.append(JavaCast("string", "<!--- i process the YourOpenbox, Circuit, and FuseAction variables --->" & NewLine));
				GeneratedContent.append(JavaCast("string", "<" & "cfset _PushToPhaseStack()>" & NewLine));
				GeneratedContent.append(JavaCast("string", NewLine));
				
				// if this is a Circuit related Circuit Phase
				if(IsCircuitRelated){					
					// i insert the proceeding Circuit's CRVs
					GeneratedContent.append(JavaCast("string", "<" & "cfscript>" & NewLine));
					GeneratedContent.append(JavaCast("string", "YourOpenbox.ThisCircuit=application.MyOpenbox.GetCircuit(""" & arguments.Phase[i]["CircuitName"] & """);" & NewLine));
					GeneratedContent.append(JavaCast("string", "if(StructKeyExists(_YourOpenbox.Circuits, """ & arguments.Phase[i]["CircuitName"] & """) AND StructKeyExists(_YourOpenbox.Circuits." & arguments.Phase[i]["CircuitName"] & ", ""CRVs"")){" & NewLine));
						GeneratedContent.append(JavaCast("string", Indent() & "CRVs=_YourOpenbox.Circuits." & arguments.Phase[i]["CircuitName"] & ".CRVs;" & NewLine));
					GeneratedContent.append(JavaCast("string", "} else {" & NewLine));
						GeneratedContent.append(JavaCast("string", Indent() & "CRVs=StructNew();" & NewLine));
					GeneratedContent.append(JavaCast("string", "}" & NewLine));
					GeneratedContent.append(JavaCast("string", "<" & "/cfscript>" & NewLine));
					GeneratedContent.append(JavaCast("string", NewLine));
					
					// i insert the Settings include (if necessary)
					if(StructKeyExists(this.Circuits[arguments.Phase[i]["CircuitName"]], "Settings")){
						GeneratedContent.append(JavaCast("string", "<!--- i apply the Phase's Circuit Settings --->" & NewLine));
						GeneratedContent.append(JavaCast("string", "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "settings." & lcase(arguments.phase[i]["circuitname"]) & ".cfm"">" & NewLine));
						GeneratedContent.append(JavaCast("string", NewLine));
					}
					
					// i insert the Command statements
					temp=RenderCommands("Phase", arguments.Phase[i]["Commands"], arguments.PhaseName, this.Circuits[arguments.Phase[i]["CircuitName"]]);
					GeneratedContent.append(JavaCast("string", temp));
					GeneratedContent.append(JavaCast("string", NewLine));
				} else {
					// i insert the Command statements
					temp=RenderCommands("Phase", arguments.Phase[i]["Commands"], arguments.PhaseName);
					GeneratedContent.append(JavaCast("string", temp));
					GeneratedContent.append(JavaCast("string", NewLine));
				}
					
				// i insert the PopPhaseStack function
				GeneratedContent.append(JavaCast("string", "<!--- i reinstate ThisPhase's, ThisCircuit's and ThisFuseAction's values from the ActionStack --->" & NewLine));
				GeneratedContent.append(JavaCast("string", "<" & "cfset _PopPhaseStack()>" & NewLine));
				GeneratedContent.append(JavaCast("string", NewLine));
			}
			
			// i write the GeneratedContent to a file
			Write("phase." & arguments.PhaseName, GeneratedContent.ToString());
			
			// i set a TimeStamp to keep each Phase current with MyOpenbox
			this.Phases[arguments.PhaseName][1]["TimeStamp"]=this.TimeStamp;
			
			// LOGS: i set a Logs.ProcessingTime value
			if(this.Parameters.EnableLogs){
				this.Logs.ProcessingTime.CreatePhaseFile[arguments.PhaseName]=GetTickCount() - TickCount;
				this.Logs.Requests.FileBuilds=this.Logs.Requests.FileBuilds + 1;
			}
		}
		</cfscript>
		
	</cffunction>
	
	<cffunction name="CreateCircuitPhaseFiles" 
		access="private" 
		hint="." 
		output="false" 
		returntype="void">
		
		<cfargument name="Circuit" type="struct">
		
		<cfscript>
		// i initialize the local vars
		var GeneratedContent="";
		var Phase="";
		var IsStageAction=False;
		var NewLine=this.Parameters.Delimiters.NewLine;
		var TickCount=0;
		var temp="";
		</cfscript>
		
		<cfif this.Parameters.ProcessingMode NEQ "Deployment" OR (this.IsFWreparse() OR this.IsFWReinit())>
		
			<cfloop item="Phase" collection="#arguments.Circuit.Phases#">
			
				<cfscript>
				// LOGS: i (re)set TickCount for logs
				TickCount=GetTickCount();
				
				// i check for Circuit/FuseAction related stages
				if(NOT StructKeyExists(arguments.Circuit.Phases[Phase]["Attributes"], "PrimaryCall")){
					arguments.Circuit.Phases[Phase]["Attributes"]["PrimaryCall"]=True;
				}
				if(NOT StructKeyExists(arguments.Circuit.Phases[Phase]["Attributes"], "SecondaryCall")){
					arguments.Circuit.Phases[Phase]["Attributes"]["SecondaryCall"]=True;
				}
				if(NOT StructKeyExists(arguments.Circuit.Phases[Phase]["Attributes"], "TargetCall")){
					arguments.Circuit.Phases[Phase]["Attributes"]["TargetCall"]=True;
				}
				if(NOT StructKeyExists(arguments.Circuit.Phases[Phase]["Attributes"], "SuperCall")){
					arguments.Circuit.Phases[Phase]["Attributes"]["SuperCall"]=True;
				}
				
				// i (re)set GeneratedContent
				GeneratedContent=CreateObject("java", "java.lang.StringBuffer").init();
				
				GeneratedContent.append(JavaCast("string", "<" & "cfset YourOpenbox.ThisPhase.Name=""" & Phase & """>" & NewLine));
				GeneratedContent.append(JavaCast("string", NewLine));
				
				// i create the if statements for Stages with False values
				if(NOT arguments.Circuit.Phases[Phase]["Attributes"]["PrimaryCall"]){
					IsStageAction=True;
					GeneratedContent.append(JavaCast("string", "<" & "cfif NOT YourOpenbox.IsTargetCall AND NOT YourOpenbox.IsSuperCall>" & NewLine));
				} else if(NOT arguments.Circuit.Phases[Phase]["Attributes"]["SecondaryCall"]){
					IsStageAction=True;
					GeneratedContent.append(JavaCast("string", "<" & "cfif YourOpenbox.IsTargetCall OR YourOpenbox.IsSuperCall>" & NewLine));
				} else if(NOT arguments.Circuit.Phases[Phase]["Attributes"]["TargetCall"]){
					IsStageAction=True;
					GeneratedContent.append(JavaCast("string", "<" & "cfif NOT YourOpenbox.IsTargetCall>" & NewLine));
				} else if(NOT arguments.Circuit.Phases[Phase]["Attributes"]["SuperCall"]){
					IsStageAction=True;
					GeneratedContent.append(JavaCast("string", "<" & "cfif NOT YourOpenbox.IsSuperCall>" & NewLine));
				} else {
					IsStageAction=False;
				}
	
				// i insert your commands
				temp=RenderCommands("Phase", arguments.Circuit.Phases[Phase]["Commands"], Phase, arguments.Circuit);
				GeneratedContent.append(JavaCast("string", temp));
				GeneratedContent.append(JavaCast("string", NewLine));
				
				// if this Phase opened an if tag above
				if(IsStageAction){
					GeneratedContent.append(JavaCast("string", "<" & "/cfif>" & NewLine));
				}
				
				GeneratedContent.append(JavaCast("string", "<" & "cfset StructDelete(YourOpenbox, ""ThisPhase"")>" & NewLine));
				
				// i write the GeneratedContent to a file
				Write("phase." & Phase & "." & arguments.Circuit.Name, GeneratedContent.ToString());
				
				// LOGS: i set a Logs.ProcessingTime value
				if(this.Parameters.EnableLogs){
					this.Logs.ProcessingTime.CreatePhaseFile[Phase & "." & arguments.Circuit.Name]=GetTickCount() - TickCount;
					this.Logs.Requests.FileBuilds=this.Logs.Requests.FileBuilds + 1;
				}
				</cfscript>
			
			</cfloop>
		
		</cfif>
		
	</cffunction>
	
	<!--- cffunction name="RUNFUSEACTION/PHASE METHODS" --->
	
	<cffunction name="RunFuseAction" 
		access="public" 
		hint="." 
		output="false" 
		returntype="void">
		
		<cfargument name="QualifiedFuseAction" type="string">
		
		<cfscript>
		// i initialize the local vars
		var CircuitValue="";
		var FuseActionValue="";
		var Circuit="";
		var FuseAction="";
		</cfscript>
		
		<cfscript>
		// i set CircuitValue and FuseActionValue
		CircuitValue=ListFirst(arguments.QualifiedFuseAction, ".");
		FuseActionValue=ListLast(arguments.QualifiedFuseAction, ".");
		</cfscript>
		
		<cfif this.Parameters.ProcessingMode NEQ "Deployment">
		
		<cfscript>		
		// i check the QualifiedFuseAction to make sure it is valid
		if(ListLen(arguments.QualifiedFuseAction, ".") NEQ 2){
			Throw("MyOpenbox", "The FuseAction supplied is invalid.", "Please check the value of FuseAction (#arguments.QualifiedFuseAction#) to make sure it exists and/or is a valid fully qualified FuseAction.", "FuseAction = #arguments.QualifiedFuseAction#");
		// i check the CircuitValue
		} else if(NOT StructKeyExists(this.Circuits, CircuitValue)){
			Throw("MyOpenbox", "The Circuit requested is invalid.", "Please check the value of Circuit (#CircuitValue#) to make sure it exists and/or is valid.", "FuseAction = #arguments.QualifiedFuseAction#");
		// i check the FuseActionValue
		} else if(NOT StructKeyExists(this.Circuits[CircuitValue]["FuseActions"], FuseActionValue)){
			Throw("MyOpenbox", "The FuseAction requested is invalid.", "Please check the value of FuseAction (#CircuitValue#.#FuseActionValue#) to make sure it exists and/or is valid.");
		} 
		// i check the Access of the arguments.QualifiedFuseAction
		/* else if(this.Circuits[CircuitValue]["FuseActions"][FuseActionValue]["Access"] NEQ "Public"){
			Throw("MyOpenbox", "The FuseAction requested is not available.", "Please make sure you have the proper rights to access the supplied FuseAction.", "FuseAction = #arguments.QualifiedFuseAction#");
		} */
		
		// i set Circuit and FuseAction
		Circuit=this.Circuits[CircuitValue];
		FuseAction=this.Circuits[CircuitValue]["FuseActions"][FuseActionValue];
		</cfscript>
		
		<!--- i determine if i should parse the FuseAction --->
		<cfif this.Parameters.ProcessingMode EQ "Development"
			OR NOT StructKeyExists(FuseAction, "TimeStamp")>
			<!--- i lock the creation of the FuseAction file | this basically kills the ability to have recursive FuseActions, damnit. --->
			<cflock name="#Hash(GetCurrentTemplatePath() & "_RunFuseAction_" & Circuit.Name)#" timeout="10">
				<cfscript>
				// i (re)determine if i should create the FuseAction
				if(
					this.Parameters.ProcessingMode EQ "Development"  
					OR NOT StructKeyExists(FuseAction, "TimeStamp")
				){
					// i create the Circuit files
					if(NOT StructKeyExists(Circuit, "TimeStamp")){
						CreateCircuitFiles(Circuit);
					}
					
					// i create the FuseAction file
					CreateFuseActionFile(Circuit, FuseAction);
				}
				</cfscript>
			</cflock>
		</cfif>
		
		</cfif>
	
	</cffunction>
	
	<cffunction name="RunPhase" 
		access="public" 
		hint="." 
		output="false" 
		returntype="void">
		
		<cfargument name="PhaseName" type="string">
		<cfargument name="Phase" type="array">
		
		<cfset CreatePhaseFile(arguments.PhaseName, arguments.Phase)>
		
	</cffunction>
	
	<cffunction name="CreateFuseActionFile" 
    	access="public" 
    	hint="." 
    	output="false" 
    	returntype="void">
		
		<cfargument name="Circuit" type="struct">
		<cfargument name="FuseAction" type="struct">
		
		<cfscript>
		// i initialize the local vars
		var GeneratedContent=CreateObject("java", "java.lang.StringBuffer").init();
		var NewLine=this.Parameters.Delimiters.NewLine;
		var TickCount=GetTickCount();
		var temp="";
		</cfscript>
		
		<cfscript>
		// i insert the Settings file if Settings exists
		if(StructKeyExists(arguments.Circuit, "Settings")){
			GeneratedContent.append(JavaCast("string", "<!--- i include this Circuit's Settings file --->" & NewLine));
			GeneratedContent.append(JavaCast("string", "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "settings." & LCase(arguments.Circuit.Name) & ".cfm"">" & NewLine));
			GeneratedContent.append(JavaCast("string", NewLine));
		}
		
		GeneratedContent.append(JavaCast("string", "<" & "cfscript>" & NewLine));
		GeneratedContent.append(JavaCast("string", "// i set this FuseAction's properties" & NewLine));
		GeneratedContent.append(JavaCast("string", "YourOpenbox.ThisCircuit=application.MyOpenbox.GetCircuit(""" & arguments.Circuit.Name & """);" & NewLine));
		GeneratedContent.append(JavaCast("string", "YourOpenbox.ThisFuseAction=application.MyOpenbox.GetFuseAction(""" & arguments.Circuit.Name & "." & arguments.FuseAction.Name & """);" & NewLine));
		GeneratedContent.append(JavaCast("string", "YourOpenbox.ThisFuseAction.UUId=Insert(""-"", CreateUUID(), 23);" & NewLine));
		GeneratedContent.append(JavaCast("string", "YourOpenbox.IsSuperCall=False;" & NewLine));
		GeneratedContent.append(JavaCast("string", "// i set the Circuit and FuseAction variables" & NewLine));
		
		// added/changed on 12/1/08 - all Circuits will now get Keys in _YourOpenbox.Circuits
		GeneratedContent.append(JavaCast("string", "if(NOT StructKeyExists(_YourOpenbox.Circuits, """ & arguments.Circuit.Name & """) OR NOT StructKeyExists(_YourOpenbox.Circuits." & arguments.Circuit.Name & ", ""CRVs"")){" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "_YourOpenbox.Circuits[""" & arguments.Circuit.Name & """][""CRVs""]=StructNew();" & NewLine));
		GeneratedContent.append(JavaCast("string", "}" & NewLine));
		GeneratedContent.append(JavaCast("string", "variables.CRVs=_YourOpenbox.Circuits." & arguments.Circuit.Name & ".CRVs;" & NewLine));
		
		// GeneratedContent.append(JavaCast("string", "if(StructKeyExists(_YourOpenbox.Circuits, """ & arguments.Circuit.Name & """) AND StructKeyExists(_YourOpenbox.Circuits." & arguments.Circuit.Name & ", ""CRVs"")){" & NewLine));
		// 	GeneratedContent.append(JavaCast("string", Indent() & "variables.CRVs=_YourOpenbox.Circuits." & arguments.Circuit.Name & ".CRVs;" & NewLine));
		// GeneratedContent.append(JavaCast("string", "} else {" & NewLine));
		// 	GeneratedContent.append(JavaCast("string", Indent() & "variables.CRVs=StructNew();" & NewLine));
		// GeneratedContent.append(JavaCast("string", "}" & NewLine));
		GeneratedContent.append(JavaCast("string", "// i set empty local FuseAction variable structures" & NewLine));
		GeneratedContent.append(JavaCast("string", "variables.FAVs=StructNew();" & NewLine));
		GeneratedContent.append(JavaCast("string", "variables.XFAs=StructNew();" & NewLine));
		GeneratedContent.append(JavaCast("string", "// i check for PassThrough variables (from DO calls)" & NewLine));
		GeneratedContent.append(JavaCast("string", "if(ArrayLen(_YourOpenbox.ActionStack) AND StructKeyExists(_YourOpenbox.ActionStack[ArrayLen(_YourOpenbox.ActionStack)], ""PassThroughs"")){" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "// i check/set FuseAction Variables (FAVs)" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "if(StructKeyExists(_YourOpenbox.ActionStack[ArrayLen(_YourOpenbox.ActionStack)][""PassThroughs""], ""FAVs"")){" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(2) & "variables.FAVs=_YourOpenbox.ActionStack[ArrayLen(_YourOpenbox.ActionStack)][""PassThroughs""][""FAVs""];" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "}" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "// i check/set Exit FuseActions (XFAs)" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "if(StructKeyExists(_YourOpenbox.ActionStack[ArrayLen(_YourOpenbox.ActionStack)][""PassThroughs""], ""XFAs"")){" & NewLine));
				GeneratedContent.append(JavaCast("string", Indent(2) & "variables.XFAs=_YourOpenbox.ActionStack[ArrayLen(_YourOpenbox.ActionStack)][""PassThroughs""][""XFAs""];" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "}" & NewLine));
		GeneratedContent.append(JavaCast("string", "}" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "/cfscript>" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		GeneratedContent.append(JavaCast("string", "<!--- PHASE:PreFuseAction/PreGlobalFuseAction --->" & NewLine));
		if(StructKeyExists(this.Phases, "PreGlobalFuseAction")){
			GeneratedContent.append(JavaCast("string", "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "phase.preglobalfuseaction.cfm"">" & NewLine));
		}
		if(StructKeyExists(arguments.Circuit, "Phases") AND StructKeyExists(arguments.Circuit.Phases, "PreFuseAction")){
			GeneratedContent.append(JavaCast("string", "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "phase.prefuseaction." & lcase(arguments.circuit.name) & ".cfm"">" & NewLine));
		}
		GeneratedContent.append(JavaCast("string", "<!--- End PHASE:PreFuseAction/PreGlobalFuseAction --->" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		GeneratedContent.append(JavaCast("string", "<!--- PHASE:RequestedFuseAction --->" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "cfset YourOpenbox.ThisPhase.Name=""RequestFuseAction"">" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		
		// i setup the try/catch
		GeneratedContent.append(JavaCast("string", "<" & "cfset _YourOpenbox.cfcatch=StructNew() />" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "cftry>" & NewLine));
		
		
		// i render the fuseaction
		temp=RenderCommands("FuseAction", arguments.FuseAction.Commands, "RequestedFuseAction", arguments.Circuit, arguments.FuseAction);
		GeneratedContent.append(JavaCast("string", temp));
		
		GeneratedContent.append(JavaCast("string", "<" & "cfcatch type=""Any"">" & NewLine));
		if(StructKeyExists(arguments.Circuit, "Phases") AND StructKeyExists(arguments.Circuit.Phases, "OnError")) {
			GeneratedContent.append(JavaCast("string", Indent() & "<" & "cftry>" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(2) & "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "phase.onerror." & lcase(arguments.circuit.name) & ".cfm"">" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(2) & "<" & "cfcatch type=""Any"">" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(2) & "<" & "cfset _YourOpenbox.cfcatch=cfcatch />" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent(2) & "<" & "/cfcatch>" & NewLine));
			GeneratedContent.append(JavaCast("string", Indent() & "<" & "/cftry>" & NewLine));
		} else {
			GeneratedContent.append(JavaCast("string", Indent() & "<" & "cfset _YourOpenbox.cfcatch=cfcatch />" & NewLine));
		}
		GeneratedContent.append(JavaCast("string", "<" & "/cfcatch>" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "/cftry>" & NewLine));
		
		
		GeneratedContent.append(JavaCast("string", "<" & "cfset StructDelete(YourOpenbox, ""ThisPhase"")>" & NewLine));
		GeneratedContent.append(JavaCast("string", "<!--- End PHASE:RequestedFuseAction --->" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		GeneratedContent.append(JavaCast("string", "<!--- PHASE:PostFuseAction/PostGlobalFuseAction --->" & NewLine));
		if(StructKeyExists(arguments.Circuit, "Phases") AND StructKeyExists(arguments.Circuit.Phases, "PostFuseAction")){
			GeneratedContent.append(JavaCast("string", "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "phase.postfuseaction." & lcase(arguments.circuit.name) & ".cfm"">" & NewLine));
		}
		if(StructKeyExists(this.Phases, "PostGlobalFuseAction")){
			GeneratedContent.append(JavaCast("string", "<" & "cfinclude template=""" & this.Parameters.CacheFilePrefix & "phase.postglobalfuseaction.cfm"">" & NewLine));
		}
		GeneratedContent.append(JavaCast("string", "<!--- End PHASE:PostFuseAction/PostGlobalFuseAction --->" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		// i check for a value from a thrown exception and rethrow it, since cf8 doesn't have cffinally
		GeneratedContent.append(JavaCast("string", "<" & "cfif NOT StructIsEmpty(_YourOpenbox.cfcatch)>" & NewLine));
		GeneratedContent.append(JavaCast("string", Indent() & "<" & "cfthrow object=""##_YourOpenbox.cfcatch##"" />" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "/cfif>" & NewLine));
		GeneratedContent.append(JavaCast("string", NewLine));
		
		GeneratedContent.append(JavaCast("string", "<" & "cfscript>" & NewLine));
		GeneratedContent.append(JavaCast("string", "// i store and destroy the Circuit and FuseAction variables" & NewLine));
		GeneratedContent.append(JavaCast("string", "_YourOpenbox.Circuits." & arguments.Circuit.Name & ".CRVs=variables.CRVs;" & NewLine));
		GeneratedContent.append(JavaCast("string", "StructDelete(variables, ""CRVs"");" & NewLine));
		GeneratedContent.append(JavaCast("string", "StructDelete(variables, ""FAVs"");" & NewLine));
		GeneratedContent.append(JavaCast("string", "StructDelete(variables, ""XFAs"");" & NewLine));
		GeneratedContent.append(JavaCast("string", "// i destroy this FuseAction's properties" & NewLine));
		GeneratedContent.append(JavaCast("string", "StructDelete(YourOpenbox, ""ThisCircuit"");" & NewLine));
		GeneratedContent.append(JavaCast("string", "StructDelete(YourOpenbox, ""ThisFuseAction"");" & NewLine));
		GeneratedContent.append(JavaCast("string", "<" & "/cfscript>" & NewLine));
		
		// i write the GeneratedContent to a file
		Write("fuseaction." & arguments.Circuit.Name & "." & arguments.FuseAction.Name, GeneratedContent.ToString());
		
		// i set a TimeStamp to keep each FuseAction current with MyOpenbox
		this.Circuits[arguments.Circuit.Name]["FuseActions"][arguments.FuseAction.Name]["TimeStamp"]=this.TimeStamp;
		
		// i set a ProcessingTime
		if(this.Parameters.EnableLogs){
			this.Logs.ProcessingTime.CreateFuseActionFile[arguments.Circuit.Name & "." & arguments.FuseAction.Name]=GetTickCount() - TickCount;
			this.Logs.Requests.FileBuilds=this.Logs.Requests.FileBuilds + 1;
		}
		</cfscript>
    
    </cffunction>
	
	<!--- cffunction name="RENDER METHODS" --->
	
	<cffunction name="RenderCommands" 
    	hint="." 
    	access="private" 
    	output="false" 
    	returntype="string">
    	
    	<cfargument name="Type" type="string">
    	<cfargument name="Commands" type="array">
    	<cfargument name="PhaseName" type="string">
    	<cfargument name="Circuit" type="struct" default="#StructNew()#">
    	<cfargument name="FuseAction" type="struct" default="#StructNew()#">
    	<cfargument name="Level" type="numeric" default="0">
		
		<cfscript>
		// i initialize the local vars
		var GeneratedContent=CreateObject("java", "java.lang.StringBuffer").init();
		var i=0;
		var temp="";
		</cfscript>
		
		<cfloop index="i" from="1" to="#ArrayLen(arguments.Commands)#" step="1">
			<cfset temp=RenderCommand(arguments.Type, arguments.Commands[i], arguments.PhaseName, arguments.Circuit, arguments.FuseAction, arguments.Level)>
			<cfset GeneratedContent.append(JavaCast("string", temp))>
		</cfloop>
    	
		<cfreturn GeneratedContent.ToString()>
    	
    </cffunction>
	
	<cffunction name="RenderCommand" 
    	hint="." 
    	access="private" 
    	output="false" 
    	returntype="string">
    	
    	<cfargument name="Type" type="string">
    	<cfargument name="Command" type="any">
    	<cfargument name="PhaseName" type="string">
    	<cfargument name="Circuit" type="struct" default="#StructNew()#">
    	<cfargument name="FuseAction" type="struct" default="#StructNew()#">
    	<cfargument name="Level" type="numeric" default="0">
		
		<cfscript>
		// i initialize the local vars
		var GeneratedContent=CreateObject("java", "java.lang.StringBuffer").init();
		var TargetVerb=ListFirst(arguments.Command.XMLName, ".");
		var LocalVars=StructNew();
		var ErrorInformation=StructNew();
		var NewLine=this.Parameters.Delimiters.NewLine;
		</cfscript>
		
		<!--- <cftry> --->
			<cfif StructKeyExists(this.Verbs, TargetVerb)>
				<cfif StructKeyExists(this.Verbs[TargetVerb], "Path")>
					<cfinclude template="../#this.Verbs[TargetVerb]["Path"]##this.Verbs[TargetVerb]["Template"]#.cfm">
				<cfelse>
					<cfinclude template="../#this.Parameters.Dictionary.Path##this.Verbs[TargetVerb]["Template"]#.cfm">
				</cfif>
			<cfelse>
				<cfthrow message="Could not render the verb <em>&lt;#arguments.Command.XMLName#... /&gt;</em>." 
					detail="The <em>#TargetVerb#</em> verb does not exist in this application's dictionary. Please make sure you are using a valid verb/xml command.">
			</cfif>
			<!--- <cfcatch>
				<!--- i'll append the MyOpenbox information to the throw --->
				<cfif cfcatch.Type NEQ "MyOpenbox">
					<cfscript>
					// i set ExtendedInfo for determining the location of the error
					if(NOT StructIsEmpty(arguments.FuseAction)){
						ErrorInformation.Detail="The error occured while rendering the <em>#TargetVerb#</em> verb during the <em>#arguments.FuseAction.Name#</em> FuseAction in the <em>#arguments.Circuit.Name#</em> Circuit.";
					} else if(NOT StructIsEmpty(arguments.Circuit)){
						ErrorInformation.Detail="The error occured while rendering the <em>#TargetVerb#</em> verb during the <em>#arguments.PhaseName#</em> Phase in the <em>#arguments.Circuit.Name#</em> Circuit.";
					} else {
						ErrorInformation.Detail="The error occured while rendering the <em>#TargetVerb#</em> verb during the <em>#arguments.PhaseName#</em> Phase.";
					}
					</cfscript>
					<cfthrow type="MyOpenbox" 
						message="#cfcatch.Message#" 
						detail="#cfcatch.Detail# #ErrorInformation.Detail#" 
						extendedinfo="Please make sure you are using the correct syntax for your verbs and verb attributes. Visit <em>http://myopenbox.org</em> for the latest MyOpenbox documentation.">
				<!--- <cfelse>
					<cfrethrow> --->
				</cfif>
			</cfcatch>
    	</cftry> --->
		
		<cfreturn GeneratedContent.ToString()>
    	
    </cffunction>
	
	<!--- cffunction name="GET METHODS" --->
	
	<cffunction name="GetCircuit" 
    	hint="." 
    	access="public" 
    	output="false" 
    	returntype="struct">
    	
    	<cfargument name="CircuitName" type="string">
		
		<cfscript>
		// i initialize the local vars
		var Circuit=StructNew();
		var Key=0;
		</cfscript>
		
		<cfloop item="Key" collection="#this.Circuits[arguments.CircuitName]#">
			<cfscript>
			if(NOT ListFindNoCase(this.Parameters.FilterCircuitAttributes, Key)){
				Circuit[Key]=this.Circuits[arguments.CircuitName][Key];
			}
			</cfscript>
		</cfloop>
    	
		<cfreturn Circuit>
    	
    </cffunction>
	
	<cffunction name="GetFuseAction" 
    	hint="." 
    	access="public" 
    	output="false" 
    	returntype="struct">
    	
    	<cfargument name="QualifiedFuseAction" type="string">
		
		<cfscript>
		// i initialize the local vars
		var CircuitName=ListFirst(arguments.QualifiedFuseAction, ".");
		var FuseActionName=ListLast(arguments.QualifiedFuseAction, ".");
		var FuseAction=StructNew();
		var Key=0;
		</cfscript>
		
		<cfloop item="Key" collection="#this.Circuits[CircuitName]["FuseActions"][FuseActionName]#">
			<cfscript>
			if(NOT ListFindNoCase(this.Parameters.FilterFuseActionAttributes, Key)){
				FuseAction[Key]=this.Circuits[CircuitName]["FuseActions"][FuseActionName][Key];
			}
			</cfscript>
		</cfloop>
    	
		<cfreturn FuseAction>
    	
    </cffunction>
	
	<cffunction name="GetQualifiedFuseAction" 
    	hint="." 
    	access="public" 
    	output="false" 
    	returntype="string">
    	
    	<cfargument name="FuseActionToTest" type="string">
    	<cfargument name="Circuit" type="struct" default="#StructNew()#">
		
		<cfscript>
		// i initialize the local vars
		var QualifiedFuseAction="";
		</cfscript>
		
		<cfscript>
		if(ListLen(arguments.FuseActionToTest, ".") EQ  2){
			QualifiedFuseAction=arguments.FuseActionToTest;
		} else if(ListLen(arguments.FuseActionToTest, ".") EQ 1 AND NOT StructIsEmpty(arguments.Circuit)){
			// i append the local Circuit Name if the FuseActionToTest is not fully qualified
			QualifiedFuseAction=arguments.Circuit.Name & "." & arguments.FuseActionToTest;
		} else {
			// THROW ERROR -- invalid value for FuseAction
		}
		</cfscript>
    	
		<cfreturn QualifiedFuseAction>
    	
    </cffunction>
	
	<cffunction name="SetAttributes" 
    	hint="." 
    	access="public" 
    	output="false" 
    	returntype="struct">
    	
    	<cfargument name="CallerVariables" type="struct">
    	<cfargument name="BaseTagList" type="string">
    	<cfargument name="CallerFile" type="string" default="myopenbox.cfm">
		
		<cfscript>
		// i initialize the local vars
		var RequestAttributes=StructNew();
		</cfscript>
		
		<cfscript>
		// i create a empty struct
		if(StructKeyExists(arguments.CallerVariables, "attributes")){
			RequestAttributes=arguments.CallerVariables.Attributes;
		} else {
			RequestAttributes=StructNew();
		}
		// if this is not a custom tag call
		if(NOT ListFindNoCase(arguments.BaseTagList, "CF_" & ListFirst(arguments.CallerFile, "."))){
			// i append Form and URL variables to attributes
			if(this.Parameters.PrecedenceFormOrURL EQ "form"){
				StructAppend(RequestAttributes, form, "No");
				StructAppend(RequestAttributes, url, "No");
			} else {
				StructAppend(RequestAttributes, url, "No");
				StructAppend(RequestAttributes, form, "No");
			}
		} 
		// ...else if this is a custom tag, i do not "pass in" Form and URL variables to the custom tag call, use caller.attributes to access attributes from the calling template
		// i set the DefaultFuseAction as the target FuseAction if necessary
		/*
		if(NOT StructKeyExists(RequestAttributes, this.Parameters.FuseActionVariable)){
			RequestAttributes[this.Parameters.FuseActionVariable]=this.Parameters.DefaultFuseAction;
		}
		*/
		</cfscript>
    	
		<cfreturn RequestAttributes>
    	
    </cffunction>
    
    <cffunction name="LogAction">
    	<cfargument name="Action" />
    	<cfargument name="Type" default="" />
    	<cfargument name="Time" default="" />
		<cfargument name="Info" default="" />
    	
    	<cfif NOT IsDefined("this.Parameters.EnableLogs") OR this.Parameters.EnableLogs>
	    	<cfset QueryAddRow(this.Logs.Actions) />
	    	<cfset QuerySetCell(this.Logs.Actions, "TimeStamp", Now()) />
	    	<cfset QuerySetCell(this.Logs.Actions, "Action", arguments.Action) />
	    	<cfset QuerySetCell(this.Logs.Actions, "Type", arguments.Type) />
	    	<cfset QuerySetCell(this.Logs.Actions, "Time", arguments.Time) />
				<cfset QuerySetCell(this.Logs.Actions, "Info", arguments.Info) />
	    </cfif>
    </cffunction>
	
	<!--- cffunction name="UTILITY METHODS" --->
	
	<cffunction name="AppendDefaultFileExtension" 
    	hint="I determine, and append the ScriptFileDelimiter to the given file." 
    	access="public" 
    	output="false" 
    	returntype="string">
    	
    	<cfargument name="TargetFile" type="string">
    	
		<cfscript>
		if(ListFindNoCase(this.Parameters.Delimiters.MaskedFileExtensions, ListLast(arguments.TargetFile, "."))){
			return arguments.TargetFile;
		} else {
			return arguments.TargetFile & "." & this.Parameters.Delimiters.DefaultFileExtension;
		}
		</cfscript>
    	
    </cffunction>
	
	<cffunction name="Exists" 
    	access="public" 
    	output="false" 
    	returntype="boolean">
    	
		<cfargument name="QualifiedFuseAction" type="string">

		<cfscript>
		// i initialize the local vars
		var CircuitValue="";
		var FuseActionValue="";
		</cfscript>

		<cfscript>
		// i set CircuitValue and FuseActionValue
		CircuitValue=ListFirst(arguments.QualifiedFuseAction, ".");
		FuseActionValue=ListLast(arguments.QualifiedFuseAction, ".");
		</cfscript>
    	
    	<cfif StructKeyExists(this.Circuits, CircuitValue) AND StructKeyExists(this.Circuits[CircuitValue]["FuseActions"], FuseActionValue)>
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>
    	
    </cffunction>
	
	<cffunction name="Dump" 
    	hint="I am a cfscript replacement for cfdump." 
    	access="private" 
    	output="true" 
    	returntype="void">
    	
    	<cfargument name="Var" type="any">
    	<cfargument name="Label" type="string" default="">
    	<cfargument name="Expand" type="boolean" default="True">
    	<cfargument name="Abort" type="boolean" default="false">
    	
    	<cfif Len(arguments.Label)>
			<cfdump var="#arguments.Var#" label="#arguments.Label#" expand="#arguments.Expand#">
		<cfelse>
			<cfdump var="#arguments.Var#" expand="#arguments.Expand#">
		</cfif>
		<cfif arguments.Abort>
			<cfabort />
		</cfif>
    	
    </cffunction>
	
	<cffunction name="FilterString" 
    	hint="" 
    	access="public" 
    	output="false" 
    	returntype="string">
    	
    	<cfargument name="DirtyString" type="string">
		
		<cfreturn REReplaceNoCase(REReplace(REReplace(arguments.DirtyString, "[[:punct:]]", "", "All"), "([[:alnum:]]*)", "\u\1", "All"), "\band\b|\bor\b|\bthe\b|\s", "", "All")>
    	
    </cffunction>
	
	<cffunction name="Indent" 
    	access="private" 
    	hint="." 
    	output="false" 
    	returntype="string">
		
		<cfargument name="Level" type="numeric" default="1">
		
		<cfreturn RepeatString(this.Parameters.Delimiters.Tab, arguments.Level)>
    
    </cffunction>
	
	<cffunction name="Read" 
		access="private" 
		hint="I read a file." 
		output="false" 
		returntype="string">
		
		<cfargument name="FileName" type="string">
		
		<cfscript>
		// i initialize the local vars
		var FileToReturn="";
		</cfscript>
		
		<cffile action="read" file="#arguments.FileName#" variable="FileToReturn">
		
		<cfreturn FileToReturn>
	
	</cffunction>
	
	<cffunction name="Throw" 
    	hint="I am a cfscript replacement for cfthrow." 
    	access="private" 
    	output="false" 
    	returntype="void">
    	
		<cfargument name="Type" type="string">
    	<cfargument name="Message" type="string">
    	<cfargument name="Detail" type="string">
    	<cfargument name="ExtendedInfo" type="string" default="">
    	
		<cfthrow type="#arguments.Type#" 
			message="#arguments.Message#" 
			detail="#arguments.Detail#" 
			extendedinfo="#arguments.ExtendedInfo#">
    	
    </cffunction>
	
	<cffunction name="Write" 
    	access="private" 
    	hint="." 
    	output="false" 
    	returntype="void">
		
		<cfargument name="FileName" type="string">
		<cfargument name="Content" type="string">
		
		<cfset var file=this.Parameters.Cache.Path />
		<cfif NOT StructKeyExists(this.Parameters.Cache, "PathExpandPath") OR this.Parameters.Cache.PathExpandPath>
			<cfset file=ExpandPath(file) />
		</cfif>
		<cfif StructKeyExists(this.Parameters, "CacheFilePrefix") AND Len(this.Parameters.CacheFilePrefix) GT 0>
			<cfset file = file & this.Parameters.CacheFilePrefix />
		</cfif>
		<cfset file = file & LCase(arguments.FileName) & ".cfm" />
		
		<cfset this.LogAction("Write File", FileName) />
		
		<cffile action="write" 
			file="#file#" 
			output="#arguments.Content#" 
			charset="#this.Parameters.CharacterEncoding#" 
			addnewline="no">
    
    </cffunction>

	<cffunction name="FileExists" access="public" output="false" returntype="boolean">
		<cfargument name="Path" type="string" />

		<cfset local.ExpandedPath=ExpandPath(Path) />
		<cfif this.Parameters.EnableFileExistsCache>
			<cfif StructKeyExists(this.FileExistsCache, local.ExpandedPath)>
				<cfreturn this.FileExistsCache[local.ExpandedPath] />
			<cfelse>
				<cfset local.Check=FileExists(local.ExpandedPath) />
				<cfset this.FileExistsCache[local.ExpandedPath]=local.Check />
				<cfreturn local.Check />
			</cfif>
		<cfelse>
			<cfreturn FileExists(local.ExpandedPath) />
		</cfif>
	</cffunction>

	<cffunction name="GetFileExistsCache" access="public" output="false" returntype="struct">
		<cfreturn this.FileExistsCache />
	</cffunction>

</cfcomponent>