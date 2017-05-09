<?xml version='1.0' encoding="UTF-8"?>
<xsl:transform
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:MARC21="http://www.loc.gov/MARC21/slim"
  version="2.0">
<!--

  swapa-suchmaschine.xsl

  in:  MARC XML
  out: Textdatei, Trenner '|', mit den Feldern:
        1:  Link (Aleph Systemnummer)
        2:  Anzeigetitel (245)
        3:  [leer]
        4:  Suchbegriffe (enhält Dubletten und falsche Zeichen, muss noch bereinigt werden)

  History
  30.08.2010 andres.vonarx@unibas.ch

-->
  <xsl:output
    method="text"
    encoding="UTF-8"
    />
  <xsl:strip-space elements="*"/>
  <xsl:variable name="NL" select="'&#x0a;'"/>
  <xsl:variable name="SEP" select="'|'"/>

  <xsl:template match="/">
    <xsl:for-each select="//MARC21:record">
        <xsl:sort lang="de" select="MARC21:datafield[@tag='245']/MARC21:subfield[@code='a']"/>

        <xsl:value-of select="MARC21:controlfield[@tag='001']"/>
        <xsl:value-of select="$SEP"/>

        <xsl:value-of select="MARC21:datafield[@tag='245']/MARC21:subfield[@code='a']"/>
        <xsl:value-of select="$SEP"/>

        <xsl:value-of select="$SEP"/>

        <xsl:for-each select="MARC21:datafield[@tag=('245','500','520','544')]/MARC21:subfield[@code='a']">
            <xsl:value-of select="concat(translate(.,'ÄÖÜ','äöü'),' ')"/>
        </xsl:for-each>
        <xsl:for-each select="MARC21:datafield[@tag='690' and @ind1='w']">
            <xsl:value-of select="concat('W',@ind2,'_',translate(MARC21:subfield,'ÄÖÜ','äöü'),' ')"/>
        </xsl:for-each>
        <xsl:for-each select="MARC21:datafield[@tag='909']/MARC21:subfield[@code='f']/text()[. = ('swapafirma','swapaverband','swapapnl')]">
            <xsl:value-of select="concat(.,' ')"/>
        </xsl:for-each>
        <xsl:value-of select="$NL"/>

    </xsl:for-each>
  </xsl:template>

</xsl:transform>
