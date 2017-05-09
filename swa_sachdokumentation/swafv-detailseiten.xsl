<?xml version='1.0' encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
<!--

  swafv-detailseiten.xsl
  generiere Detailinformationen für die Detailinformationen pro Deskriptor.
  Produziert wird eine einzige grosse HTML-Datei, die anschliessend mit
  swafv-splitte-detailseiten.pl in einzelne HTML-Seiten gesplittet wird.

  History:
  29.11.2002 - andres.vonarx@unibas.ch
  24.08.2010 - rewrite
  21.10.2010 - synon
  15.05.2014 - rewrite für F+V, nur Teilbaum "Wirtschaftssektoren",
                nur Verweisungen

-->
  <xsl:output
    method          = "xhtml"
    encoding        = "UTF-8"
    indent          = "yes"
    doctype-public  = "-//W3C//DTD XHTML 1.0 Frameset//EN"
    doctype-system  = "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd"
    />
  <xsl:strip-space elements="*"/>

  <xsl:variable name="NL" select="'&#x0A;'" />
  <xsl:variable name="SEP" select="' '"/>
  <xsl:variable name="SYNONYMA_SEPARATOR" select="' - '"/>

  <xsl:template match="/">
    <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
            <link rel="stylesheet" type="text/css" href="../output/swa.css" />
            <link rel="stylesheet" type="text/css" href="../output/swafv.css" />
        </head>
        <body>
            <xsl:for-each select="//thesaurus">
              <xsl:if test="@name='Wirtschaftssektoren'">
                <xsl:apply-templates select="subthesaurus" />
              </xsl:if>
            </xsl:for-each>
        </body>
    </html>
  </xsl:template>


  <xsl:template match="deskriptor">
    <h1><xsl:value-of select="@id"/></h1>
    <h2><xsl:value-of select="@name"/></h2>

    <!-- Synonyma -->
    <xsl:if test="synonyme/synonym/@name != ''">
        <p class="synonym_title">Im SWA auch benutzt im Sinne von: </p>
        <p class="synonym">
        <xsl:for-each select="synonyme/synonym">
            <xsl:value-of select="@name"/>
            <xsl:if test="position() != last()"><xsl:value-of select="$SYNONYMA_SEPARATOR"/></xsl:if>
        </xsl:for-each>
        </p>
    </xsl:if>

    <!-- Kontext -->
    <p class="context_title">Dokumentensammlung &apos;<xsl:value-of select="@name"/>&apos; im Kontext</p>
    <p class="comment">Klicken Sie auf einen Begriff,
      um zur entsprechenden Stelle in der Systematischen Gliederung zu springen</p>
    <xsl:call-template name="context_chain">
        <xsl:with-param name="did">
            <xsl:value-of select="@id"/>
        </xsl:with-param>
    </xsl:call-template>
    <xsl:for-each select="siehe_auch/querverweis">
        <xsl:call-template name="context_chain">
            <xsl:with-param name="did">
                <xsl:value-of select="@linkid"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:for-each>

  </xsl:template>

  <xsl:template name="context_chain">
    <xsl:param name="did"/>
      <xsl:if test="//deskriptor[@id=$did]/ancestor::thesaurus/@name='Wirtschaftssektoren'">
        <p class="context">
            
            <xsl:if test="//deskriptor[@id=$did]/ancestor::subthesaurus">
                <a>
                    <xsl:attribute name="href">
                        <xsl:text>javascript:activate('</xsl:text>
                        <xsl:value-of select="//deskriptor[@id=$did]/ancestor::subthesaurus/@id"/>
                        <xsl:text>');</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of select="//deskriptor[@id=$did]/ancestor::subthesaurus/@name"/>
                </a>
                <xsl:value-of select="$SEP"/>
            </xsl:if>

            <xsl:if test="//deskriptor[@id=$did]/ancestor::teilthesaurus">
                <a>
                    <xsl:attribute name="href">
                        <xsl:text>javascript:activate('</xsl:text>
                        <xsl:value-of select="//deskriptor[@id=$did]/ancestor::teilthesaurus/@id"/>
                        <xsl:text>');</xsl:text>
                    </xsl:attribute>
                    <xsl:value-of select="//deskriptor[@id=$did]/ancestor::teilthesaurus/@name"/>
                </a>
                <xsl:value-of select="$SEP"/>
            </xsl:if>

            <a>
                <xsl:attribute name="href">
                    <xsl:text>javascript:activate('</xsl:text>
                    <xsl:value-of select="//deskriptor[@id=$did]/@id"/>
                    <xsl:text>');</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="//deskriptor[@id=$did]/@name"/>
            </a>
        </p>
      </xsl:if>
  </xsl:template>

</xsl:stylesheet>
