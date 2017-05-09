<?xml version="1.0" encoding="UTF-8"?>
<!--

  Zweck:    SWA Projekt Elekronische Zeitschriftenausschnitte
            generiert die "flache" Deskriptorenliste für das Newbase
            Modul "Systemadminstrator" für die Vergabe von Deskriptoren
            (Abschnitt "Sachthemen".)

  usage:    xsltproc swasd-e-zas-flach.xsl tmp/swasd-hierarchie.xml \
                | uniq > doku/swa-e-zas-sachthemen-flach.txt
  
  input:    swasd-hierarchie.xml (vollstaendige Information, hierarchisch)
  output:   Sachdossiers (inkl. Geographika), unsortiert, undedubliert
  
  history:      
    24.01.2013/andres.vonarx@unibas.ch

-->
<xsl:transform
    version="1.0"
    xmlns:MARC21="http://www.loc.gov/MARC21/slim"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >
    <xsl:output method="text" encoding="UTF-8" />
    <xsl:strip-space elements="*" />
    <xsl:variable name="NL"       select="'&#xA;'"/>
    <xsl:template match="/">
        <xsl:for-each select="//dossier">
            <xsl:choose>
                <xsl:when test="@unterbegriff_ort != ''">
                    <xsl:value-of select="concat(@begriff, '. ', @unterbegriff_ort)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@begriff"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$NL" />
        </xsl:for-each>
    </xsl:template>
</xsl:transform>
