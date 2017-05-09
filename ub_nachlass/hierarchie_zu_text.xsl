<?xml version="1.0" encoding="utf-8"?>
<!--

  Input:
    hierarchie.xml

  Output:
    tab separated values mit den Feldern Titel/Recno/'+' (= "hat Hierarchie")

    27.03.2008  andres.vonarx@unibas.ch

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="marc"
  >

  <xsl:output method="text" encoding="UTF-8" />

  <xsl:variable name="NL" select="'&#x0A;'"/>
  <xsl:variable name="TAB" select="'&#09;'"/>

  <xsl:template match="/tree">
    <xsl:for-each select ="//rec[@level=1]">

      <!-- Feld 1: Name -->
      <xsl:value-of select="data/nachlass"/>
      <xsl:value-of select="$TAB"/>

      <!-- Feld 2: RecNo -->
      <xsl:value-of select="@recno"/>
      <xsl:value-of select="$TAB"/>

      <!-- Feld 3: '+' bedeutet: hat Unterfelder -->
      <xsl:choose>
        <xsl:when test="./rec[@level=2]">
          <xsl:value-of select="'+'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="' '"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="$NL"/>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
