<?xml version="1.0" encoding="utf-8"?>
<!--

    zeitungskatalog.xsl

    extrahiert folgende Info aus MARC21-Records mit "wlc=ztgbs":

    1: Systemnummer (001)
    2: Titel (730 $a $p oder 245 $a), mit Materialbezeichnung (245 $h) und Titelzusatz/Zählung (245 $p)
    3: Code (909A_ [$d ztgbs] $x ... )
    4: Externer Link (856 $u)

    10.05.2011/andres.vonarx@unibas.ch

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

  <xsl:output method="text" encoding="UTF-8" />
  <xsl:variable name="TAB" select="'&#09;'"/>
  <xsl:variable name="NL" select="'&#x0A;'"/>

  <xsl:template match="/">
    <xsl:value-of select="concat('Systemnummer',$TAB,'Titel',$TAB,'Code',$TAB,'Externer_Link',$NL)"/>
    <xsl:for-each select="//marc:record">

        <!-- Systemnummer -->
        <xsl:value-of select="marc:controlfield[@tag='001']"/>
        <xsl:value-of select="$TAB"/>

        <!-- Titel -->
        <xsl:choose>
            <xsl:when test="marc:datafield[@tag='730']/marc:subfield[@code='a']">
                <xsl:value-of select="marc:datafield[@tag='730']/marc:subfield[@code='a']"/>
                <xsl:if test="marc:datafield[@tag='730']/marc:subfield[@code='p']">
                    <xsl:value-of select="concat('. ', marc:datafield[@tag='730']/marc:subfield[@code='p'])"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="marc:datafield[@tag='245']/marc:subfield[@code='a']"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="marc:datafield[@tag='245']/marc:subfield[@code='h']">
            <xsl:value-of select="concat(' [', marc:datafield[@tag='245']/marc:subfield[@code='h'], ']')"/>
        </xsl:if>
        <xsl:if test="marc:datafield[@tag='245']/marc:subfield[@code='p']">
            <xsl:choose>
                <xsl:when test="starts-with(marc:datafield[@tag='245']/marc:subfield[@code='p'], '[')">
                    <xsl:value-of select="concat(' ', marc:datafield[@tag='245']/marc:subfield[@code='p'])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(' [', marc:datafield[@tag='245']/marc:subfield[@code='p'], ']')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:value-of select="$TAB"/>

        <!-- Code -->
        <xsl:value-of select="marc:datafield[@tag='909']/marc:subfield[@code='d'][text()='ztgbs']/parent::marc:datafield/marc:subfield[@code='x']"/>
        <xsl:value-of select="$TAB"/>

        <!-- Externer Link -->
        <xsl:value-of select="marc:datafield[@tag='856']/marc:subfield[@code='u']"/>
        <xsl:value-of select="$NL"/>
    </xsl:for-each>
  </xsl:template>


</xsl:stylesheet>
