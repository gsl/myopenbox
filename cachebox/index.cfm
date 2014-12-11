<cfset rc = duplicate(url) />
<cfset structAppend(rc,form,true) />
<cfparam name="rc.event" type="string" default="" />
<cfset rc.event = rereplace(trim(rc.event), "^$", "home") />

<cfsetting enablecfoutputonly="false" />

<cfprocessingdirective suppresswhitespace="false">
	<cfsavecontent variable="pageContent">
		<cftry>
			<cfsavecontent variable="temp">
				<cfinvoke component="#request.frontController#" 
					method="#rc.event#" argumentcollection="#rc#" />
			</cfsavecontent>
			
			<cfoutput>#temp#</cfoutput>
			
			<cfcatch type="CacheBox.Agent.NotRegistered">
				<cfset request.frontController.AgentNotRegistered(cfcatch.detail) />
			</cfcatch>
		</cftry>
	</cfsavecontent>
	
	<cfset request.frontController.showLayout(rc.event, pageContent, request.pageEvents) />
</cfprocessingdirective>