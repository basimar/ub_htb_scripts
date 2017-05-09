<?xml version="1.0" encoding="UTF-8"?>
<!--

  file:     swasd-descriptors-doku.xsl

  input:    swasd-hierarchie.xml   (vollstaendige Information, hierarchisch)
  output:   swasd-deskriptoren.xml (pure Hierarchie, zur Dokumentation)

  13.08.2010/andres.vonarx@unibas.ch

//-->

<xsl:transform
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

  <xsl:output method="xml" encoding="UTF-8" />
  <xsl:strip-space elements="*"/>

  <xsl:template match="/">
    <swa-sachdokumentation-thesaurus stand="27.02.2012 / andres.vonarx@unibas.ch">
      <xsl:for-each select="//thesaurus">
        <deskriptor stufe="1">
          <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
          <xsl:apply-templates select="subthesaurus" />
        </deskriptor>
      </xsl:for-each>
    </swa-sachdokumentation-thesaurus>
  </xsl:template>

  <xsl:template match="subthesaurus">
    <deskriptor stufe="2">
      <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:apply-templates />
    </deskriptor>
  </xsl:template>

  <xsl:template match="teilthesaurus">
    <deskriptor stufe="3">
      <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:apply-templates />
    </deskriptor>
  </xsl:template>

  <xsl:template match="deskriptor">
    <deskriptor stufe="4">
      <xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
    </deskriptor>
  </xsl:template>

</xsl:transform>
