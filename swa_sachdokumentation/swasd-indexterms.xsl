<?xml version='1.0' encoding="UTF-8"?>
<!--

  swasd-indexterms.xsl
  produziert eine XML Datei, die unsortiert alle zu indexierenden Begriffe enthaelt.

  <term> (für den alphabetischen Index):
  Ausgewertet werden Deskriptoren, Synonyma, Verwandte Begriffe und Oberbegriffe.
  Nicht ausgewertet werden Begriffe aus der Systematik (diese tauchen fast alle als
  Dossiertitel auf), Sachunterbegriffe (die's zur Zeit nicht mehr gibt) und
  Ortsunterbegriffe.

  <parent> (zusätzlich für den Wortindex):
  Für jedes Dossier werden zusätzlich die Begriffe aus den übergeordneten Stufen
  Subthesaurus und Teilthesaurus (ohne 'Allgemein') ausgewertet, und zwar von
  *allen* gleichlautenden Deskriptoren.

  <ort> (zusätzlich für den Wortindex):
  Geographische Unterschlagwörter

  Beispiel:
  für jeden der vier Deskriptoren "Gewässerschutz" werden die Begriffe aller
  vier übergeordneten Stufen ausgegeben. (In der Indexdatei wird dann nur *eine*
  verwendet).
    Volkswirtschaft > Umwelt- und Ressourcenökonomik > Umweltbelastung > Gewässerschutz
    Wirtschaftssektoren > Abfallwirtschaft und Recycling > Allgemein > Gewässerschutz
    Wirtschaftssektoren > Energie- und Wasserwirtschaft > Wasserwirtschaft > Gewässerschutz
    Nachbarwissenschaften > Naturwissenschaften und Technik > Geowissenschaften und Umwelt > Gewässerschutz

  History:
  20.08.2010  rewrite - andres.vonarx@unibas.ch
  08.09.2010  <ort> hinzugefuegt

-->
<xsl:transform
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">

  <xsl:output
    method="xml"
    indent="yes"
    encoding="UTF-8"
    />
  <xsl:strip-space elements="*"/>
  <xsl:variable name="SUBSEP" select="'°°°'"/>

  <xsl:template match="/">
    <swasd_index_terms>
      <xsl:apply-templates/>
    </swasd_index_terms>
  </xsl:template>


  <xsl:template match="deskriptor">
    <xsl:variable name="kontext" select="@name"/>
    <xsl:variable name="target" select="@id"/>

    <xsl:element name="term">
      <xsl:attribute name="deskriptor"><xsl:value-of select="@name"/></xsl:attribute>
      <xsl:attribute name="id"><xsl:value-of select="$target"/></xsl:attribute>
      <xsl:value-of select="@name"/>
    </xsl:element>

    <xsl:for-each select="synonyme/synonym|verwandte_begriffe/vb_oberbegriff">
      <xsl:element name="term">
        <xsl:attribute name="deskriptor"><xsl:value-of select="$kontext"/></xsl:attribute>
        <xsl:attribute name="id"><xsl:value-of select="$target"/></xsl:attribute>
        <xsl:value-of select="@name"/>
      </xsl:element>
    </xsl:for-each>

    <xsl:for-each select="dossiers/dossier/@unterbegriff_ort[. != '']">
        <xsl:element name="ort">
            <xsl:attribute name="did"><xsl:value-of select="$target"/></xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:for-each>

    <xsl:element name="parent">
      <xsl:attribute name="did"><xsl:value-of select="$target"/></xsl:attribute>
      <xsl:for-each select="//deskriptor[@name=$kontext]">
        <xsl:value-of select="concat(ancestor::subthesaurus/@name,$SUBSEP)"/>
        <xsl:if test="ancestor::teilthesaurus/@name != 'Allgemein'">
            <xsl:value-of select="concat(ancestor::teilthesaurus/@name,$SUBSEP)"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>

  <xsl:template match="//subthesaurus|//thesaurus|//teilthesaurus">
    <xsl:variable name="current_name" select="@name"/>
    <xsl:if test="(@name != 'Allgemein') and ( not(//deskriptor[@name=$current_name]))">
        <xsl:element name="term">
            <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
            <xsl:value-of select="@name"/>
        </xsl:element>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

</xsl:transform>
