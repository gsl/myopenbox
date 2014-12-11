<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2008 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author 	    :	Isaac Dealey
Date        :	Sept 17, 2009
Description :
	This cfc takes care of debugging settings.

Modification History:
01/18/2007 - Created
----------------------------------------------------------------------->
<cfcomponent name="CBLoaderService" output="false" extends="LoaderService" 
hint="I replace the original application loader service to substitute CacheBox for storage">

	<!--- createCacheManager --->
    <cffunction name="createCacheManager" output="false" access="public" hint="Create the object cache manager">
    	<cfreturn CreateObject("component","coldbox.system.cache.CBCacheManager").init(controller) />
    </cffunction>
	
</cfcomponent>