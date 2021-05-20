<cfcomponent extends="defaultconfig">
	<cfset instance.pollingURL = "http://" & cgi.HTTP_Host & Reverse(ListRest(Reverse(cgi.Script_Name), '/')) & "/monitor.cfm" />
	<!--- <cfset instance.preferred.cluster = "redis" /> --->
	<!--- <cfset instance.preferred = getStruct( cluster = "memcached", server = "memcached", application = "memcached" ) /> --->

	<cffunction name="init" access="public" output="true">
		<cfargument name="service" type="any" required="true" />
		<cfargument name="testInstance" type="any" required="false" default="" />

		<cfscript>
		local.env = CreateObject( "java", "java.lang.System" ).GetEnv();
		super.init(arguments.service, arguments.testInstance);

		if (StructKeyExists(local.env, "CACHEBOX_PASSWORD")) {
			if (NOT this.isPasswordSet()) {
				this.savePassword(local.env["CACHEBOX_PASSWORD"]);
			}
		}

		if (StructKeyExists(local.env, "CACHEBOX_PREFERRED_CLUSTER")) {
			instance.preferred.cluster = local.env["CACHEBOX_PREFERRED_CLUSTER"];
			if (instance.preferred.cluster EQ "redis") {
				local.storage = instance.StorageManager.getStorageType("redis");
				local.config = {
					factoryClass = local.env["CACHEBOX_REDIS_FACTORYCLASS"] ?: local.storage.getFactoryClass()
					, server = local.env["CACHEBOX_REDIS_SERVER"] ?: local.storage.getServer()
					, port = local.env["CACHEBOX_REDIS_PORT"] ?: local.storage.getPort()
					, password = local.env["CACHEBOX_REDIS_PASSWORD"] ?: local.storage.getPassword()
					, timeout = local.env["CACHEBOX_REDIS_TIMEOUT"] ?: local.storage.getTimeout()
				}
				local.storage.setConfig(local.config);
			}
			if (instance.preferred.cluster EQ "memcached") {
				local.storage = instance.StorageManager.getStorageType("memcached");
				local.config = {
					factoryClass = local.env["CACHEBOX_MEMCACHED_FACTORYCLASS"] ?: local.storage.getFactoryClass()
					, serverList = local.env["CACHEBOX_MEMCACHED_SERVERLIST"] ?: local.storage.getServerList()
					, defaultTimeout = local.env["CACHEBOX_MEMCACHED_DEFAULTTIMEOUT"] ?: local.storage.getDefaultTimeout()
					, defaultUnit = local.env["CACHEBOX_MEMCACHED_DEFAULTUNIT"] ?: local.storage.getDefaultUnit()
					, defaultExpiry = local.env["CACHEBOX_MEMCACHED_DEFAULTEXPIRY"] ?: local.storage.getDefaultExpiry()
				}
				local.storage.setConfig(local.config);
			}
		}
		if (StructKeyExists(local.env, "CACHEBOX_PREFERRED_SERVER")) {
			instance.preferred.server = local.env["CACHEBOX_PREFERRED_SERVER"];
		}
		if (StructKeyExists(local.env, "CACHEBOX_PREFERRED_APPLICATION")) {
			instance.preferred.application = local.env["CACHEBOX_PREFERRED_APPLICATION"];
		}
		</cfscript>
		
		<cfreturn this />
	</cffunction>

	<cffunction name="updateMonitoringTask" access="private" output="false"></cffunction>
</cfcomponent>
