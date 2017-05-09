<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!--
  Eingabe: print-01, Format "Feldnummern"
  Ausgabe: standardisierte Aleph-Datei (Feldnummer, TAB, Feldinhalt)

  Anmerkungen in 'par-004' werden ignoriert, ebenso das stets leere par-85e

  29.11.2005/ava
//-->

  <xsl:output method="text"/>
  <xsl:variable name="NL" select="'&#x0A;'" />
  <xsl:variable name="TAB" select="'&#x09;'" />

  <xsl:template match="/">
    <xsl:apply-templates select="//section-02"/>
  </xsl:template>

  <xsl:template match="section-02">
    <xsl:choose>
        <xsl:when test="col1='----------'">
            <xsl:value-of select="$NL"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="col1"/>
            <xsl:value-of select="$TAB" />
            <xsl:value-of select="col2"/>
            <xsl:value-of select="$NL"/>
        </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

