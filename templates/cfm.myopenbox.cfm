<myopenbox>

	<parameters>
		<!-- 1:Development | 0:Production | -1:Deployment -->
		<parameter name="ProcessingMode" value="0" />
		<parameter name="ForceReparsePassword" value="APP_PASSWORD" />
	</parameters>
	
	<settings>
		<!-- Identification -->
		<setting name="Name" value="APP_NAME" />
		<setting name="Title" value="APP_TITLE" />
		
		<!-- DataBase -->
		<setting name="DB.DataSource" value="DSN_NAME" />
		<setting name="DB.UserName" value="" />
		<setting name="DB.Password" value="" />
		<setting name="DB.CachedWithin" value="#CreateTimespan(0, 0, 9, 59)#" />
	</settings>
	
	<phases>
		<phase name="PreProcess"></phase>
		<phase name="PostProcess"></phase>
	</phases>

</myopenbox>