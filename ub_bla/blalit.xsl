<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!--
  Eingabe: BLA Sekundaerliteratur im Format "Katalogkarte mit Signatur" (print-01)
  Ausgabe: Textdatei: ISBD (## als NewLine) - Tab - Sysno - Tab - Signaturen (roh)
  29.11.2005/ava
//-->

  <xsl:output method="text" />
  <xsl:strip-space elements="*"/>
  <xsl:variable name="NL" select="'&#x0A;'"/>
  <xsl:variable name="TAB" select="'&#x09;'"/>


  <xsl:template match="/">
    <xsl:apply-templates select="//section-02" />
  </xsl:template>


  <xsl:template match="section-02">
      <!-- autor -->
      <xsl:if test="par-555 != ''">
      	<xsl:value-of select="concat(par-555,': ')" />
      </xsl:if>
      <!-- titel -->
      <xsl:value-of select="par-556"/>
      <!-- GTA -->
      <xsl:if test="par-557 != ''">
      	<xsl:value-of select="concat('##',par-557)" />
      </xsl:if>
      <!-- Fussnote -->
      <xsl:if test="par-558 != ''">
      	<xsl:value-of select="concat('##',par-558)" />
      </xsl:if>

      <!-- sysno -->
      <xsl:value-of select="$TAB"/>
      <xsl:value-of select="translate(par-001,'[]','')"/>

      <!-- signaturen -->
      <xsl:value-of select="$TAB"/>
      <xsl:value-of select="par-853"/>

      <xsl:value-of select="$NL"/>
  </xsl:template>

</xsl:stylesheet>
