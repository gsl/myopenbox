<cfif NOT (IsDefined("application.MyOpenbox.Parameters.Dashboard.Enable") AND application.MyOpenbox.Parameters.Dashboard.Enable EQ true)>
	<h1>Dashboard not enabled</h1><cfabort />
<cfelseif NOT (structKeyExists(url, "auth")	AND IsDefined("application.MyOpenbox.Parameters.FWReparse")
	AND (
		url.auth EQ application.MyOpenbox.Parameters.FWReparse
		OR url.auth EQ Hash(application.MyOpenbox.Parameters.FWReparse)
	))>
	<h1>Authentication Required</h1><cfabort />
</cfif>