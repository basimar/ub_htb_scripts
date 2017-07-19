<?xml version="1.0" encoding="utf-8"?>
<!--

  tigra_tree_menu_bernoulli.xsl

  input:  korrespondenz.xml   structured hierarchy xml of records
  output: tree_items.js       Tigra Tree Menu JS code

  rev. 24.01.2008/andres.vonarx@unibas.ch

-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

  <xsl:output method="text" encoding="UTF-8" />
  <xsl:variable name="NL" select="'&#x0A;'"/>
  <xsl:variable name="TAB" select="'&#09;'"/>
  <xsl:variable name="BAD_QUOTES">&apos;&quot;</xsl:variable>
  <xsl:variable name="SAFE_QUOTES">&#x2019;&#x201D;</xsl:variable>


  <!-- fix some characters bound to cause trouble in JavaScript -->

  <xsl:template match="/">
    <xsl:value-of select="concat('// data generated: ', bernoulli_tree/@generated,$NL)"/>
    <xsl:text>var TREE_ITEMS = [</xsl:text>
    <xsl:value-of select="$NL"/>
    <xsl:text>  ['Bernoulli Briefwechsel','',</xsl:text>
    <xsl:value-of select="$NL"/>

    <xsl:for-each select="//briefwechsel">
        <!-- $SRS = name des briefwechsels ohne interpunktion -->
        <xsl:variable name="SRS">
            <xsl:call-template name="suchform">
                <xsl:with-param name="wer" select="@von"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:text>    ['</xsl:text>
        <xsl:value-of select="@von"/>
        <xsl:text>','javascript:bib(\'SRS=%22</xsl:text>
        <xsl:value-of select="$SRS"/>
        <xsl:text>%22\');',</xsl:text>
        <xsl:value-of select="$NL"/>

        <xsl:for-each select="korr">
            <xsl:text>      ['</xsl:text>
            <xsl:value-of select="translate(.,$BAD_QUOTES,$SAFE_QUOTES)"/>
            <xsl:text>','javascript:bib(\'(SRS=%22</xsl:text>
            <xsl:value-of select="$SRS"/>
            <xsl:text>%22)%20and%20(KOR=</xsl:text>
            <xsl:value-of select="@ascii7"/>
            <xsl:text>)\');'],</xsl:text>
            <xsl:value-of select="$NL"/>
        </xsl:for-each>

        <xsl:value-of select="concat('    ],',$NL)"/>
    </xsl:for-each>

    <xsl:value-of select="concat('  ]',$NL,'];',$NL)"/>
  </xsl:template>

  <xsl:template name="suchform">
    <xsl:param name="wer"/>
    <xsl:value-of select="translate($wer,',','')"/>
  </xsl:template>

</xsl:stylesheet>
