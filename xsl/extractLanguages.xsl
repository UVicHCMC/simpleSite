<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:hcmc="http://hcmc.uvic.ca/ns"
                xpath-default-namespace=""
                exclude-result-prefixes="#all"
                version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>Exports site configuration as Ant properties.</xd:desc>
    <xd:p><xd:b>Created on:</xd:b> 2026-09-29</xd:p>
    <xd:p><xd:b>Author:</xd:b> HCMC</xd:p>
  </xd:doc>

  <!--**************************************************************
       *                                                            *
       *                         Output                             *
       *                                                            *
       **************************************************************-->
  <xsl:output method="text" encoding="UTF-8" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                        Templates                           *
       *                                                            *
       **************************************************************-->
  <xd:doc>
    <xd:desc>Writes language, asset, and homepage-mode settings for Ant.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:text>languages=</xsl:text>
    <xsl:value-of select="string-join(/site/languages/lang/@code, ',')"/>
    <xsl:text>&#10;defaultLang=</xsl:text>
    <xsl:value-of select="(/site/languages/lang[@default eq 'true'], /site/languages/lang)[1]/@code"/>
    <xsl:text>&#10;languageCount=</xsl:text>
    <xsl:value-of select="count(/site/languages/lang)"/>
    <xsl:text>&#10;hasLanguageSelector=</xsl:text>
    <xsl:value-of select="if (/site/languageSelector) then 'true' else 'false'"/>
    <xsl:if test="normalize-space(/site/landingPageMode) ne ''">
      <xsl:text>&#10;landingPageMode=</xsl:text>
      <xsl:value-of select="normalize-space(/site/landingPageMode)"/>
    </xsl:if>
    <xsl:text>&#10;cssFile=</xsl:text>
    <xsl:value-of select="/site/files/cssFile"/>
    <xsl:text>&#10;jsFile=</xsl:text>
    <xsl:value-of select="/site/files/jsFile"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
