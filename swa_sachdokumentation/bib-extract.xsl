<?xml version="1.0" encoding="UTF-8"?>

<!--

  file:     bib-extract.xsl
  author:   andres.vonarx@unibas.ch

  input:    MARC21 Slim XML  (BIB)

  output:   CSV Text mit den Feldern

  - DESK        = 690FC $a
  - USW SACHE   = 690FC $x
  - USW ORT     = 690FC $z [+ 690 FC $v]
  - Aleph Sysno = SYS
  - URL zu Dossierdef/Sammlungskonzept  = 856 $u (falls $z == 'Sammlungskonzept')

  history:
    16.02.2005  andres.vonarx@unibas.ch
    25.11.2010  behandle USW Format ($v) gleich wie USW Ort ($z)

//-->

<xsl:transform
    version="1.0"
    xmlns:MARC21="http://www.loc.gov/MARC21/slim"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

  <xsl:output method="text" encoding="UTF-8" />
  <xsl:variable name="NL" select="'&#xA;'"/>

  <xsl:template match="/">
    <xsl:for-each select="//MARC21:datafield[@tag='690'][@ind1='f'][@ind2='c']" xmlns="http://www.loc.gov/MARC21/slim">
      <xsl:call-template name="make_record"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="make_record">
    <xsl:value-of select="MARC21:subfield[@code='a']"/>
    <xsl:value-of select="'#'"/>
    <xsl:value-of select="MARC21:subfield[@code='x']"/>
    <xsl:value-of select="'#'"/>
    <xsl:value-of select="MARC21:subfield[@code='z']"/>
    <xsl:if test="MARC21:subfield[@code='v']">
        <xsl:if test="MARC21:subfield[@code='z']">
            <xsl:value-of select="'. '"/>
        </xsl:if>
        <xsl:value-of select="MARC21:subfield[@code='v']"/>
    </xsl:if>
    <xsl:value-of select="'#'"/>
    <xsl:value-of select="../MARC21:controlfield[@tag='001']" />
    <xsl:value-of select="'#'"/>
    <xsl:if test="../MARC21:datafield[@tag='856']/MARC21:subfield[@code='z'] = 'Sammlungskonzept'">
      <xsl:value-of select="../MARC21:datafield[@tag='856']/MARC21:subfield[@code='u']"/>
    </xsl:if>
    <xsl:value-of select="$NL"/>
  </xsl:template>

</xsl:transform>
