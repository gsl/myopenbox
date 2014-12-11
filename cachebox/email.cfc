
<!--- to enable email alerts when memory failure is predicted, 
copy this component to the /cachebox/settings directory and edit the variables as needed 
once installed, email alerts may be modified without restarting the ColdFusion service --->

<cfcomponent output="false">

	<cffunction name="sendAlert" access="public" output="false" returntype="void">
		<cfargument name="subject" type="string" required="true" />
		<cfargument name="message" type="string" required="true" />
		
		<cfmail 
			from="noreply@..." 
			to="webmaster@..." 
			subject="#arguments.subject#">#message#</cfmail>
			
	</cffunction>
	
</cfcomponent>

