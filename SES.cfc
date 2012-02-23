<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2008 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author     :	Luis Majano
Date        :	9/28/2007
Description :
	This is an interceptor for ses support. This code is based almost totally on
	Adam Fortuna's ColdCourse cfc, which is an AMAZING SES component
	All credits go to him: http://coldcourse.riaforge.com
	
Modified for MyOpenbox framework 1/11/2010
----------------------------------------------------------------------->
<cfcomponent hint="This interceptor provides complete SES and URL mappings support to ColdBox Applications"
			 output="false">
				 
<!------------------------------------------- CONSTRUCTOR ------------------------------------------->

	<cfscript>
		// Reserved Keys as needed for cleanups
		instance.RESERVED_KEYS = "circuit,fuse";
		instance.RESERVED_ROUTE_ARGUMENTS = "";
		instance.config={ EventVariable="Fuseaction", DefaultHandler="Home", DefaultAction="Home" };
	</cfscript>

	<cffunction name="configure" access="public" returntype="void" hint="This is where the ses plugin configures itself." output="false" >
		<cfargument name="AppendStruct" required="false" default="#StructNew()#" type="struct" />
		<cfscript>
			StructAppend(instance.config, arguments.AppendStruct, true);
			// Setup the default interceptor properties
			setRoutes( ArrayNew(1) );
		</cfscript>
	</cffunction>
	

<!------------------------------------------- PUBLIC ------------------------------------------->
	
	
	<!--- Add a new Route --->
	<cffunction name="addRoute" access="public" returntype="void" hint="Adds a route to dispatch" output="false">
		<!--- ************************************************************* --->
		<cfargument name="pattern" 				 type="string" 	required="true"  hint="The pattern to match against the URL." />
		<cfargument name="circuit" 				 type="string" 	required="false" hint="The handler to execute if pattern matched.">
		<cfargument name="fuse"  				 type="any" 	required="false" hint="The action in a handler to execute if a pattern is matched.  This can also be a structure or JSON structured based on the HTTP method(GET,POST,PUT,DELETE). ex: {GET:'show', PUT:'update', DELETE:'delete', POST:'save'}">
		<cfargument name="vars" type="array" default="#ArrayNew(1)#" required="false" />
		<!--- ************************************************************* --->
		<cfscript>
		var thisRoute = structNew();
		var thisPattern = "";
		var thisPatternParam = "";
		var arg = 0;
		var x =1;
		var thisRegex = 0;
		var patternType = "";
			
		// Process all incoming arguments
		for(arg in arguments){
			if( structKeyExists(arguments,arg) ){ thisRoute[arg] = arguments[arg]; }
		}
		
		// Add trailing / to make it easier to parse
		if( left(thisRoute.pattern,1) IS NOT "/" ){
			thisRoute.pattern = "/" & thisRoute.pattern;
		}		
		// Cleanup initial /
		if( Len(thisRoute.pattern) GT 1 AND right(thisRoute.pattern,1) IS "/" ){
/*
			if( thisRoute.pattern eq "/" ){ 
				$throw(message="Pattern is empty, please verify the pattern is valid. Route: #thisRoute.toString()#",type="SES.InvalidRoute");
			}
*/
			thisRoute.pattern = left(thisRoute.pattern,len(thisRoute.pattern)-1);
		}
		
		// Check if we have optional args by looking for a ?
		if( findnocase("?",thisRoute.pattern) ){
			processRouteOptionals(thisRoute);
			return;
		}
				
		// Init the regexpattern
		thisRoute.regexPattern = "";
		thisRoute.patternParams = arrayNew(1);
		
		// Process the route as a regex pattern
		for(x=1; x lte listLen(thisRoute.pattern,"/");x=x+1){
			
			// Pattern and Pattern Param
			thisPattern = listGetAt(thisRoute.pattern,x,"/");
			thisPatternParam = replace(listFirst(thisPattern,"-"),":","");
			
			// Detect Optional Types
			patternType = "alphanumeric";
			if( findnoCase("-numeric",thisPattern) ){ patternType = "numeric"; }
			if( findnoCase("-alpha",thisPattern) ){ patternType = "alpha"; }
			
			switch(patternType){
				// ALPHANUMERICAL OPTIONAL
				case "alphanumeric" : {
					if( find(":",thisPattern) ){
						thisRegex = "(" & REReplace(thisPattern,":(.[^-]*)",".");
						// Check Digits Repetions
						if( find("{",thisPattern) ){
							thisRegex = listFirst(thisRegex,"{") & "{#listLast(thisPattern,"{")#)";
							arrayAppend(thisRoute.patternParams,replace(listFirst(thisPattern,"{"),":",""));
						}
						else{
							thisRegex = thisRegex & "+)";
							arrayAppend(thisRoute.patternParams,thisPatternParam);
						}
					}
					else{ 
						thisRegex = thisPattern; 
					}
					break;
				}
				// NUMERICAL OPTIONAL
				case "numeric" : {
					// Convert to Regex Pattern
					thisRegex = "(" & REReplace(thisPattern, ":.*?-numeric", "[0-9]");
					// Check Digits
					if( find("{",thisPattern) ){
						thisRegex = listFirst(thisRegex,"{") & "{#listLast(thisPattern,"{")#)";
					}
					else{
						thisRegex = thisRegex & "+)";
					}
					// Add Route Param
					arrayAppend(thisRoute.patternParams,thisPatternParam);
					break;
				}
				// ALPHA OPTIONAL
				case "alpha" : {
					// Convert to Regex Pattern
					thisRegex = "(" & REReplace(thisPattern, ":.*?-alpha", "[a-zA-Z]");
					// Check Digits
					if( find("{",thisPattern) ){
						thisRegex = listFirst(thisRegex,"{") & "{#listLast(thisPattern,"{")#)";
					}
					else{
						thisRegex = thisRegex & "+)";
					}
					// Add Route Param
					arrayAppend(thisRoute.patternParams,thisPatternParam);
					break;
				}
			} //end pattern type detection switch
			
			// Add Regex Created To Pattern
			thisRoute.regexPattern = thisRoute.regexPattern & "/" & thisRegex;
			
		} // end looping of pattern optionals
		
		thisRoute.vars=arguments.vars;
		
		// Finally add it to the routing table
		ArrayAppend(getRoutes(), thisRoute);
		</cfscript>
	</cffunction>
	
	<!--- Getter routes --->
	<cffunction name="getRoutes" access="public" output="false" returntype="Array" hint="Get the array containing all the routes">
		<cfreturn instance.Routes/>
	</cffunction>	

<!------------------------------------------- PRIVATE ------------------------------------------->
    
	<!--- Set Routes --->
	<cffunction name="setRoutes" access="private" output="false" returntype="void" hint="Internal override of the routes array">
		<cfargument name="Routes" type="Array" required="true"/>
		<cfset instance.Routes = arguments.Routes/>
	</cffunction>
	
	<!--- CGI Element Facade. --->
	<cffunction name="getCGIElement" access="private" returntype="string" hint="The cgi element facade method" output="false" >
		<cfargument name="cgielement" required="true" type="string" hint="The cgi element to retrieve">
		<cfscript>
			return cgi[arguments.cgielement];
		</cfscript>
	</cffunction>
	
	<!--- Fix Ending IIS funkyness --->
	<cffunction name="fixIISURLVars" access="private" returntype="string" hint="Clean up some IIS funkyness" output="false" >
		<cfargument name="requestString"  type="any" required="true" hint="The request string">
		<cfargument name="rc"  			  type="any" required="true" hint="The request collection">
		<cfscript>
			var varMatch = 0;
			var qsValues = 0;
			var qsVal = 0;
			var x = 1;
			
			// Find a Matching position of IIS ?
			varMatch = REFind("\?.*=",arguments.requestString,1,"TRUE");
			if( varMatch.pos[1] ){
				// Copy values to the RC
				qsValues = REreplacenocase(arguments.requestString,"^.*\?","","all");	
				// loop and create
				for(x=1; x lte listLen(qsValues,"&"); x=x+1){
					qsVal = listGetAt(qsValues,x,"&");
					rc[listFirst(qsVal,"=")] = listLast(qsVal,"=");
				}
				// Clean the request string
				arguments.requestString = Mid(arguments.requestString, 1, (varMatch.pos[1]-1));
			}
			
			return arguments.requestString;
		</cfscript>
	</cffunction>
	
	<!--- Find a route --->
	<cffunction name="findRoute" access="public" output="false" returntype="Struct" hint="Figures out which route matches this request">
		<!--- ************************************************************* --->
		<cfargument name="action" required="true" type="any" hint="The action evaluated by the path_info">
		<!--- ************************************************************* --->
		<cfset var requestString = arguments.action />
		<cfset var packagedRequestString = "">
		<cfset var match = structNew() />
		<cfset var foundRoute = structNew() />
		<cfset var params = structNew() />
		<cfset var key = "" />
		<cfset var i = 1 />
		<cfset var x = 1 >
		<cfset var _routes = getRoutes()>
		<cfset var _routesLength = ArrayLen(_routes)>
		
		<cfscript>
			// fix URL vars after ?
			//requestString = fixIISURLVars(requestString,rc);
			//Remove the leading slash
			if( len(requestString) GT 1 AND right(requestString,1) eq "/" ){
				requestString = left(requestString,len(requestString)-1);
			}
			// Add ending slash
			if( left(requestString,1) IS NOT "/" ){
				requestString = "/" & requestString;
			}
			
			// Let's Find a Route, Loop over all the routes array
			for(i=1; i lte _routesLength; i=i+1){
				// Match The route to request String
				match = reFindNoCase(_routes[i].regexPattern,requestString,1,true);
				//writedump(match);
				if( match.len[1] IS NOT 0 AND match.pos[1] EQ 1 ){
					// Setup the found Route
					foundRoute = _routes[i];
					break;
				}				
			}//end finding routes
			
		</cfscript>
		<!--- <cfdump var="#foundRoute#" /><cfabort /> --->
		<cfscript>
			// Check if we found a route, else just return empty params struct
			if( structIsEmpty(foundRoute) ){ return params; }
			
			// Populate the params, with variables found in the request string
			for(x=1; x lte arrayLen(foundRoute.patternParams); x=x+1){
				params[foundRoute.patternParams[x]] = mid(requestString, match.pos[x+1], match.len[x+1]);
			}
			
			// Now setup all found variables in the param struct, so we can return
			for(key in foundRoute){
				if( NOT listFindNoCase(instance.RESERVED_ROUTE_ARGUMENTS,key) ){
					params[key] = foundRoute[key];
				}
				else if (key eq "matchVariables"){
					for(i=1; i lte listLen(foundRoute.matchVariables); i = i+1){
						params[listFirst(listGetAt(foundRoute.matchVariables,i),"=")] = listLast(listGetAt(foundRoute.matchVariables,i),"=");
					}
				}
			}
		</cfscript>
		<!--- <cfdump var="#params#" /><cfabort /> --->
		<cfscript>
			return params;			
		</cfscript>
	</cffunction>
	
	<cffunction name="processRouteOptionals" access="private" returntype="void" hint="Process route optionals" output="false" >
		<cfargument name="thisRoute"  type="struct" required="true" hint="The route struct">
		<cfscript>
			var x=1;
			var thisPattern = 0;
			var base = "";
			var optionals = "";
			var routeList = "";
			
			// Parse our base & optionals
			for(x=1; x lte listLen(arguments.thisRoute.pattern,"/"); x=x+1){
				thisPattern = listgetAt(arguments.thisRoute.pattern,x,"/");
				// Check for ?
				if( not findnocase("?",thisPattern) ){ 
					base = base & thisPattern & "/"; 
				}
				else{ 
					optionals = optionals & replacenocase(thisPattern,"?","","all") & "/";
				}
			}
			// Register our routeList
			routeList = base & optionals;
			// Recurse and register in reverse order
			for(x=1; x lte listLen(optionals,"/"); x=x+1){
				// Create new route
				arguments.thisRoute.pattern = routeList;
				// Register route
				addRoute(argumentCollection=arguments.thisRoute);	
				// Remove last bit
				routeList = listDeleteat(routeList,listlen(routeList,"/"),"/");		
			}
			// Setup the base route again
			arguments.thisRoute.pattern = base;
			// Register the final route
			addRoute(argumentCollection=arguments.thisRoute);
		</cfscript>
	</cffunction>

</cfcomponent>