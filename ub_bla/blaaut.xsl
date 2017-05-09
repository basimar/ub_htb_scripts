<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!--
  Eingabe: BLA Autorenwerke im Format "Katalogkarte ohne Signatur" (print-01)
  Ausgabe: Textdatei: Sysno - Tab - ISBD
  rev. 28.06.2007/ava
//-->

  <xsl:output method="text"/>
  <xsl:variable name="NL"  select="'&#x0A;'" />
  <xsl:variable name="TAB" select="'&#x09;'" />
  <xsl:variable name="BLA" select="'Signatur: BLA '"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//section-02"/>
  </xsl:template>

  <xsl:template match="section-02">
    <!-- Systemnummer -->
    <xsl:value-of select="substring-before(substring-after(par-001,'['),']')"/>
    <xsl:value-of select="$TAB" />
    <!-- ISBD -->
    <xsl:value-of select="par-556"/>
    <!-- GTA -->
    <xsl:if test="par-557 != ''">
        <xsl:value-of select="' '" />
        <xsl:value-of select="par-557"/>
    </xsl:if>
    <xsl:value-of select="$NL"/>
  </xsl:template>

</xsl:stylesheet>

