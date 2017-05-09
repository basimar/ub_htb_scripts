<xsl:transform
    version="1.0"
    xmlns:MARC21="http://www.loc.gov/MARC21/slim"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    >
<!--

    Input:   swapa-swapa_schlagwoerter.xml
             swapa-marc.xml
    Ouptput: Hierarchie-Textdatei

    30.08.2010 / andres.vonarx@unibas.ch

-->
  <xsl:output method="text" encoding="UTF-8" />
  <xsl:variable name="MARC" select="'tmp/swapa-marc.xml'"/>
  <xsl:variable name="SEPARATOR"  select="' > '"/>
  <xsl:variable name="NO_ITEMS_MARKER" select="' > 000'"/>
  <xsl:variable name="NL" select="'&#xA;'"/>

  <xsl:template match="/">
    <xsl:value-of select="concat('Firmen- und Verbandsarchive',$NL)"/>
    <xsl:for-each select="//top">
        <xsl:choose>
            <xsl:when test="sub">
                <xsl:value-of select="concat(' ',@name,$NL)"/>
                <xsl:for-each select="sub">
                    <xsl:call-template name="lookup">
                        <xsl:with-param name="name" select="@name"/>
                        <xsl:with-param name="f690" select="@deskriptor"/>
                        <xsl:with-param name="indent" select="'  '"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="lookup">
                    <xsl:with-param name="name" select="@name"/>
                    <xsl:with-param name="f690" select="@deskriptor"/>
                    <xsl:with-param name="indent" select="' '"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>

    <xsl:value-of select="concat('Personennachlässe',$NL)"/>
    <xsl:for-each select="document($MARC)//MARC21:record/MARC21:datafield[@tag='909']/MARC21:subfield/text()[. = 'swapapnl']">
        <xsl:sort lang="de" select="ancestor::MARC21:record/MARC21:datafield[@tag='245']/MARC21:subfield[@code='a']"/>
        <xsl:value-of select="' '"/>
        <xsl:value-of select="ancestor::MARC21:record/MARC21:datafield[@tag='245']/MARC21:subfield[@code='a']"/>
        <xsl:value-of select="$SEPARATOR"/>
        <xsl:value-of select="ancestor::MARC21:record/MARC21:controlfield[@tag='001']"/>
        <xsl:value-of select="$NL"/>
    </xsl:for-each>
  </xsl:template>


  <xsl:template name="lookup">
    <xsl:param name="name"/>
    <xsl:param name="f690"/>
    <xsl:param name="indent"/>
    <xsl:choose>
        <xsl:when test="document($MARC)//MARC21:record/MARC21:datafield[@tag='690' and @ind1='w' and @ind2='2']/MARC21:subfield[@code='a']/text()[. = $f690]">
            <!-- es hat Aufnahmen mit diesem Deskriptor -->
            <xsl:value-of select="concat($indent, $name, $NL)"/>
            <xsl:for-each select="document($MARC)//MARC21:record/MARC21:datafield[@tag='690' and @ind1='w' and @ind2='2']/MARC21:subfield[@code='a']/text()[. = $f690]">
                <xsl:sort lang="de" select="ancestor::MARC21:record/MARC21:datafield[@tag='245']/MARC21:subfield[@code='a']"/>
                <xsl:if test="ancestor::MARC21:record/MARC21:datafield[@tag='909']/MARC21:subfield/text()[. = 'swapafirma' or . = 'swapaverband']">
                    <xsl:value-of select="concat($indent,' ')"/>
                    <xsl:value-of select="ancestor::MARC21:record/MARC21:datafield[@tag='245']/MARC21:subfield[@code='a']"/>
                    <xsl:value-of select="$SEPARATOR"/>
                    <xsl:value-of select="ancestor::MARC21:record/MARC21:controlfield[@tag='001']"/>
                    <xsl:value-of select="$NL"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <!-- es hat *keine* Aufnahmen mit diesem Deskriptor -->
            <xsl:value-of select="concat($indent, $name, $NO_ITEMS_MARKER, $NL)"/>
        </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:transform>
