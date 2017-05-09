<?xml version='1.0' encoding="UTF-8"?>
<!--

  swasd-suchmaschine.xsl

  extrahiert zu jedem Deskriptor die zugehörigen Begriffe.
  Vorstufe zu einer Texdatei, die von ava::search::cgi
  verwendet wird. Die Begriffe enthalten noch Dubletten.

  History
  20.08.2010  rewrite / andres.vonarx@unibas.ch

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output
    method="text"
    encoding="UTF-8"
    />
  <xsl:strip-space elements="*"/>
  <xsl:variable name="NL" select="'&#x0A;'"/>
  <xsl:variable name="SEP" select="'&#x7C;'"/>
  <xsl:variable name="SUBSEP" select="'°°°'"/>

  <xsl:key name="keyTerm" match="//term" use="@deskriptor"/>
  <xsl:template match="/">
    <xsl:variable name="uniqueTerms"
      select="//term[generate-id(.)=generate-id(key('keyTerm', @deskriptor))]" />
    <xsl:for-each select="$uniqueTerms">

      <xsl:sort select="@deskriptor" lang="de"/>

      <!-- feld 1: link -->
      <xsl:value-of select="@id"/>
      <xsl:value-of select="$SEP"/>

      <!-- feld 2: Fundstelle -->
      <xsl:value-of select="@deskriptor"/>
      <xsl:value-of select="$SEP"/>

      <!-- feld 3: description (leer) -->
      <xsl:value-of select="$SEP"/>

      <!-- feld 4: suchbegriffe -->
      <xsl:call-template name="print_word">
        <xsl:with-param name="word" select="@deskriptor"/>
      </xsl:call-template>

      <xsl:for-each select="key('keyTerm', @deskriptor)">
        <xsl:call-template name="print_word">
          <xsl:with-param name="word" select="."/>
        </xsl:call-template>
      </xsl:for-each>

      <xsl:variable name="child_did" select="@id"/>
      <xsl:call-template name="print_word">
        <xsl:with-param name="word" select="//parent[@did=$child_did]"/>
      </xsl:call-template>

      <xsl:for-each select="//ort[@did=$child_did]">
        <xsl:call-template name="print_word">
            <xsl:with-param name="word" select="."/>
        </xsl:call-template>
      </xsl:for-each>

      <xsl:value-of select="$NL"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="print_word">
    <xsl:param name="word" />
    <xsl:value-of select="translate(concat($word,$SUBSEP),'ÄÖÜ','äöü')"/>
  </xsl:template>

</xsl:stylesheet>
