<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />
	
	<xsl:param name="id" />
	<xsl:param name="storagetype" />
	<xsl:param name="evictpolicy" />
	<xsl:param name="evictafter" select="'0'" />
	
	<!-- copy all nodes in the document verbatim -->
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*" />
			<xsl:apply-templates />
		</xsl:copy>
	</xsl:template>
	
	<!-- copy the agents node and all sub-nodes, plus the new agent -->
	<xsl:template match="agents">
		<xsl:copy>
			<xsl:copy-of select="@*" />
			
			<!-- copy all agent nodes except for any matching the agentid being added -->
			<xsl:copy-of select="./*[@id!=$id]" />
			
			<!-- add the new agent node -->
			<agent>
				<!-- always include the agent id to uniquely identify this agent in the document -->
				<xsl:attribute name="id"><xsl:value-of select="$id" /></xsl:attribute>
				
				<!-- include the storage type only if a storage type is provided -->
				<xsl:if test="string-length($storagetype) > 0">
					<xsl:attribute name="storagetype"><xsl:value-of select="$storagetype" /></xsl:attribute>
				</xsl:if>
				
				<!-- include the eviction policy and eviction limit only if a policy name is provided -->
				<xsl:if test="string-length($evictpolicy) > 0">
					<xsl:attribute name="evictpolicy"><xsl:value-of select="$evictpolicy" /></xsl:attribute>
					
					<!-- if evictafter is less than 1 don't save it - this is the default for policies without limits -->
					<xsl:if test="number($evictafter) > 0">
						<xsl:attribute name="evictafter"><xsl:value-of select="$evictafter" /></xsl:attribute>
					</xsl:if>
				</xsl:if>
			</agent>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
