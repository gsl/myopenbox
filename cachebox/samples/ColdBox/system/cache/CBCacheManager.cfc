<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2008 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author 	    :	Isaac Dealey
Date        :	Sept 17, 2009
Description :
	This is a cfc that handles caching of event handlers.

Dependencies :
 - Controller to get to dependencies
 - Interceptor Service for event model

----------------------------------------------------------------------->
<cfcomponent name="CBCacheManager" 
			extends="CacheManager" 
			hint="A CacheBox powered substitute for the ColdBox CacheManager." 
			output="false">

<!------------------------------------------- CONSTRUCTOR ------------------------------------------->
	
	<cfset instance.cachebox = getCacheBoxSettings() />
	
	<cffunction name="getCacheBoxSettings" access="private" output="false">
		<cfscript>
			var cb = structNew(); 
			
			// create cachebox agents for various objects that need to be stored 
			// using multiple agents allows each type of object to have its own eviction policy -- demand may not be linear across object types 
			cb = StructNew(); 
			cb.prefix = StructNew(); 
			
			cb.views = CreateObject("component","cachebox.cacheboxagent").init("coldbox_views"); 
			cb.prefix.views = this.VIEW_CACHEKEY_PREFIX; 
			
			cb.events = CreateObject("component","cachebox.cacheboxagent").init("coldbox_events"); 
			cb.prefix.events = this.EVENT_CACHEKEY_PREFIX; 
			
			cb.handlers = CreateObject("component","cachebox.cacheboxagent").init("coldbox_handlers"); 
			cb.prefix.handlers = this.HANDLER_CACHEKEY_PREFIX; 
			
			cb.interceptors = CreateObject("component","cachebox.cacheboxagent").init("coldbox_interceptors"); 
			cb.prefix.interceptors = this.INTERCEPTOR_CACHEKEY_PREFIX; 
			
			cb.plugins = CreateObject("component","cachebox.cacheboxagent").init("coldbox_plugins"); 
			cb.prefix.plugins = this.PLUGIN_CACHEKEY_PREFIX & "," & this.CUSTOMPLUGIN_CACHEKEY_PREFIX; 
			
			cb.other = CreateObject("component","cachebox.cacheboxagent").init("coldbox_other"); 
			
			return cb; 
		</cfscript>
	</cffunction>
	
<!------------------------------------------- PUBLIC ------------------------------------------->
	
	<!--- Simple cache Lookup --->
	<cffunction name="lookup" access="public" output="false" returntype="boolean" 
	hint="Check if an object is in cache, if not found it records a miss.">
		<!--- ************************************************************* --->
		<cfargument name="objectKey" type="any" required="true" hint="The key of the object to lookup.">
		<!--- ************************************************************* --->
		
		<cfset var agent = getCBAgentByKey(objectKey)>
		<cfset var tmpObj = agent.fetch(objectKey)>
		
		<cfreturn iif(tmpObj.status,false,true)>
	</cffunction>
	
	<!--- Get an object from the cache --->
	<cffunction name="get" access="public" output="false" returntype="any" hint="Get an object from cache. If it doesn't exist it returns the THIS.NOT_FOUND value">
		<!--- ************************************************************* --->
		<cfargument name="objectKey" type="any" required="true" hint="The key of the object to lookup.">
		<!--- ************************************************************* --->
		
		<cfset var agent = getCBAgentByKey(objectKey)>
		<cfset var tmpObj = agent.fetch(objectKey)>
		
		<cfif tmpObj.status>
			<cfreturn this.NOT_FOUND />
		<cfelse>
			<cfreturn tmpObj.content />
		</cfif>
	</cffunction>
	
	<!--- Get multiple objects from the cache --->
	<cffunction name="getMulti" access="public" output="false" returntype="struct" hint="The returned value is a structure of name-value pairs of all the keys that where found. Not found values will not be returned">
		<!--- ************************************************************* --->
		<cfargument name="keys" 			type="string" required="true" hint="The comma delimited list of keys to retrieve from the cache.">
		<cfargument name="prefix" 			type="string" required="false" default="" hint="A prefix to prepend to the keys">
		<!--- ************************************************************* --->
		<cfscript>
			var returnStruct = structnew();
			var fetch = 0; 
			var x = 1;
			var thisKey = "";
			/* Clear Prefix */
			arguments.prefix = trim(arguments.prefix);
			
			/* Loop on Keys */
			for(x=1;x lte listLen(arguments.keys);x=x+1){
				thisKey = arguments.prefix & listGetAt(arguments.keys,x);
				fetch = getCBAgentByKey(thisKey).fetch(thisKey); 
				if (not fetch.status) { 
					returnStruct[thiskey] = fetch.content; 
				} 
			}
			
			/* Return Struct */
			return returnStruct;
		</cfscript>
	</cffunction>
	
	<!--- Set an Object in the cache --->
	<!--- we're going to ignore the timeout and lastAccessTimeout arguments and just let CacheBox handle that instead 
	- we could alternatively create a CacheBoxNanny object to handle timeout, but we'll leave that for later --->
	<cffunction name="set" access="public" output="false" returntype="boolean" hint="sets an object in cache. Sets might be expensive. If the JVM threshold is used and it has been reached, the object won't be cached. If the pool is at maximum it will expire using its eviction policy and still cache the object. Cleanup will be done later.">
		<!--- ************************************************************* --->
		<cfargument name="objectKey" 			type="any"  required="true" hint="The object cache key">
		<cfargument name="myObject"				type="any" 	required="true" hint="The object to cache">
		<cfargument name="timeout"				type="any"  required="false" default="" hint="Timeout in minutes. If timeout = 0 then object never times out. If timeout is blank, then timeout will be inherited from framework.">
		<cfargument name="lastAccessTimeout"	type="any"  required="false" default="" hint="Last Access Timeout in minutes. If timeout is blank, then timeout will be inherited from framework.">
		<!--- ************************************************************* --->
		
		<cfset getCBAgentByKey(objectKey).store(objectKey,myObject) />
		
		<!--- I decided to leave these alone so that the interceptors can still work as normal ---> 
		<!--- InterceptMetadata --->
		<cfset interceptMetadata.cacheObjectKey = arguments.objectKey>
		<cfset interceptMetadata.cacheObjectTimeout = arguments.timeout>
		<cfset interceptMetadata.cacheObjectLastAccessTimeout = arguments.lastAccessTimeout>
		
		<!--- Execute afterCacheElementInsert Interception --->
		<cfset instance.controller.getInterceptorService().processState("afterCacheElementInsert",interceptMetadata)>				
		
		<cfreturn true>
	</cffunction>

	<!--- Clear an object from the cache --->
	<cffunction name="clearKey" access="public" output="false" returntype="boolean" hint="Clears an object from the cache by using its cache key. Returns false if object was not removed or did not exist anymore">
		<!--- ************************************************************* --->
		<cfargument name="objectKey" type="string" required="true" hint="The key the object was stored under.">
		<!--- ************************************************************* --->
		<cfset var interceptMetadata = structNew() />
		<cfset interceptMetadata.cacheObjectKey = arguments.objectKey>
		
		<cfreturn getCBAgentByKey(objectKey).delete(objectKey) />
		
		<!--- CacheBox doesn't inform the calling code if removal was successful --->
		<!--- Execute afterCacheElementRemoved Interception --->
		<cfset instance.controller.getInterceptorService().processState("afterCacheElementRemoved",interceptMetadata)>
		
		<cfreturn true>
	</cffunction>
	
	<!--- Clear an event --->
	<cffunction name="clearEvent" access="public" output="false" returntype="void" hint="Clears all the event permutations from the cache according to snippet and querystring. Be careful when using incomplete event name with query strings as partial event names are not guaranteed to match with query string permutations">
		<!--- ************************************************************* --->
		<cfargument name="eventsnippet" type="string" 	required="true" hint="The event snippet to clear on. Can be partial or full">
		<cfargument name="queryString" 	type="string" 	required="false" default="" hint="If passed in, it will create a unique hash out of it. For purging purposes"/>
		<cfargument name="async" 		type="boolean"  required="false" default="true" hint="Run asynchronously or not"/>
		<!--- ************************************************************* --->
		<cfscript>
			//.*- = the cache suffix and appendages for regex to match
			var cacheKey = this.EVENT_CACHEKEY_PREFIX & replace(arguments.eventsnippet,".","\.","all") & "%"; // changed regex .* to sql wildcard %
														  
			//Check if we are purging with query string
			if( len(arguments.queryString) neq 0 ){
				cacheKey = cacheKey & "-" & getEventURLFacade().buildHash(arguments.queryString);
			}
			
			// Clear All Events by Criteria 
			instance.cachebox.events.delete(cacheKey); // I *think* this will do the same thing with CacheBox that the ColdBox cache was doing 
		</cfscript>
	</cffunction>
	
	<!--- Clear All the Events form the cache --->
	<cffunction name="clearAllEvents" access="public" output="false" returntype="void" hint="Clears all events from the cache.">
		<!--- ************************************************************* --->
		<cfargument name="async" 		type="boolean"  required="false" default="true" hint="Run asynchronously or not"/>
		<!--- ************************************************************* --->
		<cfset instance.cachebox.events.reset() />
	</cffunction>
	
	<!--- clear View --->
	<cffunction name="clearView" output="false" access="public" returntype="void" hint="Clears all view name permutations from the cache according to the view name.">
		<!--- ************************************************************* --->
		<cfargument name="viewSnippet"  required="true" type="string" hint="The view name snippet to purge from the cache">
		<cfargument name="async" 		type="boolean"  required="false" default="true" hint="Run asynchronously or not"/>
		<!--- ************************************************************* --->
		<cfset instance.cachebox.views.delete(this.VIEW_CACHEKEY_PREFIX & arguments.viewSnippet) />
	</cffunction>
	
	<!--- Clear All The Views from the Cache. --->
	<cffunction name="clearAllViews" access="public" output="false" returntype="void" hint="Clears all views from the cache.">
		<!--- ************************************************************* --->
		<cfargument name="async" 		type="boolean"  required="false" default="true" hint="Run asynchronously or not"/>
		<!--- ************************************************************* --->
		<cfset instance.cachebox.views.reset() />
	</cffunction>
	
	<!--- Clear The Pool --->
	<!--- the Hint here is from the original ColdBox object and may not apply directly to this version --->
	<cffunction name="clear" access="public" output="false" returntype="void" 
	hint="Clears the entire object cache and recreates the object pool and statistics. Call from a non-cached object or you will get 500 NULL errors, VERY VERY BAD!!. TRY NOT TO USE THIS METHOD">
		<cfscript>
			var i = 0; 
			for (i in instance.cachebox) {
				if (i is not "other" and isObject(instance.cachebox[i])) { 
					instance.cachebox[i].reset(); 
				} 
			} 
		</cfscript>
	</cffunction>
	
	<!--- Get the Cache Size --->
	<cffunction name="getSize" access="public" output="false" returntype="numeric" hint="Get the cache's size in items">
		<cfscript>
			var result = 0; 
			var i = 0; 
			for (i in instance.cachebox) {
				if (isObject(instance.cachebox[i])) { 
					result += instance.cachebox[i].getSize(); 
				} 
			} 
			return result; 
		</cfscript>
	</cffunction>
	
	<!--- Reap the Cache --->
	<cffunction name="reap" access="public" output="false" returntype="void" hint="Reap the cache.">
		<!--- we ignore this method with CacheBox because cache is reaped on a scheduled task --->
	</cffunction>
	
	<!--- Expire All Objects --->
	<cffunction name="expireAll" access="public" returntype="void" hint="Expire All Objects. Use this instead of clear() from within handlers or any cached object, this sets the metadata for the objects to expire in the next request. Note that this is not an inmmediate expiration. Clear should only be used from outside a cached object" output="false" >
		<!--- ************************************************************* --->
		<cfargument name="async" 		type="boolean" required="false" default="true" hint="Run asynchronously or not"/>
		<!--- ************************************************************* --->
		<cfscript>
			var i = 0; 
			for (i in instance.cachebox) { 
				if (i is not "other" and isObject(instance.cachebox[i])) { 
					instance.cachebox[i].expire(); 
				} 
			} 
		</cfscript>
	</cffunction>
	
	<!--- Expire an Object --->
	<cffunction name="expireKey" access="public" returntype="void" hint="Expire an Object. Use this instead of clearKey() from within handlers or any cached object, this sets the metadata for the objects to expire in the next request. Note that this is not an inmmediate expiration. Clear should only be used from outside a cached object" output="false" >
		<!--- ************************************************************* --->
		<cfargument name="objectKey" type="string" required="true">
		<cfargument name="async" 	 type="boolean" required="false" default="true" hint="Run asynchronously or not"/>
		<!--- ************************************************************* --->
		<cfset getCBAgentByKey(objectKey).expire(objectKey) />
	</cffunction>
	
	<!--- Expire an Object --->
	<cffunction name="expireByKeySnippet" access="public" returntype="void" hint="Same as expireKey but can touch multiple objects depending on the keysnippet that is sent in." output="false" >
		<!--- ************************************************************* --->
		<cfargument name="keySnippet" type="string"  required="true" hint="The key snippet to use">
		<cfargument name="regex" 	  type="boolean" required="false" default="false" hint="Use regex or not">
		<cfargument name="async" 	  type="boolean" required="false" default="true" hint="Run asynchronously or not"/>
		<!--- ************************************************************* --->
		<cfset getCBAgentByKey(objectKey).expire(replace(objectKey,".*","%","ALL")) />
	</cffunction>
	
	<!--- Get The Cache Item Types --->
	<cffunction name="getItemTypes" access="public" output="false" returntype="struct" hint="Get the item types of the cache. These are calculated according to internal coldbox entry prefixes">
		<cfscript>
			var itemTypes = Structnew();
			
			itemTypes.plugins = instance.cachebox.plugins.getSize();
			itemTypes.handlers = instance.cachebox.handlers.getSize();
			itemTypes.other = instance.cachebox.other.getSize(); 
			itemTypes.ioc_beans = 0;
			itemTypes.interceptors = instance.cachebox.interceptors.getSize();
			itemTypes.events = instance.cachebox.events.getSize();
			itemTypes.views = instance.cachebox.views.getSize();
			
			return itemTypes;
		</cfscript>
	</cffunction>
	
<!------------------------------------------- ACCESSOR/MUTATORS ------------------------------------------->
	
	<cffunction name="getCBAgentByKey" access="private" output="false" returntype="any"
	hint="I return the appropriate cachebox agent for a specific cache key">
		<cfargument name="key" type="string" required="true" />
		<cfset var cb = instance.cachebox />
		<cfset var x = 0 />
		<cfset var i = 0 />
		
		<cfloop item="i" collection="#cb.prefix#">
			<cfloop index="x" list="#cb.prefix[i]#">
				<cfif findnocase(x,key) eq 1>
					<cfreturn cb[i] />
				</cfif>
			</cfloop>
		</cfloop>
		
		<cfreturn instance.cachebox.other />
	</cffunction>
	
<!------------------------------------------- PRIVATE ------------------------------------------->
	

</cfcomponent>