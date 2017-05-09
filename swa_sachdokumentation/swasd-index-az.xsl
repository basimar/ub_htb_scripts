<?xml version='1.0' encoding="UTF-8"?>
<!--

  swasd-index-az.xsl
  sortiere die indexterms.xml und erstelle eine Textdatei.
  Bei mehreren gleichlautenden Deskriptoren wird jeweils
  nur der erste ausgegeben.

  History:
  20.08.2010 rewrite andres.vonarx@unibas.ch

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output
    method="text"
    encoding="UTF-8"
    />
  <xsl:strip-space elements="*"/>
  <xsl:key name="keyTerm" match="//term" use="."/>
  <xsl:variable name="NL" select="'&#x0A;'" />
  <xsl:template match="/">
    <xsl:variable name="uniqueTerms"
      select="//term[generate-id(.)=generate-id(key('keyTerm', .))]" />
    <xsl:for-each select="$uniqueTerms">
      <xsl:sort lang="de"/>
      <xsl:value-of select="concat(.,'#',@deskriptor,'#',@id,$NL)" />
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
