<myopenbox>
	
	<parameters>
		<parameter name="MyOpenboxObjectVariable" value="application.MyOpenbox" />
		<parameter name="ProcessingMode" value="Production" />
		<parameter name="EnableLogs" value="false" />
		<parameter name="CharacterEncoding" value="utf-8" />
		<parameter name="Delimiters.Directory" value="/" />
		<parameter name="Delimiters.NewLine" value="Chr(10)" evaluate="true" />
		<parameter name="Delimiters.Tab" value="Chr(9)" evaluate="true" />
		<parameter name="Delimiters.DefaultFileExtension" value="cfm" />
		<parameter name="Delimiters.MaskedFileExtensions" value="cfm,cfml,js,htm,html" />
		<parameter name="DefaultFuseAction" value="Home.Home" />
		<parameter name="DefaultContentVariable" value="YourOpenbox.GeneratedContent" />
		<parameter name="ForceReparsePassword" value="CreateUUID()" evaluate="true" />
		<parameter name="FuseActionVariable" value="a" />
		<parameter name="SelfFolder" value="[myopenbox]" />
		<parameter name="SelfPath" value="[myopenbox]/" />
		<parameter name="SelfRootPath" value="../" />
		<parameter name="CacheFolder" value="cache" />
		<parameter name="CachePath" value="[myopenbox]/cache/" />
		<parameter name="CacheRootPath" value="../../" />
		<parameter name="DictionaryFolder" value="dictionary" />
		<parameter name="DictionaryPath" value="[myopenbox]/dictionary/" />
		<parameter name="DictionaryRootPath" value="../../" />
		<parameter name="ParseWithComments" value="true" />
		<parameter name="PrecedenceFormOrURL" value="form" />
		<parameter name="StoreXML" value="false" />
		<parameter name="CorePhases" value="Init,PreProcess,PreGlobalFuseAction,PreFuseAction,PostFuseAction,PostGlobalFuseAction,PostProcess,OnError" />
		<parameter name="ApplicationPhases" value="Init,PreProcess,PreGlobalFuseAction,PostGlobalFuseAction,PostProcess,OnError" />
		<parameter name="CircuitPhases" value="PreFuseAction,PostFuseAction" />
		<parameter name="CircuitRelatedPhases" value="PreGlobalFuseAction,PreFuseAction,PostFuseAction,PostGlobalFuseAction" />
		<parameter name="ReservedCircuitAttributes" value="Access,ConfigFileName,DateLastModified,DirectoryPath,FuseActions,Name,Parent,Phases,RootPath,Settings,Title,UUId" />
		<parameter name="ReservedDoAttributes" value="Action,Append,Variable,Template" />
		<parameter name="ReservedFuseActionAttributes" value="Commands,Name,Title,TimeStamp" />
		<parameter name="FilterCircuitAttributes" value="Access,ConfigFileName,DateLastModified,FuseActions,Phases" />
		<parameter name="FilterFuseActionAttributes" value="Access,Commands,TimeStamp" />
		<parameter name="AccessList" value="Public,Internal,Private,Special,Any" />
		<parameter name="CircuitRootPaths" value="" />
	</parameters>
	
	<verbs>
		<verb name="Abort" />
		<verb name="Attribute" template="SetVariable" />
		<verb name="CallSuper" />
		<verb name="Call" />
		<verb name="Case" />
		<verb name="Content" />
		<verb name="CRV" template="SetVariable" />
		<verb name="DefaultCase" />
		<verb name="Do" />
		<verb name="Dump" />
		<verb name="Else" />
		<verb name="ElseIf" />
		<verb name="FAV" template="SetVariable" />
		<verb name="If" />
		<verb name="Include" />
		<verb name="Instantiate" />
		<verb name="Invoke" />
		<verb name="Lock" />
		<verb name="Loop" />
		<verb name="PrimaryCall" template="Stage" />
		<verb name="Relocate" />
		<verb name="SecondaryCall" template="Stage" />
		<verb name="Set" template="SetVariable" />
		<verb name="SuperCall" template="Stage" />
		<verb name="Switch" />
		<verb name="TargetCall" template="Stage" />
		<verb name="Throw" />
		<verb name="ToDo" />
		<verb name="Write" />
		<verb name="XFA" />
		
		<verb name="Try" />
		<verb name="Catch" />
	</verbs>
	
</myopenbox>