<?xml version="1.0" encoding="utf-8"?>
<!--

  tigra_tree_menu_split.xsl

    - Input: Hierarchie-XML Datei, angereichert mit bibliographischen Daten
    - bearbeitet nur Records mit verknüpften untergeordneten Records
    - schreibt für jeden dieser Records ein JavaScript Code-Schnipsel für ein Tigra Tree Menu.
    - die entstehende Textdatei muss anschliessend gesplittet werden.

  see also: http://www.softcomplex.com/products/tigra_menu_tree/

  history:
    rev. 03.08.2010 andres.vonarx@unibas.ch

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="marc"
  >
  <xsl:output method="text" encoding="UTF-8" />

  <xsl:variable name="NL" select="'&#x0A;'"/>
  <xsl:variable name="TAB" select="'&#09;'"/>
  <xsl:variable name="BAD_QUOTES">&apos;&quot;</xsl:variable>
  <xsl:variable name="SAFE_QUOTES">&#x2019;&#x201D;</xsl:variable>

  <xsl:template match="/tree">
    <xsl:variable name="GENERATED" select="@generated"/>
    <xsl:for-each select="rec[@level=1]">
        <xsl:if test="./rec[@level=2]">
            <xsl:value-of select="concat(
                '===', @recno, '===', $NL,
                '// ', @recno, ' - ', data/nachlass, $NL,
                '// data generated: ', $GENERATED,$NL,
                'var TREE_ITEMS = [',$NL,
                $TAB, '['
                )"/>
            <xsl:text>'</xsl:text>
            <xsl:value-of select="translate(data/titel,$BAD_QUOTES,$SAFE_QUOTES)"/>
            <!--
            <xsl:call-template name="subfield">
                <xsl:with-param name="recno" select="@recno"/>
                <xsl:with-param name="field" select="'245'"/>
                <xsl:with-param name="subfield" select="'a'"/>
            </xsl:call-template>
            -->
            <xsl:text>','javascript:bib(\'</xsl:text>
            <xsl:value-of select="@recno"/>
            <xsl:text>\');',</xsl:text>
            <xsl:value-of select="$NL"/>
            <xsl:call-template name="printlevel">
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
            <xsl:value-of select="concat(
                $TAB,']',$NL,
                '];',$NL
            )"/>
        </xsl:if>
    </xsl:for-each>
  </xsl:template>


  <!-- recursively print the hierarchical levels -->
  <xsl:template name="printlevel">
    <xsl:param name="node"/>
      <xsl:for-each select ="rec">
        <!-- opening bracket -->
        <xsl:call-template name="indent">
            <xsl:with-param name="level" select="@level"/>
        </xsl:call-template>
        <xsl:value-of select="'['"/>
        <!-- print current record (closes brackets, if without children) -->
        <xsl:call-template name="printrec">
            <xsl:with-param name="recno" select="@recno"/>
            <xsl:with-param name="level" select="@level"/>
        </xsl:call-template>
        <xsl:value-of select="$NL"/>
        <!-- recurse into deeper levels -->
        <xsl:call-template name="printlevel">
            <xsl:with-param name="node" select="."/>
        </xsl:call-template>
        <!-- close bracket, if node had children -->
        <xsl:if test="rec">
            <xsl:call-template name="indent">
                <xsl:with-param name="level" select="@level"/>
            </xsl:call-template>
            <xsl:value-of select="']'"/>
            <xsl:if test="position()!=last()">
                <xsl:value-of select="','"/>
            </xsl:if>
            <xsl:value-of select="$NL"/>
        </xsl:if>
    </xsl:for-each>
  </xsl:template>


  <!-- print appropriate indentation for each level -->
  <xsl:template name="indent">
    <xsl:param name="level"/>
    <xsl:if test=" number($level) > 0 ">
        <xsl:value-of select="$TAB"/>
        <xsl:call-template name="indent">
            <xsl:with-param name="level" select="number($level)-1"/>
        </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- print a Tigra tree menu item: quoted text and link -->
  <xsl:template name="printrec">
    <xsl:param name="level"/>
    <xsl:param name="recno"/>
    <xsl:text>'</xsl:text>
    <xsl:if test="$level!=1">
        <xsl:value-of select="concat(translate(data/zaehlung,$BAD_QUOTES,$SAFE_QUOTES),' : ')"/>
    </xsl:if>
    <xsl:if test="data/autor">
        <xsl:value-of select="concat(translate(data/autor,$BAD_QUOTES,$SAFE_QUOTES), ': ')"/>
    </xsl:if>
    <xsl:value-of select="translate(data/titel,$BAD_QUOTES,$SAFE_QUOTES)"/>
    <xsl:text>','javascript:bib(\'</xsl:text>
    <xsl:value-of select="$recno"/>
    <xsl:text>\');'</xsl:text>
    <xsl:choose>
        <xsl:when test="rec">
            <xsl:value-of select="','"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="'],'"/>
        </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


</xsl:stylesheet>
