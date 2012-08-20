<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />
	
	<xsl:param name="serverid" />
	<xsl:param name="fingerprint" />
	<xsl:param name="trusted" />
	<xsl:param name="servers" />
	
	<!-- copy all nodes in the document verbatim -->
	<xsl:template match="/">
		<cluster>
			<xsl:attribute name="serverid"><xsl:value-of select="$serverid" /></xsl:attribute>
			<xsl:attribute name="fingerprint"><xsl:value-of select="$fingerprint" /></xsl:attribute>
			<trusted>
				<xsl:value-of select="$trusted" />
			</trusted>
			<servers>
				<xsl:value-of select="$servers" />
			</servers>
		</cluster>
	</xsl:template>
	
</xsl:stylesheet>