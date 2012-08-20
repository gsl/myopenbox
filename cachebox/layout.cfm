<cfparam name="attributes.event" type="string" default="home" />
<cfset controller = request.frontController />

<cfoutput>
	<cfswitch expression="#thistag.executionmode#">
		<cfcase value="start">#Controller.showHeader(attributes.event)#</cfcase>
		<cfcase value="end">#Controller.showFooter()#</cfcase>
	</cfswitch>
</cfoutput>
