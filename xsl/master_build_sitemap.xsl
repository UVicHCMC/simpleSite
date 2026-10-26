<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:hcmc="http://hcmc.uvic.ca/ns"
  xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
  xpath-default-namespace="" exclude-result-prefixes="#all" version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>Builds search-engine metadata using the same public URL as content-page canonical links.</xd:desc>
    <xd:p><xd:b>Created on:</xd:b> 2018-03-05; revised 2026-10-02</xd:p>
    <xd:p><xd:b>Author:</xd:b> Martin Holmes</xd:p>
  </xd:doc>

  <!--**************************************************************
       *                                                            *
       *                          Output                            *
       *                                                            *
       **************************************************************-->
  <xsl:output method="xml" encoding="UTF-8" normalization-form="NFC" indent="yes" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                           Modes                            *
       *                                                            *
       **************************************************************-->
  <xsl:mode on-no-match="shallow-skip" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                         Parameters                         *
       *                                                            *
       **************************************************************-->
  <xd:doc><xd:desc>The configured public URL, supplied by Ant.</xd:desc></xd:doc>
  <xsl:param name="siteUrl" as="xs:string" select="normalize-space(doc(resolve-uri('../properties.xml', static-base-uri()))/site/metadata/siteUrl)"/>
  <xd:doc><xd:desc>The generated site directory, relative to the project root.</xd:desc></xd:doc>
  <xsl:param name="outputDir" as="xs:string" select="'site'"/>

  <!--**************************************************************
       *                                                            *
       *                          Variables                         *
       *                                                            *
       **************************************************************-->
  <xd:doc scope="component"><xd:desc>The normalized public base address.</xd:desc></xd:doc>
  <xsl:variable name="baseUrl" as="xs:string" select="replace(normalize-space($siteUrl), '/+$', '') || '/'"/>
  <xd:doc scope="component"><xd:desc>The absolute directory of generated pages.</xd:desc></xd:doc>
  <xsl:variable name="siteDirectory" as="xs:anyURI" select="resolve-uri('../' || $outputDir || '/', static-base-uri())"/>

  <!--**************************************************************
       *                                                            *
       *                          Templates                         *
       *                                                            *
       **************************************************************-->
  <xd:doc><xd:desc>Lists generated HTML pages and writes their robots.txt sitemap reference.</xd:desc></xd:doc>
  <xsl:template match="/">
    <xsl:if test="normalize-space($siteUrl) eq ''"><xsl:message terminate="yes">Sitemap: PROBLEM: Configure a public siteUrl before generating search-engine metadata.</xsl:message></xsl:if>
    <xsl:message select="'Building sitemap for ' || $baseUrl"/>
    <urlset>
      <xsl:for-each select="sort(uri-collection($siteDirectory || '?select=*.html;recurse=yes'))">
        <xsl:variable name="pagePath" as="xs:string" select="substring-after(., $siteDirectory)"/>
        <url><loc><xsl:sequence select="$baseUrl || (if ($pagePath eq 'index.html') then '' else $pagePath)"/></loc></url>
      </xsl:for-each>
    </urlset>
    <xsl:result-document href="robots.txt" method="text" encoding="UTF-8" normalization-form="NFC" exclude-result-prefixes="#all">
      <xsl:sequence select="'Sitemap: ' || $baseUrl || 'sitemap.xml' || '&#10;'"/>
    </xsl:result-document>
  </xsl:template>
</xsl:stylesheet>
