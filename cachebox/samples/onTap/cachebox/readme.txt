**********************************************
*********      CacheBox Plugin      **********
**********************************************

COPYRIGHT 2009 S. Isaac Dealey 

For the latest information about 
the onTap framework visit the website at 
http://on.tapogee.com 

CONTENTS 
----------------------------------------------- 
- LICENSE 
- REQUIREMENTS 
- INSTALLATION 


LICENSE 
----------------------------------------------- 
The onTap framework and the Cachebox plugin 
are distributed under the terms of 
the OpenBSD open-source license. 
http://www.openbsd.org/policy.html


REQUIREMENTS
----------------------------------------------- 
This plugin requires the onTap framework 
version 3.2 build 20080803 or later and 
Plugin Manager version 3.2 build 20080803 or later. 


INSTALLATION
----------------------------------------------- 
To use the Plugin Manager to install this component.

STEP 1: Download and install the onTap framework and 
the Plugin Manager from http://on.tapogee.com  
and http://plugtap.riaforge.org respectively.
Obviously skip this step if you've already installed them. 

STEP 2: Navigate to your Plugin Manager index page 
usually located at http://[ontap]/admin/plugins. 
Select the tab labelled "more" and use the provided 
form to upload the zip archive into your application. [1] 

STEP 3: Once the files have been coppied, use the 
Plugin Manager tool to install the CacheBox plugin 
by navigating to http://[ontap]/admin/plugins and 
selecting the New Plugins tab. Locate the CacheBox 
plugin in the list of plugins waiting to be installed 
and select the install button. 

STEP 4: Accept the licensing agreement. 

STEP 5: You'll be presented with a form to configure 
the plugin. When you submit the configuration form, the 
installer will begin installing files for your application. 

STEP 6: You're done! Once the plugin is installed 
you will be returned to the Plugin Manager index. 

[Footnotes]
[1] If you have problems with the upload form, you 
can unzip the plugin manually into the Plugin Manager 
source directory. 

By default the source directory is located at 
[ontap]/_tap/admin/plugins/source 

The root /cachebox/ directory in the zip archive should 
be directly underneath the plugin source directory, i.e. 
[ontap]/_tap/admin/plugins/source/cachebox 

