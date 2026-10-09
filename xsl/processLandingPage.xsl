<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:hcmc="http://hcmc.uvic.ca/ns"
                xmlns:xh="http://www.w3.org/1999/xhtml"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns="http://www.w3.org/1999/xhtml"
                xpath-default-namespace="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="#all" version="3.0">
  <!-- Render the small properties-driven homepage with shared branding and multilingual resources.
       Created on: 2026-10-09 
       Author: inokhrin -->

  <!--**************************************************************
       *                                                            *
       *                         Output                             *
       *                                                            *
       **************************************************************-->
  <xsl:output method="xhtml" html-version="5" encoding="UTF-8"
              normalization-form="NFC" indent="yes" exclude-result-prefixes="#all"
              omit-xml-declaration="yes" include-content-type="no"/>

  <!--**************************************************************
       *                                                            *
       *                          Modes                             *
       *                                                            *
       **************************************************************-->
  <xsl:mode on-no-match="shallow-copy" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                      Parameters                            *
       *                                                            *
       **************************************************************-->
  <!-- String flag: 'true' indicates language-specific output directories. -->
  <xsl:param name="isMultilingual" as="xs:string" select="'false'"/>
  <!-- Explicit output language. -->
  <xsl:param name="currentLang" as="xs:string" select="''"/>
  <!-- Default output language. -->
  <xsl:param name="defaultLang" as="xs:string" select="'en'"/>
  <!-- Comma-separated configured languages, retained for the build interface. -->
  <xsl:param name="languages" as="xs:string" select="'en'"/>

  <!--**************************************************************
       *                                                            *
       *                        Variables                           *
       *                                                            *
       **************************************************************-->
  <!-- Whether shared resources live above language-specific directories. -->
  <xsl:variable name="isMultilingualBool" as="xs:boolean" select="$isMultilingual eq 'true'"/>
  <xsl:variable name="lang" as="xs:string" select="if ($currentLang ne '') then $currentLang else $defaultLang"/>
  <xsl:variable name="propertiesDoc" as="document-node()" select="doc(resolve-uri('../properties.xml', static-base-uri()))"/>
  <xsl:variable name="siteTitle" as="xs:string" xpath-default-namespace=""
                select="normalize-space(string(($propertiesDoc/site/metadata/siteTitle/*[local-name() eq $lang],
                                                $propertiesDoc/site/metadata/siteTitle)[1]))"/>
  <xsl:variable name="metaDescription" as="xs:string" xpath-default-namespace=""
                select="normalize-space(string(($propertiesDoc/site/metadata/metaDescription/*[local-name() eq $lang],
                                                $propertiesDoc/site/metadata/metaDescription)[1]))"/>
  <xsl:variable name="configuredSiteUrl" as="xs:string" xpath-default-namespace=""
                select="normalize-space(string($propertiesDoc/site/metadata/siteUrl))"/>
  <!-- The public URL with a trailing slash. -->
  <xsl:variable name="siteUrl" as="xs:string"
                select="if (ends-with($configuredSiteUrl, '/')) then $configuredSiteUrl else $configuredSiteUrl || '/'"/>
  <xsl:variable name="canonicalUrl" as="xs:string"
                select="$siteUrl || (if ($isMultilingualBool) then $lang || '/' else '')"/>
  <xsl:variable name="txtDimensions" as="xs:string"
                select="unparsed-text(resolve-uri('../utilities/imageDimensions.txt', static-base-uri()))"/>
  <xsl:variable name="mapImgPathsToElements" as="map(xs:string, element(xh:img))">
    <xsl:map>
      <xsl:for-each select="distinct-values(tokenize($txtDimensions, '&#x0A;'))">
        <xsl:variable name="bits" as="xs:string*" select="tokenize(., '\s+')"/>
        <xsl:variable name="wh" as="xs:string*" select="if (count($bits) gt 1) then tokenize($bits[2], 'x') else ()"/>
        <xsl:if test="count($bits) eq 2 and count($wh) eq 2">
          <xsl:map-entry key="$bits[1]">
            <img src="{$bits[1]}" width="{$wh[1]}" height="{$wh[2]}"/>
          </xsl:map-entry>
        </xsl:if>
      </xsl:for-each>
    </xsl:map>
  </xsl:variable>

  <!--**************************************************************
       *                                                            *
       *                        Templates                           *
       *                                                            *
       **************************************************************-->
  <!-- Render the generated landing template. -->
  <xsl:template match="/">
    <xsl:message>Rendering the properties-driven simple homepage.</xsl:message>
    <xsl:apply-templates select="node()"/>
  </xsl:template>

  <!-- Set the homepage identifier and actual output language. -->
  <xsl:template match="html" priority="3">
    <xsl:copy>
      <xsl:sequence select="@*[local-name() ne 'lang']"/>
      <xsl:attribute name="lang" select="$lang"/>
      <xsl:if test="not(@id)">
        <xsl:attribute name="id">index</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="title" priority="5">
    <title><xsl:value-of select="$siteTitle"/></title>
  </xsl:template>

  <xsl:template match="meta[@name eq 'description']" priority="5">
    <meta name="description" content="{$metaDescription}"/>
  </xsl:template>

  <xsl:template match="link[@rel eq 'canonical']" priority="5">
    <link rel="canonical" href="{$canonicalUrl}"/>
  </xsl:template>

  <xsl:template match="link/@href[not(starts-with(., 'http')) and not(starts-with(., '/'))] |
                       script/@src[not(starts-with(., 'http')) and not(starts-with(., '/'))] |
                       img/@src[not(starts-with(., 'http')) and not(starts-with(., '/'))]" priority="3">
    <xsl:attribute name="{local-name()}" select="(if ($isMultilingualBool) then '../' else '') || ."/>
  </xsl:template>

  <!-- Preserve the existing intrinsic dimensions, aspect classes, and remaining image attributes. -->
  <xsl:template match="img[starts-with(@src, 'images/') or starts-with(@src, '/images/')]" priority="4">
    <xsl:variable name="normalizedSrc" as="xs:string" select="replace(@src, '^/', '')"/>
    <xsl:variable name="imgTag" as="element(xh:img)?" select="map:get($mapImgPathsToElements, $normalizedSrc)"/>
    <xsl:choose>
      <xsl:when test="exists($imgTag)">
        <xsl:variable name="aspectClass" as="xs:string"
                      select="if (number($imgTag/@width) eq number($imgTag/@height)) then 'square'
                              else if (number($imgTag/@width) gt number($imgTag/@height)) then 'landscape'
                              else 'portrait'"/>
        <img>
          <xsl:sequence select="$imgTag/@width, $imgTag/@height"/>
          <xsl:attribute name="class" select="normalize-space(string-join((@class, $aspectClass), ' '))"/>
          <xsl:attribute name="src" select="(if ($isMultilingualBool) then '../' else '') || $normalizedSrc"/>
          <xsl:sequence select="@*[not(local-name() = ('width', 'height', 'class', 'src'))]"/>
        </img>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Warning: No dimensions found for <xsl:value-of select="@src"/></xsl:message>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
