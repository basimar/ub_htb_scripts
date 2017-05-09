<?xml version='1.0' encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
<!--

  swasd-detailseiten.xsl
  generiere Detailinformationen für die Detailinformationen pro Deskriptor.
  Produziert wird eine einzige grosse HTML-Datei, die anschliessend mit
  swasd-splitte-detailseiten.pl in einzelne HTML-Seiten gesplittet wird.

  History:
  29.11.2002 - andres.vonarx@unibas.ch
  24.08.2010 - rewrite
  21.10.2010 - synon

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
            <link rel="stylesheet" type="text/css" href="../output/swa.css" />
            <link rel="stylesheet" type="text/css" href="../output/swasd.css" />
        </head>
        <body>
            <xsl:apply-templates/>
        </body>
    </html>
  </xsl:template>


  <xsl:template match="deskriptor">
    <h1><xsl:value-of select="@id"/></h1>
    <h2><xsl:value-of select="@name"/></h2>

    <!-- Synonyma -->
    <xsl:if test="synonyme/synonym/@name != ''">
        <h3>
            <p class="synonym_title">Im SWA auch benutzt im Sinne von: </p>
            <p class="synonym">
            <xsl:for-each select="synonyme/synonym">
                <xsl:value-of select="@name"/>
                <xsl:if test="position() != last()"><xsl:value-of select="$SYNONYMA_SEPARATOR"/></xsl:if>
            </xsl:for-each>
            </p>
        </h3>
    </xsl:if>

    <!-- Kataloglinks -->
    <p class="catalog_title">Suchresultate im Katalog:</p>
    <xsl:choose>
        <xsl:when test="count(dossiers/dossier) = 1">
            <xsl:for-each select="dossiers/dossier">
                <xsl:call-template name="katlink">
                    <xsl:with-param name="mit_titel" select="false()"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
            <xsl:for-each select="dossiers/dossier">
                <xsl:call-template name="katlink">
                    <xsl:with-param name="mit_titel" select="true()"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:otherwise>
    </xsl:choose>

    <!-- Kontext -->
    <xsl:if test="not(synonyme/synonym/@name != '')">
        <!-- Abstand, damit der Text nicht in die Box Navigationshilfe rutscht -->
        <br/>
    </xsl:if>
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

  <xsl:template name="katlink">
      <xsl:param name="mit_titel"/>
      <xsl:if test="$mit_titel = true()">
        <p class="dossier_title">
            <xsl:value-of select="@begriff"/>
            <xsl:if test="not(@unterbegriff_sache = '')">
                <xsl:value-of select="concat('. ', @unterbegriff_sache)"/>
            </xsl:if>
            <xsl:if test="not(@unterbegriff_ort = '')">
                <xsl:value-of select="concat('. ', @unterbegriff_ort)"/>
            </xsl:if>
        </p>
      </xsl:if>
      <p class="catalog">
        <a>
            <xsl:attribute name="href">
                <xsl:text disable-output-escaping="yes">javascript:aleph('Bro','</xsl:text>
                <xsl:value-of select="@suchstring" />
                <xsl:text disable-output-escaping="yes">')</xsl:text>
            </xsl:attribute>
                <xsl:text disable-output-escaping="yes">Broschüren ab 2005</xsl:text>
        </a>
      </p>
      <p class="catalog">
        <a>
            <xsl:attribute name="href">
                <xsl:text disable-output-escaping="yes">javascript:aleph('Zs','</xsl:text>
                <xsl:value-of select="@suchstring" />
                <xsl:text disable-output-escaping="yes">')</xsl:text>
            </xsl:attribute><xsl:text disable-output-escaping="yes">Zeitungsausschnitte ab 2005</xsl:text>
        </a>
      </p>
      <p class="catalog">
        <a>
            <xsl:attribute name="href">
                <xsl:text disable-output-escaping="yes">javascript:aleph('Per','</xsl:text>
                <xsl:value-of select="@suchstring" />
                <xsl:text disable-output-escaping="yes">')</xsl:text>
            </xsl:attribute><xsl:text disable-output-escaping="yes">Zeitschriften und Reihen</xsl:text>
        </a>
      </p>
      <p class="catalog">
        <a>
            <xsl:attribute name="href">
                <xsl:text disable-output-escaping="yes">javascript:aleph('Alt','</xsl:text>
                <xsl:value-of select="@suchstring" />
                <xsl:text disable-output-escaping="yes">')</xsl:text>
            </xsl:attribute><xsl:text disable-output-escaping="yes">Broschüren und Zeitungsausschnitte bis 2005 (als Dossiers in Schachteln)</xsl:text>
        </a>
      </p>
      <p class="catalog">
        <a>
            <xsl:attribute name="href">
                <xsl:text disable-output-escaping="yes">javascript:aleph('All','</xsl:text>
                <xsl:value-of select="@suchstring" />
                <xsl:text disable-output-escaping="yes">')</xsl:text>
            </xsl:attribute><xsl:text disable-output-escaping="yes">Alles</xsl:text>
        </a>
      </p>
      <xsl:value-of select="$NL"/>
  </xsl:template>


  <xsl:template name="context_chain">
    <xsl:param name="did"/>
    <p class="context">
        <a>
            <xsl:attribute name="href">
                <xsl:text>javascript:activate('</xsl:text>
                <xsl:value-of select="//deskriptor[@id=$did]/ancestor::thesaurus/@id"/>
                <xsl:text>');</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="//deskriptor[@id=$did]/ancestor::thesaurus/@name"/>
        </a>
        <xsl:value-of select="$SEP"/>

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
  </xsl:template>

</xsl:stylesheet>
