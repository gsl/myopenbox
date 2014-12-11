<cf_validate form="#variables.installForm#">
	<cftry>
		<cfset htlib = request.tapi.html>
		<cfset plugin.install(argumentcollection=attributes)>
		<cfset htlib.childSet(pluginmanager.view.main,1,plugin.getPluginManager().goHome())>
		
		<cfcatch>
			<cfset htlib.childAdd(pluginManager.view.error,"<p>#cfcatch.message#</p><p>#cfcatch.detail#</p>")>
			<cfinclude template="/inc/pluginmanager/view.cfm">
			<cf_abort>
		</cfcatch>
	</cftry>
</cf_validate>

<cfinclude template="/inc/pluginmanager/view.cfm">
