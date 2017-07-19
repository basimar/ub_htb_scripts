<?xml version="1.0" encoding="utf-8"?>
<!--

  extracts the information needed to produce a hierarchy structure out of
  a set of MARC records.


  usage: saxon bernoulli-marc.xml bernoulli-hierarchy.xsl |sort -u

  in:   Bernoulli-Daten ('wco=bernoulli'), MARC21 XML slim
  out:  unsorted tab separated text file. the fields contain
        - Briewechsel (830)
        - Korrespondenz (903)

  05.04.2006/andres.vonarx@unibas.ch

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="marc"
  >

  <xsl:output method="text" encoding="UTF-8" />
  <xsl:variable name="TAB" select="'&#09;'"/>
  <xsl:variable name="NL" select="'&#x0A;'"/>

  <xsl:template match="/">
    <xsl:for-each select="//marc:record">
        <xsl:value-of select="marc:datafield[@tag='830']/marc:subfield[@code='a']"/>
        <xsl:value-of select="$TAB"/>
        <xsl:value-of select="marc:datafield[@tag='903']/marc:subfield[@code='a']"/>
        <xsl:value-of select="$NL"/>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
