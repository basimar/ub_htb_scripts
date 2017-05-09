<?xml version="1.0" encoding="UTF-8"?>
<!--

  file:     swasd-descriptors.xsl

  input:    swasd-hierarchie.xml   (vollstaendige Information, hierarchisch)
  output:   swasd-descriptors.txt  (Hierarchie und IDs, bis Stufe Deskriptor)

  13.08.2010/andres.vonarx@unibas.ch

//-->

<xsl:transform
    version="1.0"
    xmlns:MARC21="http://www.loc.gov/MARC21/slim"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

  <xsl:output method="text" encoding="UTF-8" />
  <xsl:variable name="NL" select="'&#xA;'"/>
  <xsl:variable name="SEP" select="' &gt; '"/>
  <xsl:variable name="SUBSEP" select="'°°°'"/>
  <xsl:strip-space elements="*"/>

  <xsl:template match="/">
    <xsl:for-each select="//thesaurus">
      <xsl:value-of select="concat(@name,$SEP,@id,$SUBSEP,@treeitem,$NL)"/>
      <xsl:apply-templates select="subthesaurus" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="subthesaurus">
    <xsl:value-of select="concat(' ',@name,$SEP,@id,$SUBSEP,@treeitem,$NL)"/>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="teilthesaurus">
    <xsl:value-of select="concat('  ',@name,$SEP,@id,$SUBSEP,@treeitem,$NL)"/>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="deskriptor">
    <xsl:value-of select="concat('   ',@name,$SEP,@id,$SUBSEP,@treeitem,$NL)"/>
  </xsl:template>

</xsl:transform>
