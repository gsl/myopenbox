<!--- 
	== CacheBox is Free Software == 
	 
	 * Copyright (c) 2008 
	 * AutLabs and S. Isaac Dealey.  All rights reserved.
	 * 
	 * Redistribution and use in source and binary forms, with or without
	 * modification, are permitted provided that the following conditions
	 * are met:
	 * 1. Redistributions of source code must retain the above copyright
	 *    notice, this list of conditions and the following disclaimer.
	 * 2. Redistributions in binary form must reproduce the above copyright
	 *    notice, this list of conditions and the following disclaimer in the
	 *    documentation and/or other materials provided with the distribution.
	 * 3. All advertising materials mentioning features or use of this software
	 *    must display the following acknowledgment:
	 *	This product includes software developed by AutLabs and S. Isaac Dealey.
	 * 4. Neither the name of the AutLabs, S. Isaac Dealey or other contributors 
	 *    may be used to endorse or promote products derived from this software
	 *    without specific prior written permission.
	 * 
	 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
	 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
	 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
	 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
	 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
	 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
	 * SUCH DAMAGE. 
--->

<cfcomponent displayname="CacheBoxNanny" output="false" 
hint="I provide additional per-item cache expiration for CacheBox at the client, similar to ColdFusion query caching features">
	<cfset instance = structNew() />
	<cfset instance.created = now() />
	<cfset instance.rules = structNew() />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="Agent" type="any" required="true" hint="a CacheBox agent around which the Nanny is wrapped" />
		<cfset structAppend(instance,arguments,true) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getAgent" access="public" output="false" hint="I return the CacheBox agent aroudn which te Nanny is wrapped">
		<cfreturn instance.agent />
	</cffunction>
	
	<cffunction name="debug" access="public" output="true">
		<cfdump var="#variables.instance#" />
	</cffunction>
	
	<cffunction name="isCachedAfter" access="private" output="false" returntype="boolean" 
	hint="I check the birthdate of a content item for eviction based on a cachedafter date">
		<cfargument name="birth" type="string" required="true" hint="the time of the content item's creation" />
		<cfargument name="after" type="string" required="true" hint="the time after which the content is cached" />
		
		<!--- if no cachedafter date is supplied, the test passes by default--->
		<cfif not isDate(after)><cfreturn true /></cfif>
		
		<!--- otherwise apply the test --->
		<cfreturn iif(arguments.birth gt arguments.after,true,false) />
	</cffunction>
	
	<cffunction name="isCachedWithin" access="private" output="false" returntype="boolean" 
	hint="I check the birthdate of a content item for eviction based on a cachedwithin number">
		<cfargument name="birth" type="string" required="true" hint="the time of the content item's creation" />
		<cfargument name="within" type="string" required="true" hint="the interval within which the content is cached" />
		
		<!--- if no cachedwhithin interval was given, the test passes by default --->
		<cfif val(within) eq 0><cfreturn true /></cfif>
		
		<!--- otherwise apply the test --->
		<cfreturn iif(birth gte dateadd("s",-int(86400*arguments.within),now()),true,false) />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="struct">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="cachedafter" type="string" required="false" default="" />
		<cfset var agent = getAgent() />
		<cfset var result = structNew() />
		<cfset var evict = iif(structKeyExists(instance.rules,cachename),"instance.rules[cachename]","structNew()") />
		
		<cfparam name="evict.cachedwithin" type="numeric" default="0" />
		<cfparam name="evict.birth" type="date" default="#now()#" />
		
		<cfif not isCachedAfter(evict.birth,arguments.cachedafter) or not isCachedWithin(evict.birth,evict.cachedwithin)>
			<!--- the content is not fresh enough based on the cachedafter or cachedwithin arguments, return a standard cache miss status --->
			<cfset result.content = "" />
			<cfset result.status = 1 />
			<cfreturn result />
		</cfif>
		
		<cfreturn agent.fetch(cachename) />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="struct">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfargument name="cachedwithin" type="numeric" required="false" default="0" />
		
		<cfset instance.rules[arguments.cachename] = { cachedwithin=arguments.cachedwithin, birth=now() } />
		
		<cfreturn getAgent().store(cachename,content) />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" hint="removes one or more records from the agent's cache - a wild-card (%) at the end of the cache name can be used to remove multiple related records">
		<cfargument name="cachename" type="string" required="true" />
		<!--- throw away our expiration rules (this doesn't work with wildcards) --->
		<cfset structDelete(instance.rules,cachename) />
		<!--- remove the content from cache --->
		<cfset getAgent().delete(cachename) />
	</cffunction>
	
	<cffunction name="expire" access="public" output="false" hint="removes one or more records from the agent's cache - a wild-card (%) at the end of the cache name can be used to remove multiple related records">
		<cfargument name="cachename" type="string" required="false" default="%" />
		<!--- throw away our expiration rules (this doesn't work with partial wildcards) --->
		<cfif cachename is "%">
			<cfset structClear(instance.rules) />
		<cfelse>
			<cfset structDelete(instance.rules,cachename) />
		</cfif>
		<!--- remove the content from cache --->
		<cfset getAgent().expire(cachename) />
	</cffunction>
	
	<cffunction name="reset" access="public" output="false" hint="removes all content from cache for the wrapped agent">
		<!--- throw away our expiration rules --->
		<cfset instance.rules = structNew() />
		<!--- remove all agent content from cache --->
		<cfset getAgent().reset() />
	</cffunction>
	
	<cffunction name="getSize" access="public" output="false">
		<cfreturn getAgent().getSize() />
	</cffunction>
	
	<cffunction name="runMethod" access="public" output="false" returntype="any" 
	hint="I return the cache of a method result if it exists, otherwise I run the method and cache and return the results.">
		<cfargument name="component" type="any" required="true" />
		<cfargument name="method" type="string" required="true" />
		<cfargument name="args" type="struct" required="false" default="" />
		<cfargument name="cachedafter" type="string" required="false" default="">
		<cfargument name="cachedwithin" type="numeric" required="false" default="0">
		<cfargument name="cachename" type="string" default="#arguments.method#" />
		<cfset var result = 0 />
		
		<cfscript>
			if (len(trim(arguments.cachename)) and not structIsEmpty(arguments.args)) { 
				structDelete(arguments.args,"cachedafter"); 
				structDelete(arguments.args,"cachedwithin"); 
				structDelete(arguments.args,"cachename"); 
				
				// massage the cache name 
				arguments.cachename = arguments.cachename & ":" &  VarToString(arguments.args); 
				
				// check to see if it was cached already 
				result = this.fetch(arguments.cachename,arguments.cachedafter); 
				
				// okay, it was cached, so we don't need to execute it again 
				if (not result.status) { return result.content; } 
			} 
		</cfscript>
		
		<cfinvoke component="#arguments.component#" 
			returnvariable="result" 
			method="#arguments.method#" 
			argumentcollection="#arguments.args#" />
		
		<cfscript>
			if (len(trim(arguments.cachename))) { 
				result = this.store(arguments.cachename,result,arguments.cachedwithin).content; 
			} 
			
			return result; 
		</cfscript>
	</cffunction>
	
	<cffunction name="VarToString" access="private" output="false" returntype="string" 
	hint="I'm useful for creating cache names from arguments or other complex data">
		<cfargument name="variable" type="any" required="true" hint="A variable to convert to a URL string">
		<cfscript>
			var result = ""; 
			var keys = ""; 
			var ii = 0; 
			
			if ( isSimplevalue(arguments.variable) ) { 
				// these variables are most likely to be UUID or integer values, 
				// but we want to massage the data a little to be on the safe side 
				// So we're replacing all non-word characters with the tilde instead of a | or % that might cause problems later 
				result = rereplace(arguments.variable,"\W+","~","ALL"); 
			} else if ( isArray(arguments.variable) ) { 
				result = ArrayNew(1); 
				
				for ( ii=1; ii LTE ArrayLen(arguments.variable); ii = ii + 1 ) { 
					result[ii] = VarToString(arguments.variable[ii]); 
				} 
				
				result = "[#ArrayToList(result,':')#]"; 
			} else if ( isStruct(arguments.variable) ) { 
				result = listToArray(listSort(lcase(structKeyList(arguments.variable)),"text")); 
				
				for ( ii=ArrayLen(result); ii GTE 1; ii = ii - 1 ) { 
					if (not isDefined("variable.#result[ii]#") or // argument values can be unusable null values -- ARGH! 
					(isSimpleValue(variable[result[ii]]) and not len(trim(variable[result[ii]])))) { 
						arrayDeleteAt(result,ii); 
					} else { 
						result[ii] = result[ii] & "=" & VarToString(arguments.variable[result[ii]]); 
					} 
				} 
				
				result = "{#arrayToList(result,':')#}"; 
			} else { 
				result = "(unknown)"; 
			} 
			
			return result; 
		</cfscript>
	</cffunction>
</cfcomponent>

