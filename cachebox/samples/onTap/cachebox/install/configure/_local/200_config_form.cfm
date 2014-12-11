<cfset defaultpath = expandpath('/cachebox') />

<cfparam name="attributes.plumbing" type="string" default="#defaultpath#" />
<cfset haspassword = plugin.isPasswordSet() />

<cfif directoryExists(defaultpath) and haspassword>
	<cf_html parent="#pluginmanager.view.main#">
		<div xmlns:tap="xml.tapogee.com">
			<cfif listlast(tap.process,"/") is "complete">
				<form tap:variable="installForm" />
			<cfelse>
				<script><cfoutput>
					<tap:location href="?netaction=#plugin.getValue('source')#/install/configure/complete&amp;download=1" domain="C" />
				</cfoutput></script>
			</cfif>
		</div>
	</cf_html>
<cfelse>
	<cf_html return="temp" parent="#pluginmanager.view.main#">
		<div xmlns:tap="xml.tapogee.com" 
		style="border:solid black 1px; background-color: #F0F0FF; width: 400px; padding: 10px; -moz-border-radius: 8px;">
			<form tap:domain="C" tap:variable="installForm">
				<input type="hidden" name="netaction" value="<cfoutput>#plugin.getValue('source')#</cfoutput>/install/configure/complete" />
				
				<cfif not plugin.isPasswordSet()>
					<div>Admin Password: <input type="password" name="password" tap:required="true" /></div>
				</cfif>
				<div>
					CacheBox Directory: <input name="plumbing" tap:required="true" /><button type="submit">Install</button>
					<div style="color:black; font-size:smaller;text-align:center;">Example: C:\apache\htdocs\cachebox\</div>
				</div>
				<div>
					<label><input type="checkbox" name="download" value="1" checked="checked" /> download the latest version</label>
				</div>
			</form>
		</div>
	</cf_html>
</cfif>