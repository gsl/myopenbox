<cfcomponent output="false" extends="cfc.plugin">
	<cfset setValue("name","CacheBox")>
	<cfset setValue("version","0.9.10")>
	<cfset setValue("revision","beta")>
	<cfset setValue("releasedate","20-Apr-2012")>
	<cfset setValue("buildnumber",dateformat(getValue("releasedate"),"yyyymmdd"))>
	<cfset setValue("description","Installs the CacheBox framework.")>
	<cfset setValue("providerName","the CacheBox Project")>
	<cfset setValue("providerEmail","info@autlabs.com")>
	<cfset setValue("providerURL","http://cachebox.riaforge.org")>
	<cfset setValue("install","install/license")>
	<cfset setValue("remove","")>
	<cfset setValue("docs","")>
	
	<cfset variables.sourcepath = getDirectoryFromPath(getCurrentTemplatePath())>
	
	<cffunction name="get_version" access="public" output="false" returntype="string">
		<cfset var version = 0 />
		<cfset var newversion = getProperty("version") />
		<cfset var i = 0 />
		
		<cftry>
			<cfloop index="i" from="1" to="#listlen(newversion)#">
				<cfif listgetat(newversion,i) gt listgetat(version,i)>
					<cfreturn newversion />
				</cfif>
			</cfloop>
			
			<cfreturn version />
			
			<cfcatch><cfreturn newversion /></cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="getService" access="private" output="false">
		<cfreturn CreateObject("component","cachebox.cacheboxservice").init() />
	</cffunction>
	
	<cffunction name="getConfig" access="public" output="false">
		<cfreturn getService().getConfig() />
	</cffunction>
	
	<cffunction name="install" access="public" output="false" returntype="void">
		<cfargument name="plumbing" type="string" default="" />
		<cfargument name="adminpassword" type="string" default="" />
		<cfargument name="download" type="string" default="0" />
		
		<cfif len(trim(plumbing))>
			<cfif val(arguments.download)>
				<cfset downloadLatestVersionTo(plumbing) />
			</cfif>
			
			<cfset getIoC().getBean("filemanager").filecache = CreateObject("component","cfc.cacheboxagent").init("tap_filecache","application") />
			<cfif directoryExists(expandpath("/cachebox"))>
				<cfset copyAgent(plumbing) />
			<cfelse>
				<cfif createMapping(plumbing)>
					<cfthrow type="cachebox.mapping" />
				</cfif>
			</cfif>
			
			<cfset setPassword(arguments.adminpassword) />
			
			<cfset setInstallationStatus(true) />
		</cfif>
	</cffunction>
	
	<cffunction name="copyAgent" access="private" output="false">
		<cfargument name="source" type="string" default="#ExpandPath('/cachebox/cacheboxagent.cfc')#" />
		<cfargument name="destination" type="string" default="#ExpandPath('/cfc/cacheboxagent.cfc')#" />
		<cftry>
			<cffile action="copy" source="#source#" destination="#destination#" />
			<cfcatch></cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="isPasswordSet" access="public" output="false">
		<cftry>
			<cfreturn getConfig().isPasswordSet() />
			<cfcatch><cfreturn false /></cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="setPassword" access="private" output="false" 
	hint="I attempt to set the CacheBox management application password - failure is not important">
		<cfargument name="adminpassword" type="string" required="true" />
		<cftry>
			<cfif not isPasswordSet()>
				<cfset getConfig().savePassword(arguments.adminpassword) />
			</cfif>
			
			<cfcatch></cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="getFile" access="private" output="false">
		<cfreturn getObject("file")>
	</cffunction>
	
	<cffunction name="remove" access="public" output="false" returntype="void">
		<cfset removeMapping() />
	</cffunction>
	
	<cffunction name="getMappingComponent" access="private" output="false">
		<cfreturn getFile().init("_config/mappings/cachebox.cfc","P") />
	</cffunction>
	
	<cffunction name="hasMappingComponent" access="public" output="false">
		<cfreturn getMappingComponent().exists() />
	</cffunction>
	
	<cffunction name="removeMapping" access="public" output="false">
		<cfset getMappingComponent().delete() />
	</cffunction>
	
	<cffunction name="makeDirs" access="private" output="false">
		<cfargument name="plumbing" type="string" required="true" />
		
		<cfif not directoryexists(getFS().getPath(plumbing,"T")) and not directoryexists(plumbing)>
			<cfif left(plumbing,1) is not "/" and not findnocase(":",listfirst(plumbing,"\/"))>
				<cfset plumbing = getFS().getPath(plumbing,"T") />
			</cfif>
			
			<cfset CreateObject("java","java.io.File").init(plumbing).mkdirs() />
		</cfif>
	</cffunction>
	
	<cffunction name="createMapping" access="public" output="false">
		<cfargument name="plumbing" type="string" required="true" />
		<cfset var mapping = getMappingComponent().getValue("filepath") />
		<cfset var temp = "" />
		
		<cfif fileExists(mapping)>
			<cfreturn false />
		<cfelse>
			<cfset plumbing = replace(plumbing,"##","","ALL") />
			<cfset plumbing = replace(plumbing,'"','""','ALL') />
			
			<cfset makeDirs(plumbing) />
			
			<cfsavecontent variable="temp">
				<cfoutput><#trim("cfcomponent")# extends="config">
					
					<#trim("cffunction")# name="configure" access="public" output="false">
						<#trim("cfset")# addMapping("cachebox","#plumbing#",false) />
					</#trim("cffunction")#>
				</#trim("cfcomponent")#></cfoutput>
			</cfsavecontent>
			
			<cffile action="write" file="#mapping#" output="#temp#" />
			<cfreturn true />
		</cfif>
	</cffunction>
	
	<cffunction name="extractArchiveTo" access="private" output="false">
		<cfargument name="archive" type="string" required="true" />
		<cfargument name="domain" type="string" required="true" />
		<cfargument name="destination" type="string" required="true" />
		<cfset var dirname = listlast(destination,"/\") />
		<cfset parentdir = CreateObject("java","java.io.File").init(destination & "/../").getCanonicalPath() />
		
		<cfset archive = getObject("file").init(archive,domain,"zip") />
		<cfset archive.extract(destination="",domain=parentdir) />
		<cfset archive.delete() />
		
		<cfif dirname is not "cachebox">
			<cfset archive.init("cachebox",parentdir).move(dirname) />
		</cfif>
	</cffunction>
	
	<cffunction name="getArchiveFromHTTP" access="private" output="false">
		<cfset var temp = 0 />
		<cfhttp result="temp" getasbinary="yes" 
		url="http://cachebox.riaforge.org/index.cfm?event=action.download&doit=true" />
		<cfreturn temp.fileContent />
	</cffunction>
	
	<cffunction name="downloadLatestVersionTo" access="public" output="false">
		<cfargument name="path" type="string" required="true" />
		<cfset var filename = "../cachebox.zip" />
		<cfset var archive = getFS().getPath(filename,arguments.path) />
		<cfif fileExists(archive)><cffile action="delete" file="#archive#" /></cfif>
		<cffile action="write" file="#archive#" output="#getArchiveFromHTTP()#" />
		<cfset extractArchiveTo(filename,arguments.path,arguments.path) />
	</cffunction>
	
</cfcomponent>
