<?xml version='1.0' encoding="UTF-8"?>
<xsl:stylesheet xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
<!--

  doilist.xsl

  input:   Marc-XML
  output:  tab delimited text (URL/AlephSysno)

  history:
  19.03.2013: 1. Version abi

-->

  <xsl:output method="text" encoding="UTF-8" />

  <xsl:variable name="TAB" select="'&#x09;'" />
  <xsl:variable name="NL"  select="'&#x0A;'" />

  <xsl:template match="/">

<!-- Daten fuer Liste -->
	   <xsl:for-each select="//marc:datafield[@tag='856']">
			<xsl:value-of select="marc:subfield[@code='u']"/>
			<xsl:value-of select="$TAB"/>
			<xsl:value-of select="../marc:controlfield[@tag='001']"/>
			<xsl:value-of select="$NL"/>
		</xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
