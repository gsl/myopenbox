<cfset rc = duplicate(url) />
<cfset structAppend(rc,form,true) />
<cfparam name="rc.event" type="string" default="home" />

<cfsetting enablecfoutputonly="false" />

<cfprocessingdirective suppresswhitespace="false">
	<cf_layout event="#rc.event#">
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
	</cf_layout>
</cfprocessingdirective>