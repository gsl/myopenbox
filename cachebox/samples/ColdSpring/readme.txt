ColdSpring Framework: 
http://www.coldspringframework.org/

Documentation:
http://www.coldspringframework.org/index.cfm/go/documentation

================================================

ColdSpring is an open source Dependency Injection (DI) framework 
originally designed by David Ross, Chris Scott, Kurt Wiersma and 
Sean Corfield. This sample is designed to show how to integrate 
CacheBox into ColdSpring. To install and use this CacheBox enabled 
version of ColdSpring, simply copy the cacheboxagent.cfc and the 
components in the /beans/ directory into the /coldspring/beans/ 
directory and update your code to create the CacheBoxBeanFactory 
instead of the DefaultXmlBeanFactory. If you have multiple 
ColdSpring factories in your application, be sure you provide 
a unique cache agent name for each bean factory. 

NOTE: The current version of ColdSpring seems to store singleton 
objects twice - once in the singleton cache, and again in the 
BeanDefinition.cfc. This has made the integration slightly more 
challenging and required the inclusion of the modified 
BeanDefinition.cfc here in an attempt to eliminate the possibility 
of a race condition and/or duplicate objects in memory. 
This integration is written with ColdSpring version 1.2. If you're 
using a newer version of ColdSpring, you should merge the changes 
to BeanDefinition.cfc with a file-compare tool like WinMerge. 

Acknowledgement: This version of the ColdSpring integration was tested 
with Model-Glue Unity and the ByteSpring content management system (CMS) 

Model-Glue: http://www.model-glue.com
ByteSpring: http://www.bytespring.com 
