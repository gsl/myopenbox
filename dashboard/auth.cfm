<cfif structKeyExists(url, "auth")
	AND IsDefined("application.MyOpenbox.Parameters.FWReparse")
	AND (
		url.auth EQ application.MyOpenbox.Parameters.FWReparse
		OR url.auth EQ Hash(application.MyOpenbox.Parameters.FWReparse)
	)>
<cfelse>
	<h1>Authentication Required</h1><cfabort />
</cfif>