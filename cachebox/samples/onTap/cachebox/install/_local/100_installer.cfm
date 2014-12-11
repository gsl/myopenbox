<cfset request.tapi.ls("%tap_pluginmanager_title",
	"Installing #plugin.getValue('name')# #plugin.getValue('edition')# " & 
	"#plugin.getValue('version')# #plugin.getValue('revision')#",true)>

<cfset minversion = 3.3>
<cfset minbuild = 20090920>
<cfif not plugin.checkDependency("ontapframework",minversion,minbuild)>
	<cf_html parent="#pluginmanager.view.error#">
		<div xmlns:tap="xml.tapogee.com">
			<cfoutput>
				<p>This version of the #request.tapi.xmlFormat(plugin.getValue('name'))# plugin requires 
				version #minversion# build number #minbuild# or later of the onTap framework.</p>
			</cfoutput>
			
			<p><tap:text>Download the latest version at </tap:text>
			<a href="http://on.tapogee.com" /></p>
		</div>
	</cf_html>
	
	<cfinclude template="/inc/pluginmanager/view.cfm">
	<cf_abort>
</cfif>