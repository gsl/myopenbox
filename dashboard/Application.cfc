<cfcomponent name="Application" output="false">
	<cfscript>
	this.name = hash(ExpandPath("../../Application.cfc"));
	this.mappings["/"] = reverse(listRest(listRest(listRest(reverse(getDirectoryFromPath(getCurrentTemplatePath())), "\/"), "\/"), "\/")) & "/";
	this.mappings["/ram"] = "ram://";
	</cfscript>
</cfcomponent>