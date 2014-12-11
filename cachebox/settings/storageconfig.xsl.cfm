<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />
	
	<xsl:param name="storagetype" />
	
	<!-- copy all nodes in the document verbatim -->
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*" />
			<xsl:apply-templates />
		</xsl:copy>
	</xsl:template>
	
	<!-- copy the agents node and all sub-nodes, plus the new agent -->
	<xsl:template match="form">
		<xsl:copy>
			<xsl:attribute name="action">?</xsl:attribute>
			<xsl:attribute name="method">post</xsl:attribute>
			<xsl:attribute name="enctype">multipart/formdata</xsl:attribute>
			<input type="hidden" name="event" value="storageupdate" />
			<input type="hidden" name="storagetype" value="{$storagetype}" />
			
			<table border="0" cellpadding="2" cellspacing="0">
				<xsl:if test="./head">
					<thead>
						<tr>
							<td colspan="2" style="padding-bottom: 15px;">
								<xsl:copy-of select="./head/node()" />
							</td>
						</tr>
					</thead>
				</xsl:if>
				<tbody>
					<!-- loop over the input elements in the form -->
					<xsl:for-each select="*[name()!='head' and name()!='foot']">
						<tr>
							<td><xsl:value-of select="concat(@label,':')" /></td>
							<td>
								<!-- display the input element minus the label attribute -->
								<xsl:copy>
									<xsl:copy-of select="@*[name()!='label']" />
									<xsl:copy-of select="./node()" />
								</xsl:copy>
							</td>
						</tr>
					</xsl:for-each>
				</tbody>
				
				<!-- display the submit button -->
				<tfoot>
					<tr>
						<td colspan="2" class="buttons">
							<button type="submit">Save</button>
						</td>
					</tr>
					<xsl:if test="./foot">
						<tr>
							<td colspan="2" style="padding-top: 15px;">
								<xsl:copy-of select="./foot/node()" />
							</td>
						</tr>
					</xsl:if>
				</tfoot>
			</table>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
