<?xml version="1.0" encoding="utf-8"?>
<!--
    INFO
    ====
    extract-top-info.xsl
    in:  MARC 21 XML
    out: TSV Textdatei mit den Feldern
         - Systemnummer,
         - Sortierfeld (Aktenbildner),
         - XML-Data (Aktenbildner),
         - Marker: Struktur (1-3 Ziffern gemäss Nummerierung, 'K' für Kryptonachlass (d.h. Aufnahme hat ein 490er), 'N'    für Nicht-Krypto -> als eindeutiger Hash benötigt für Aufnahmen mit mehreren Aktenbildnern (osc)

    VERSIONSGESCHICHTE
    ==================
    13.11.2008/ava: rev.
    14.03.2011/osc: Umstellung auf mehrere Aktenbildner
    05.01.2016/bmt: Angepasst auf neues HAN-Format (Aktenbildner neu in 100/110/111/700/710/711)

-->

<xsl:stylesheet version="1.0"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  >

  <xsl:output method="text" encoding="UTF-8" />
  <xsl:variable name="TAB" select="'&#09;'"/>
  <xsl:variable name="NL" select="'&#x0A;'"/>

  <xsl:template match="/">

<!-- 
===============================================================================
1. Teil: Personen- und Familiennachlässe und Autographensammlungen (i.e. 700$4cre)
===============================================================================
-->
<xsl:for-each select="//marc:datafield[@tag='100' or @tag='700']/marc:subfield[@code='a']">
<xsl:if test="../marc:subfield[@code='4'] = 'cre'">

<!-- Systemnummer -->

   <xsl:value-of select="../../marc:controlfield[@tag='001']"/>
   <xsl:value-of select="$TAB"/>

<!-- Sortierwert -->

   <xsl:value-of select="."/>
      <xsl:if test="../marc:subfield[@code='b']">
         <xsl:value-of select="concat(' ', ../marc:subfield[@code='b'], '.')"/>
      </xsl:if>
      <xsl:if test="../marc:subfield[@code='c']">
         <xsl:value-of select="concat(', ', ../marc:subfield[@code='c'])"/>
      </xsl:if>
      <xsl:if test="../marc:subfield[@code='d']">
         <xsl:value-of select="concat(' (', ../marc:subfield[@code='d'], ')')"/>
      </xsl:if>
   <xsl:value-of select="$TAB"/>

<!-- XML-Data (Anzeige) -->

   <xsl:text>&lt;nachlass&gt;</xsl:text>
     <xsl:value-of select="."/>
         <xsl:if test="../marc:subfield[@code='b']">
              <xsl:value-of select="concat(' ', ../marc:subfield[@code='b'], '.')"/>
         </xsl:if>
         <xsl:if test="../marc:subfield[@code='c']">
     <xsl:value-of select="concat(', ', ../marc:subfield[@code='c'])"/>
         </xsl:if>
         <xsl:if test="../marc:subfield[@code='d']">
     <xsl:value-of select="concat(' (', ../marc:subfield[@code='d'], ')')"/>
         </xsl:if>
   <xsl:text>&lt;/nachlass&gt;</xsl:text>
     <xsl:value-of select="$TAB"/>

<!--Marker (= (n-stelliger) Zusatz zur Systemnummer bei Kryptonachlässen und Nachlässen mit mehreren Aktenbildnern zur Erstellung eindeutiger Hashes
-->

    <!--ok, brauchbare Lösung (osc)-->
    <xsl:value-of select="position()"/>

     <xsl:choose>
        <xsl:when test="../../marc:datafield[@tag='490']">
           <xsl:text>K</xsl:text>
        </xsl:when>
        <xsl:otherwise>
           <xsl:text>N</xsl:text>
        </xsl:otherwise>
     </xsl:choose>
   <xsl:value-of select="$NL"/>
 </xsl:if>
 </xsl:for-each>

<!-- 
=====================================================
2. Teil: Archive von Körperschaften (i.e. 710$4cre)
=====================================================
-->

<xsl:for-each select="//marc:datafield[@tag='110' or @tag='111' or @tag='710' or @tag='711']/marc:subfield[@code='a']">
<xsl:if test="../marc:subfield[@code='4'] = 'cre'">

<!-- Systemnummer -->

     <xsl:value-of select="../../marc:controlfield[@tag='001']"/>
     <xsl:value-of select="$TAB"/>

<!-- Sortierwert -->

     <xsl:value-of select="."/>
         <xsl:if test="../marc:subfield[@code='b']">
              <xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
         </xsl:if>
    <xsl:value-of select="$TAB"/>

<!-- XML-Data (Anzeige) -->

   <xsl:text>&lt;nachlass&gt;</xsl:text>
     <xsl:value-of select="."/>
         <xsl:if test="../marc:subfield[@code='b']">
              <xsl:value-of select="concat(', ', ../marc:subfield[@code='b'])"/>
         </xsl:if>
    <xsl:text>&lt;/nachlass&gt;</xsl:text>
   <xsl:value-of select="$TAB"/>

<!--Marker (= (zweistelliger) Zusatz zur Systemnummer bei Kryptonachlässen und Nachlässen mit mehreren Aktenbildnern zur Erstellung eindeutiger Hashes
-->

    <!--ok, brauchbare Lösung-->
      <xsl:value-of select="position()"/>
         <xsl:choose>
            <xsl:when test="../../marc:datafield[@tag='490']">
               <xsl:text>K</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>N</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:value-of select="$NL"/>
      </xsl:if>
      </xsl:for-each>

<!-- ========================================================== -->

   </xsl:template>
</xsl:stylesheet>
