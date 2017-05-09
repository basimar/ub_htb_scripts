<?xml version="1.0" encoding="UTF-8"?>
<!--

  Zweck:    SWA Projekt Elekronische Zeitschriftenausschnitte
            generiert die Deskriptorenliste für das Newbase Portal für
            die hierarchische Anzeige der Deskriptoren
            (Abschnitt "Sachthemen").

  usage:    xsltproc swasd-e-zas-hierarchie.xsl tmp/swasd-hierarchie.xml \
                > doku/swa-e-zas-sachthemen-hierarchie.csv
  
  input:    swasd-hierarchie.xml (vollstaendige Information, hierarchisch)
  output:   Sachdossiers (inkl. Geographika), sortiert, undedubliert

  history:  
    24.01.2013 andres.vonarx@unibas.ch
    24.04.2014 rev/ava

//-->
<xsl:transform
    version="1.0"
    xmlns:MARC21="http://www.loc.gov/MARC21/slim"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >

    <xsl:output method="text" encoding="UTF-8" />
    <xsl:strip-space elements="*"/>

    <xsl:variable name="DEBUG"    select="false()" />
    <xsl:variable name="NL"       select="'&#xA;'" />
    <xsl:variable name="TAB"      select="'&#09;'" />
    <xsl:variable name="SEP"      select="'|'" />
    <xsl:variable name="TOPNODE"  select="'Sachthemen'" />

    <xsl:template match="//deskriptor">
        <xsl:choose>
            <xsl:when test="$DEBUG=false()">
                <xsl:variable name="thesaurus"      select="./../../../@name" />
                <xsl:variable name="subthesaurus"   select="./../../@name" />
                <xsl:variable name="teilthesaurus"  select="./../@name" />
                <xsl:for-each select="dossiers/dossier">
                    <xsl:value-of select="concat($TOPNODE, $SEP, $thesaurus, $SEP, $subthesaurus, $SEP, $teilthesaurus, $SEP)" />
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
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$NL" />
                <xsl:value-of select="concat(name(./../../..), ':',$TAB, ./../../../@name, $NL)" />
                <xsl:value-of select="concat(  name(./../..), ':',$TAB, ./../../@name, $NL)" />
                <xsl:value-of select="concat(  name(./..), ':', $TAB, ./../@name, $NL)" />
                <xsl:value-of select="concat(name(), ':',$TAB, @name, $NL)" />
                <xsl:for-each select="dossiers/dossier">
                    <xsl:value-of select="concat('* dossier: ',$TAB)" />
                    <xsl:choose>
                        <xsl:when test="@unterbegriff_ort != ''">
                            <xsl:value-of select="concat(@begriff, '. ', @unterbegriff_ort)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@begriff" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:value-of select="$NL" />
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:transform>
