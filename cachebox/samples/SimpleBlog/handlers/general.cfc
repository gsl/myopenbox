<!-----------------------------------------------------------------------
Author 	 :	Henrik Joreteg (modified by Isaac Dealey)
Date     :	October, 2008
Description : 			
	This used to be a ColdBox Event Handler. (Isaac)

----------------------------------------------------------------------->
<cfcomponent name="general" output="false">
	<cfset dsn = "simpleblog" />

<!----------------------------------- CONSTRUCTOR --------------------------------------->	
	
	<cffunction name="init" access="public" returntype="any" output="false" hint="constructor">
		<cfargument name="controller" type="any">
		<cfset instance.controller = arguments.controller />
		<cfreturn this>
	</cffunction>
	
<!----------------------------------- PUBLIC EVENTS --------------------------------------->
	
	<cffunction name="index" access="public" returntype="void" output="false">
		<cfargument name="Event" type="any">
		<cfscript>
			/* Welcome message */
			Event.setValue("welcomeMessage","Hello, welcome to Simple Blog!");
			/* Display View */
			Event.setView("home");
		</cfscript>
	</cffunction>
	
	<!--- about --->
	<cffunction name="about" access="public" returntype="void" output="false" hint="">
		<cfargument name="Event" type="any" required="yes">
	    <cfset var rc = event.getCollection()>
	    <!--- Display View --->    	
		<cfset Event.setView("about")>
	</cffunction>
	
	<!--- blog --->
	<cffunction name="blog" access="public" returntype="void" output="false" hint="Displays the blog page" cache="true" cacheTimeout="10">
		<cfargument name="Event" type="any" required="yes">
		<cfset var rc = event.getCollection() />
		<cfset var qry = 0 />
		
		<cfset event.setView("blog") />
		<cfquery name="qry" datasource="#dsn#">
			select * from entries 
			order by time desc 
		</cfquery>
		
		<cfset rc.posts = qry />
	</cffunction>
	
	<!--- newPost --->
	<cffunction name="newPost" access="public" returntype="void" output="false" hint="">
		<cfargument name="Event" type="any" required="yes">
	    <cfset var rc = event.getCollection()>
	        
	    <cfset Event.setView("newPost")>	     
	</cffunction>
	
	<!--- doNewPost --->
	<cffunction name="doNewPost" access="public" returntype="void" output="false" hint="Action to handle new post operation">
		<cfargument name="Event" type="any" required="yes">
	    <cfset var rc = event.getCollection()>
		 <cfset var entry_id = CreateUUID() />
	    <cfset var newPost = "">
		 
		 <cfquery datasource="#dsn#">
		 	insert into entries 
				(entry_id, entryBody, author, title, time) 
			values (
				<cfqueryparam value="#entry_id#" cfsqltype="cf_sql_varchar" />,
				<cfqueryparam value="#rc.entryBody#" cfsqltype="cf_sql_varchar" />,
				<cfqueryparam value="#rc.author#" cfsqltype="cf_sql_varchar" />,
				<cfqueryparam value="#rc.title#" cfsqltype="cf_sql_varchar" />,
				<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp" />
			)
		 </cfquery>
		 
		 <cfset getCache().expire("event.general.blog") />
		 
		 <cflocation url="#event.buildLink('general.blog')#" addtoken="false" />
	    
	</cffunction>
	
	<!--- viewPost --->
	<cffunction name="viewPost" access="public" returntype="void" output="false" hint="Shows one particular post and related comments" cache="true" cacheTimeout="10" >
		<cfargument name="Event" type="any" required="yes">
	    <cfset var rc = event.getCollection()>
		 <cfset var entry = 0 />
		 <cfset var comments = 0 />
		 
		 <cfquery name="entry" datasource="#dsn#">
		 	select * from entries 
			where entry_id = <cfqueryparam value="#rc.id#" cfsqltype="cf_sql_varchar" />
		 </cfquery>
		 
		 <cfquery name="comments" datasource="#dsn#">
		 	select * from comments 
			where entry_id = <cfqueryparam value="#rc.id#" cfsqltype="cf_sql_varchar" />
			order by time asc 
		 </cfquery>
		 
		 <cfset rc.qPost = entry />
		 <cfset rc.qComments = comments />
		 <cfset event.setView("viewPost") />
	</cffunction>
	
	<!--- doAddComment --->
	<cffunction name="doAddComment" access="public" returntype="void" output="false" hint="action that adds comment">
		<cfargument name="Event" type="any" required="yes">
	    <cfset var rc = event.getCollection()>
		 
		 <cfquery datasource="#dsn#">
		 	insert into comments 
				(comment_id, entry_id, comment, time) 
			values (
				<cfqueryparam value="#CreateUUID()#" cfsqltype="cf_sql_varchar" />,
				<cfqueryparam value="#rc.id#" cfsqltype="cf_sql_varchar" />,
				<cfqueryparam value="#rc.commentfield#" cfsqltype="cf_sql_varchar" />,
				<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp" />
			) 
		 </cfquery>
		 
		 <cfset getCache().expire("event.general.viewpost.#rc.id#") />
		 <cflocation url="#event.buildLink('general/viewPost/' & rc.ID)#" addtoken="false" />
	</cffunction>
	
<!----------------------------------- UTILITIES --------------------------------------->
	
	<cffunction name="getController" access="private" output="false">
		<cfreturn instance.controller />
	</cffunction>
	
	<cffunction name="getCache" access="private" output="false">
		<cfreturn getController().getCache() />
	</cffunction>
	
	
	
</cfcomponent>