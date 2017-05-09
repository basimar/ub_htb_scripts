<?xml version="1.0" encoding="UTF-8"?>

<!--

  file:     aut-extract.xsl
  version:  01.06.2010
  author:   andres.vonarx@unibas.ch

  input:    MARC21 Slim XML (AUT)

  output:   CSV Text mit den Feldern

  - thesaurus     = 690FD $a
  - subthesaurus  = 690FD $b [1]
  - teilthesaurus = 690FD $b [2]
  - deskriptor    = 190FC $a
  - bibsysno      = SYS
  - synonyme      = 490FC $abg
                    [* wiederholbar, einzelne Begriffe getrennt durch '$']
  - verwandter_begriff/oberbegriff = 590FC $a, $w='g'
                    [* wiederholbar, einzelne Begriffe getrennt durch '$']
  - verwandter_begriff/siehe_auch  = 590FC $a, $w=''
                    [* wiederholbar, einzelne Begriffe getrennt durch '$']

//-->

<xsl:transform
    version="1.0"
    xmlns:MARC21="http://www.loc.gov/MARC21/slim"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

  <xsl:output method="text" encoding="UTF-8" />

  <xsl:variable name="FSEP" select="'#'"/>
  <xsl:variable name="DOLLAR" select="'$'"/>
  <xsl:variable name="NL" select="'&#xA;'"/>

  <xsl:template match="/">
    <!-- relevant sind nur AUT records mit einem Sachdeskriptor 190FC -->
    <xsl:for-each select="//MARC21:datafield[@tag='190'][@ind1='f'][@ind2='c']">
      <xsl:call-template name="make_record"/>
    </xsl:for-each>
  </xsl:template>


  <xsl:template name="make_record">
    <xsl:for-each select="../MARC21:datafield[@tag='690'][@ind1='f'][@ind2='d']">

        <!-- thesaurus -->
        <xsl:value-of select="MARC21:subfield[@code='a']"/>
        <xsl:value-of select="'#'"/>

        <!-- subthesaurus -->
        <xsl:value-of select="MARC21:subfield[@code='b'][1]"/>
        <xsl:value-of select="'#'"/>

        <!-- teilhesaurus -->
        <xsl:value-of select="MARC21:subfield[@code='b'][2]"/>
        <xsl:value-of select="'#'"/>

        <!-- deskriptor -->
        <xsl:value-of select="../MARC21:datafield[@tag='190'][@ind1='f'][@ind2='c']/MARC21:subfield[@code='a']"/>
        <xsl:value-of select="'#'"/>

        <xsl:value-of select="../MARC21:controlfield[@tag='001']"/>
        <xsl:value-of select="'#'"/>

        <xsl:for-each select="../MARC21:datafield[@tag='490'][@ind1='f'][@ind2='c']">
            <xsl:value-of select="MARC21:subfield[@code='a']"/>
            <xsl:value-of select="$DOLLAR"/>
        </xsl:for-each>
        <xsl:value-of select="'#'"/>

        <xsl:for-each select="../MARC21:datafield[@tag='590'][@ind1='f'][@ind2='c']">
            <xsl:if test="MARC21:subfield[@code='w']='g'">
                <xsl:value-of select="MARC21:subfield[@code='a']"/>
                <xsl:value-of select="$DOLLAR"/>
            </xsl:if>
        </xsl:for-each>
        <xsl:value-of select="'#'"/>

        <xsl:for-each select="../MARC21:datafield[@tag='590'][@ind1='f'][@ind2='c']">
            <xsl:if test="MARC21:subfield[@code='w']=''">
                <xsl:value-of select="MARC21:subfield[@code='a']"/>
                <xsl:value-of select="$DOLLAR"/>
            </xsl:if>
        </xsl:for-each>
      <xsl:value-of select="$NL"/>
    </xsl:for-each>
  </xsl:template>

</xsl:transform>
