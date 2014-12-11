********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************
SimpleBlog
by Henrik Joreteg
Revised by Luis Majano

This is a simple blog engine that has been built using 4 different techniques using ColdBox and Transfer.

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
