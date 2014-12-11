<cfcomponent name="CacheBoxBeanFactory" 
			displayname="BeanFactory" 
			extends="coldspring.beans.DefaultXmlBeanFactory" 
			hint="Adds CacheBox caching integration to ColdSpring" 
			output="false">
	
	<cffunction name="init" access="public" output="false" hint="Constuctor. Creates a beanFactory">
		<cfargument name="CacheAgentName" type="string" required="false" default="coldbox" />
		<cfargument name="CacheAgentContext" type="string" required="false" default="application" />
		<cfargument name="defaultAttributes" type="struct" required="false" default="#structnew()#" hint="default behaviors for undefined bean attributes"/>
		<cfargument name="defaultProperties" type="struct" required="false" default="#structnew()#" hint="any default properties, which can be refernced via ${key} in your bean definitions"/>
		
		<cfset super.init(defaultAttributes,defaultProperties) />
		<cfset variables.cachebox = CreateObject("component","cacheboxagent").init(CacheAgentName,CacheAgentContext,"none") />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getCacheAgent" access="public" output="false">
		<cfreturn variables.cachebox />
	</cffunction>
	
	<cffunction name="singletonCacheContainsBean" access="public" returntype="boolean" output="false">
		<cfargument name="beanName" type="string" required="true" />
		<cfset var result = variables.CacheBox.fetch(beanName) />
		
		<cfif not result.status>
			<cfreturn true />
		</cfif>
		
		<cfif isObject(variables.parent)>
			<cfreturn variables.parent.singletonCacheContainsBean(beanName) />
		</cfif>
		
		<cfreturn false />
	</cffunction>
	
	<cffunction name="getBeanFromSingletonCache" access="public" returntype="any" output="false">
		<cfargument name="beanName" type="string" required="true" />
		<cfset var result = variables.CacheBox.fetch(beanName) />
		<cfset var objExists = true />
		
		<cfif not result.status>
			<cfreturn result.content />
		</cfif>
		
		<cfif isObject(variables.parent)>
			<cfreturn variables.parent.getBeanFromSingletonCache(arguments.beanName) />
		</cfif>
		
		<cfthrow message="Cache error, #beanName# does not exists" />
	</cffunction>
	
	<cffunction name="addBeanToSingletonCache" access="public" returntype="any" output="false">
		<cfargument name="beanName" type="string" required="true" />
		<cfargument name="beanObject" type="any" required="true" />
		<cfreturn variables.CacheBox.store(beanName,beanObject).content />
	</cffunction>
	
	<cffunction name="constructBean" access="private" returntype="any">
		<cfargument name="beanName" type="string" required="true"/>
		<cfargument name="returnInstance" type="boolean" required="false" default="false" 
					hint="true when constructing a non-singleton bean (aka a prototype)"/>
					
		<cfset var localBeanCache = StructNew() />
		<cfset var dependentBeanDefs = ArrayNew(1) />
		<!--- first get list of beans including this bean and it's dependencies
		<cfset var dependentBeanNames = getMergedBeanDefinition(arguments.beanName).getDependencies(arguments.beanName) /> --->
		<cfset var beanDefIx = 0 />
		<cfset var beanDef = 0 />
		<cfset var beanInstance = 0 />
		<cfset var dependentBeanDef = 0 />
		<cfset var dependentBeanInstance = 0 />
		<cfset var propDefs = 0 />
		<cfset var propType = 0 />
		<cfset var prop = 0/>
		<cfset var argDefs = 0 />
		<cfset var argType = "" />
		<cfset var arg = 0/>
		<cfset var md = '' />
		<cfset var functionIndex = '' />
		<!--- new, for faster factoryBean lookup --->
		<cfset var searchMd = '' />
		<cfset var instanceType = '' />
		<cfset var factoryBeanDef = '' />
		<cfset var factoryBean = 0>
		
		<cfset var dependentBeanNames = "" />
		<cfset var dependentBeans = StructNew() />
		
		<cfset var mergedBeanDefinition = getMergedBeanDefinition(arguments.beanName) />
		
		<!--- <cfif mergedBeanDefinition.dependenciesChecked()>
			<cfset dependentBeans = mergedBeanDefinition.getDependentBeans()>
		<cfelse>
		</cfif> --->
		<cfset dependentBeans.allBeans = arguments.beanName />
		<cfset dependentBeans.orderedBeans = "" />
		<cfset mergedBeanDefinition.getDependencies(dependentBeans) />
			
		<cfset dependentBeanNames = ListPrepend(dependentBeans.orderedBeans, arguments.beanName) />
		
		<!--- DEBUGGING DEP LIST
		DEPENDECY LIST:<BR/>
		<cfdump var="#dependentBeanNames#" label="DEPENDENCY LIST"/><cfabort/> --->
		
		<!--- put them all in an array, and while we're at it, make sure they're in the singleton cache, or the localbean cache --->
		
		<cfloop from="1" to="#ListLen(dependentBeanNames)#" index="beanDefIx">
			<cfset beanDef = getMergedBeanDefinition(ListGetAt(dependentBeanNames,beanDefIx)) />
			<cfset ArrayAppend(dependentBeanDefs,beanDef) />
			
			<cfif beanDef.getFactoryBean() eq "">
				<!--- Factory beans are a special situation, and we actually don't want to create them in this way, because
					their constructor args may be dependencies, so we will create them in the NEXT loop, along with
					init methods --->
				<cfif beanDef.isAbstract()>
					<cfthrow type="coldspring.BeanCreationException" 
							 detail="Abstract Beans cannot be instanciated. Did you really meen to define: #beanDef.getBeanID()# as 'Abstract'?"/>
				</cfif>
				
				<!--- there are only two places where we check then create objects in the singletone cache, we need to 
					  introduce a mutually exclusive lock around this --->
				<cflock name="bf_#variables.beanFactoryId#.bean_#beanDef.getBeanID()#" throwontimeout="true" timeout="10">
					<cfif beanDef.isSingleton() and not singletonCacheContainsBean(beanDef.getBeanID())>
						<cfset beanDef.getBeanInstance() />
					<cfelse>
						<cfset localBeanCache[beanDef.getBeanID()] = beanDef.getBeanInstance() />
					</cfif>
				</cflock>
			</cfif>
		</cfloop>
	
		<!--- now resolve all dependencies by looping through list backwards, causing the "most dependent" beans to get created first  --->
		<cfloop from="#ArrayLen(dependentBeanDefs)#" to="1" index="beanDefIx" step="-1">
			<cfset beanDef = dependentBeanDefs[beanDefIx] />
			
			<!--- this is the second place we need to lock --->
			<cflock name="bf_#variables.beanFactoryId#.bean_#beanDef.getBeanID()#" throwontimeout="true" timeout="10">
				
				<cfif not beanDef.isConstructed()>
				
					<cfset argDefs = beanDef.getConstructorArgs()/>
					<cfset propDefs = beanDef.getProperties()/>
					
					<!--- if this is a 'normal' bean, we can just get the created reference
						but if it's a factory bean, we have to create it now --->
					<cfif beanDef.getFactoryBean() eq "">
					
						<cfif beanDef.isSingleton()>
							<cfset beanInstance = getBeanFromSingletonCache(beanDef.getBeanID())>
						<cfelse>
							<cfset beanInstance = localBeanCache[beanDef.getBeanID()] />
						</cfif>
						
						<!--- make sure the beanInstance is an object if we are gonna look at it
							  (beanInstance could be anything)  --->
						<cfif isCFC(beanInstance)>
							<cfset md = flattenMetaData(getMetaData(beanInstance))/>
						<cfelse>
							<cfset md = structnew()/>
							<cfset md.name = ""/>
						</cfif>
		
						
					<cfelse>
						
						<!--- retrieve the factoryBeanDef, then the factory bean --->
						<cfset factoryBeanDef = getMergedBeanDefinition(beanDef.getFactoryBean()) />
						
						<cfif factoryBeanDef.isAbstract()>
							<cfthrow type="coldspring.BeanCreationException" 
									 detail="Abstract Beans cannot be instanciated. Did you really meen to define: #beanDef.getBeanID()# as 'Abstract'?"/>
						</cfif>
						
						<cfif factoryBeanDef.isSingleton()>
							<cfset factoryBean = factoryBeanDef.getInstance() />
						<cfelse>
							<cfif factoryBeanDef.isFactory()>
								<cfset factoryBean = localBeanCache[factoryBeanDef.getBeanID()].getObject() />
							<cfelse>
								<cfset factoryBean = localBeanCache[factoryBeanDef.getBeanID()] />
							</cfif>
						</cfif>
						
						<cftry>
							<!--- now call the 'constructor' to generate the bean, which is the factoryMethod --->
							<cfinvoke component="#factoryBean#" method="#beanDef.getFactoryMethod()#" 
								returnvariable="beanInstance">
								<!--- loop over constructor-args and pass them into the factoryMethod --->
								<cfloop collection="#argDefs#" item="arg">
									<cfset argType = argDefs[arg].getType() />
									<cfif argType eq "value">
										<cfinvokeargument name="#argDefs[arg].getArgumentName()#" value="#argDefs[arg].getValue()#"/>
									<cfelseif argType eq "list" or argType eq "map">
										<cfinvokeargument name="#argDefs[arg].getArgumentName()#" value="#constructComplexProperty(argDefs[arg].getValue(),argDefs[arg].getType(), localBeanCache)#"/>
									<cfelseif argType eq "ref" or argType eq "bean">
										<cfset dependentBeanDef = getMergedBeanDefinition(argDefs[arg].getValue()) />
											<cfif dependentBeanDef.isSingleton()>
												<cfset dependentBeanInstance = dependentBeanDef.getInstance() />
											<cfelse>
												<cfif dependentBeanDef.isFactory()>
													<cfset dependentBeanInstance = localBeanCache[dependentBeanDef.getBeanID()].getObject() />
												<cfelse>
													<cfset dependentBeanInstance = localBeanCache[dependentBeanDef.getBeanID()] />
												</cfif>
											</cfif>
											<cfinvokeargument name="#argDefs[arg].getArgumentName()#" value="#dependentBeanInstance#"/>
									</cfif>	  								
								</cfloop>
							</cfinvoke>
							<cfcatch type="any">
								<cfthrow type="coldspring.beanCreationException" 
									message="Bean creation exception during factory-method call (trying to call #beanDef.getFactoryMethod()# on #factoryBeanDef.getBeanClass()#)" 
									detail="#cfcatch.message#:#cfcatch.detail#">							
							</cfcatch>						
						</cftry>					
						<!--- since we skipped factory beans in the bean creation loop, we need to store a reference to the bean now --->
						<cfif beanDef.isSingleton() and not singletonCacheContainsBean(beanDef.getBeanID())>
							<cfset beanInstance = beanDef.getBeanFactory().addBeanToSingletonCache(beanDef.getBeanID(), beanInstance) />
						<cfelse>
							<cfset localBeanCache[beanDef.getBeanID()] = beanInstance /> 
						</cfif>
						<!--- make sure the beanInstance is an object if we are gonna look at it
							  (beanInstance could be anything returned from a factory-method call)  --->
						<cfif isCFC(beanInstance)>
							<cfset md = flattenMetaData(getMetaData(beanInstance))/>
						<cfelse>
							<cfset md = structnew()/>
							<cfset md.name = ""/>
						</cfif>
					</cfif>
					
					<cfif structKeyExists(md, "functions")>
						<!--- we need to call init method if it exists --->
						<cfloop from="1" to="#arraylen(md.functions)#" index="functionIndex">
							<cfif md.functions[functionIndex].name eq "init"
									and beanDef.getFactoryBean() eq "">
								
								<cftry>
								<cfinvoke component="#beanInstance#" method="init">
									<!--- loop over any bean constructor-args and pass them into the init() --->
									<cfloop collection="#argDefs#" item="arg">
										<cfset argType = argDefs[arg].getType() />
										<cfif argType eq "value">
											<cfinvokeargument name="#argDefs[arg].getArgumentName()#"
													    	  value="#argDefs[arg].getValue()#"/>
										<cfelseif argType eq "list" or argType eq "map">
											<cfinvokeargument name="#argDefs[arg].getArgumentName()#"
													    	  value="#constructComplexProperty(argDefs[arg].getValue(),argDefs[arg].getType(), localBeanCache)#"/>
										<cfelseif argType eq "ref" or argType eq "bean">
											<cfinvokeargument name="#argDefs[arg].getArgumentName()#"
															  value="#getBean(argDefs[arg].getValue())#"/>
										</cfif>			  								
									</cfloop>
								</cfinvoke>
								
								<cfcatch type="any">
									<cfthrow type="coldspring.beanCreationException" 
										message="Bean creation exception during init() of #beanDef.getBeanClass()#" 
										detail="#cfcatch.message#:#cfcatch.detail#">
								</cfcatch>
							</cftry>
							
							<cfelseif md.functions[functionIndex].name eq "setBeanFactory"
									  and arraylen(md.functions[functionIndex].parameters) eq 1
									  and structKeyExists(md.functions[functionIndex].parameters[1],"type")
									  and md.functions[functionIndex].parameters[1].type eq "coldspring.beans.BeanFactory">
								<!--- call setBeanFactory() if it exists and is a beanFactory --->
								<cfset beanInstance.setBeanFactory(beanDef.getBeanFactory()) />	
								
							</cfif>
						</cfloop>
					</cfif>				
					
					<!--- if this is a bean that extends the factory bean, set IsFactory, and give it a ref to the beanFactory --->
					<cfset searchMd = md />
					<cfif searchMd.name IS 'coldspring.aop.framework.RemoteFactoryBean'>
						<cfset beanInstance.setId(arguments.beanName) />
					</cfif>
					<cfif searchMd.name IS 'coldspring.aop.framework.ProxyFactoryBean'>
						<cfset beanDef.setIsProxyFactory(true) />
					</cfif>
					
					<cfloop condition="#StructKeyExists(searchMd,"extends")#">
						<cfset searchMd = searchMd.extends />
						<cfif searchMd.name IS 'coldspring.aop.framework.RemoteFactoryBean'>
							<cfset beanInstance.setId(arguments.beanName) />
						</cfif>
						<cfif searchMd.name IS 'coldspring.aop.framework.ProxyFactoryBean'>
							<cfset beanDef.setIsProxyFactory(true) />
						</cfif>
						<cfif searchMd.name IS 'coldspring.beans.factory.FactoryBean'>
							<cfset beanDef.setIsFactory(true) />
							<!--- SO, We did this already (duck typing, above)
							<cfset beanInstance.setBeanFactory(this) /> --->
							<cfbreak />
						</cfif>
					</cfloop>
			
					<!--- now do dependency injection via setters --->		
					<cfloop collection="#propDefs#" item="prop">
						<cfset propType = propDefs[prop].getType() />
						<cfif propType eq "value">
							<cfinvoke component="#beanInstance#"
									  method="set#propDefs[prop].getName()#">
								<cfinvokeargument name="#propDefs[prop].getArgumentName()#"
									  	value="#propDefs[prop].getValue()#"/>
							</cfinvoke>			
						<cfelseif propType eq "map" or propType eq "list">
							<cfinvoke component="#beanInstance#"
									  method="set#propDefs[prop].getName()#">
								<cfinvokeargument name="#propDefs[prop].getArgumentName()#"
									  	value="#constructComplexProperty(propDefs[prop].getValue(), propDefs[prop].getType(), localBeanCache)#"/>
							</cfinvoke>				
						<cfelseif propType eq "ref" or propType eq "bean">
							<cfset dependentBeanDef = getMergedBeanDefinition(propDefs[prop].getValue()) />
							<cfif dependentBeanDef.isSingleton()>
								<cfset dependentBeanInstance = dependentBeanDef.getInstance() />
							<cfelse>
								<cfif dependentBeanDef.isFactory()>
									<cfset dependentBeanInstance = localBeanCache[dependentBeanDef.getBeanID()].getObject() />
								<cfelse>
									<cfset dependentBeanInstance = localBeanCache[dependentBeanDef.getBeanID()] />
								</cfif>
							</cfif>
							
							<cfinvoke component="#beanInstance#"
									  method="set#propDefs[prop].getName()#">
								<cfinvokeargument name="#propDefs[prop].getArgumentName()#"
												  value="#dependentBeanInstance#"/>
							</cfinvoke>
						</cfif>
					</cfloop>
					
					<!--- in order to inject the proper advisors into the aop proxy factories, we should do this now, 
						  instead of letting them lookup their own objects --->
					<cfif beanDef.isProxyFactory()>
						<cfset beanInstance.buildAdvisorChain(localBeanCache) />
					</cfif>
						
					<cfif beanDef.isSingleton()>
						<cfset beanDef.setIsConstructed(true)/>
					</cfif>
					
				</cfif>
			
			</cflock>
		</cfloop>
		
		<!--- now loop again (same direction: backwards) for init-methods --->
		<cfloop from="#ArrayLen(dependentBeanDefs)#" to="1" index="beanDefIx" step="-1">
			<cfset beanDef = dependentBeanDefs[beanDefIx] />
			
			<cfif beanDef.isSingleton()>
				<cfset beanInstance = getBeanFromSingletonCache(beanDef.getBeanID())>
			<cfelse>
				<cfset beanInstance = localBeanCache[beanDef.getBeanID()] />
			</cfif>
			
			<!--- now call an init-method if it's defined --->
			<cfif beanDef.hasInitMethod() and not beanDef.getInitMethodWasCalled()>
								
				<cfinvoke component="#beanInstance#"
						  method="#beanDef.getInitMethod()#"/>
				
				<!--- make sure it only gets called once --->
				<cfset beanDef.setInitMethodWasCalled(true) />
						  
			</cfif>
			
		</cfloop>

		<!--- if we're supposed to return the new object, do it --->
		<cfif arguments.returnInstance>
			<cfif dependentBeanDefs[1].isSingleton()>
				<cfreturn getBeanFromSingletonCache(dependentBeanDefs[1].getBeanID())>
			<cfelse>
				<cfreturn localBeanCache[dependentBeanDefs[1].getBeanID()]>
			</cfif>	
		</cfif>	
		
	</cffunction>

</cfcomponent>