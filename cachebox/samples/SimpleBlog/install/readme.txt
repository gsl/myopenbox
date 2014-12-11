SimpleBlog 
by Henrik Joreteg 
Revised by Luis Majano and Isaac Dealey 

This is a rebuild of the SimpleBlog ColdBox sample application using only 
the database and some CFML code. This version does NOT require ColdBox or Transfer
and is designed to show simple integration of the CacheBox framework. 

Caching features are found in Application.cfc and /handlers/general.cfc 

********************************************************************************
Installation
********************************************************************************
1. You will need to create the database using the provided scripts, either MSSQL or MySQL
2. The datasource should be named: simpleblog


********************************************************************************
Default User:
********************************************************************************
username: admin
password: admin


********************************************************************************
Versions
********************************************************************************
1 - A basic blog using ColdBox and Transfer.  No service layers or gateways. All controller based.
Here are some techniques used:
	- Handler Caching setup
	- Usage of the ColdBox Cache
	- Event Caching
	- Event Caching Purging Techiniques
	- Autowiring from the cache
	- SES Routing
	- Basic Request Collection manipulation
	- Multi View Renderings
