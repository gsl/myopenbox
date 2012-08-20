<cfset variables.instance = structNew() />
<cfset instance.contextList = "cluster,server,application" />
<cfset instance.rootDir = getDirectoryFromPath(getCurrentTemplatePath()) />
<cfset instance.configDir = instance.rootDir & "settings/" />
<cfset instance.created = now() />
