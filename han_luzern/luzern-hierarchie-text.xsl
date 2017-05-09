<?xml version='1.0' encoding="UTF-8"?>
<xsl:transform
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:MARC21="http://www.loc.gov/MARC21/slim"
  version="2.0">
<!--

  luzern-hierarchie-text.xsl

  in:  tmp/hierarchie.xml
       tmp/info.xml

  out: Textdatei, hierarchisch gegliedert

  History
  06.09.2010 andres.vonarx@unibas.ch

-->
  <xsl:output
    method="text"
    encoding="UTF-8"
    />
  <xsl:strip-space elements="*"/>
  <xsl:variable name="MARCFILE" select="'tmp/luzern-marc.xml'"/>
  <xsl:variable name="INFOFILE" select="'tmp/info.xml'"/>
  <xsl:variable name="NL" select="'&#x0a;'"/>
  <xsl:variable name="SEP" select="' &gt; '"/>

  <xsl:template match="/">
    <xsl:value-of select="concat(document($INFOFILE)/info/rootnode/@text,$SEP,
        document($INFOFILE)/info/rootnode/@href,$NL)"/>
    <xsl:for-each select="//rec">
        <xsl:call-template name="indent">
            <xsl:with-param name="level" select="@level"/>
        </xsl:call-template>
        <xsl:value-of select="@level"/>
        <xsl:value-of select="$NL"/>
    </xsl:for-each>
  </xsl:template>


  <xsl:template name="indent">
    <xsl:param name="level"/>
    <xsl:value-of select="' '"/>
    <xsl:if test="$level &gt; 1">
        <xsl:variable name="nextlevel" select="$level - 1"/>
        <xsl:call-template name="indent">
            <xsl:with-param name="level" select="$nextlevel"/>
        </xsl:call-template>
    </xsl:if>
  </xsl:template>


  <xsl:template match="soeinscheiss">
    <xsl:for-each select="//MARC21:datafield[@tag='351']/MARC21:subfield[@code='c']/text()[. = 'Bestand=Fonds']">

        <xsl:sort lang="de" select="concat(ancestor::MARC21:record/MARC21:datafield[@tag='901'
            and @ind1='p'][1],ancestor::MARC21:record/MARC21:datafield[@tag='902' and @ind1='p'][1])"/>

        <xsl:for-each select="ancestor::MARC21:record">

            <xsl:variable name="sysno" select="MARC21:controlfield[@tag='001']"/>
            <xsl:variable name="sysno_without_zeroes">
                <xsl:choose>
                    <xsl:when test="starts-with($sysno,'0000000')">
                        <xsl:value-of select="substring($sysno,8)"/>
                    </xsl:when>
                    <xsl:when test="starts-with($sysno,'000000')">
                        <xsl:value-of select="substring($sysno,7)"/>
                    </xsl:when>
                    <xsl:when test="starts-with($sysno,'00000')">
                        <xsl:value-of select="substring($sysno,6)"/>
                    </xsl:when>
                    <xsl:when test="starts-with($sysno,'0000')">
                        <xsl:value-of select="substring($sysno,5)"/>
                    </xsl:when>
                    <xsl:when test="starts-with($sysno,'000')">
                        <xsl:value-of select="substring($sysno,4)"/>
                    </xsl:when>
                    <xsl:when test="starts-with($sysno,'00')">
                        <xsl:value-of select="substring($sysno,3)"/>
                    </xsl:when>
                    <xsl:when test="starts-with($sysno,'0')">
                        <xsl:value-of select="substring($sysno,2)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$sysno"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:value-of select="$sysno"/>
            <xsl:value-of select="$SEP"/>

            <xsl:choose>
                <xsl:when test="MARC21:datafield[@tag='901' and @ind1='p']">
                    <xsl:value-of select="MARC21:datafield[@tag='901' and @ind1='p']/MARC21:subfield[@code='a']"/>
                    <xsl:if test="MARC21:datafield[@tag='901' and @ind1='p']/MARC21:subfield[@code='d']">
                        <xsl:value-of select="concat(' (', MARC21:datafield[@tag='901' and @ind1='p']/MARC21:subfield[@code='d'], ')')"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="MARC21:datafield[@tag='902' and @ind1='p']">
                    <xsl:value-of select="MARC21:datafield[@tag='902' and @ind1='p']/MARC21:subfield[@code='a']"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Kein Aktenbildner in DSV05-<xsl:value-of
                        select="MARC21:controlfield[@tag='001']"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$SEP"/>

            <xsl:value-of select="MARC21:datafield[@tag='245']"/>
            <xsl:value-of select="$SEP"/>

            <xsl:choose>
                <xsl:when test="//MARC21:record/MARC21:datafield[@tag='490']/MARC21:subfield[@code='w']/text()[. = $sysno_without_zeroes]">
                    <xsl:value-of select="'#ja#'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'#nein#'"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$SEP"/>

            <xsl:choose>
                <xsl:when test="MARC21:datafield[@tag='901' and @ind1='p']">
                    <xsl:value-of select="'#P#'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'#K#'"/>
                </xsl:otherwise>
            </xsl:choose>

           <xsl:value-of select="$NL"/>

        </xsl:for-each>
    </xsl:for-each>
  </xsl:template>
</xsl:transform>
