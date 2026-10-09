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
  <!-- Render content XML through the shared page template, including content and complex homepages.
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
  <xsl:mode name="content" on-no-match="shallow-copy" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                      Parameters                            *
       *                                                            *
       **************************************************************-->
  <!-- Explicit page language; otherwise infer it from the content path or site default. -->
  <xsl:param name="currentLang" as="xs:string" select="''"/>
  <!-- Comma-separated output languages supplied by Ant. -->
  <xsl:param name="languages" as="xs:string" select="'en'"/>
  <!-- String flag: 'true' omits the homepage's shared navigation and footer. -->
  <xsl:param name="omitSiteChrome" as="xs:string" select="'false'"/>

  <!--**************************************************************
       *                                                            *
       *                        Variables                           *
       *                                                            *
       **************************************************************-->
  <xsl:variable name="currentFile" as="xs:string" select="tokenize(base-uri(/), '/')[last()]"/>
  <xsl:variable name="currentPage" as="xs:string" select="replace($currentFile, '\.xml$', '.html')"/>
  <xsl:variable name="isHomepage" as="xs:boolean" select="$currentPage eq 'index.html'"/>
  <xsl:variable name="isComplexHomepage" as="xs:boolean" select="$isHomepage and $omitSiteChrome eq 'true'"/>
  <xsl:variable name="propertiesDoc" as="document-node()" select="doc(resolve-uri('../properties.xml', static-base-uri()))"/>
  <xsl:variable name="validLangCodes" as="xs:string*" xpath-default-namespace=""
                select="$propertiesDoc/site/languages/lang/@code/string()"/>
  <xsl:variable name="pathParts" as="xs:string*" select="tokenize(base-uri(/), '/')"/>
  <xsl:variable name="langFromPath" as="xs:string"
                select="if ($pathParts[last() - 1] = $validLangCodes) then $pathParts[last() - 1] else ''"/>
  <xsl:variable name="lang" as="xs:string" xpath-default-namespace=""
                select="if ($currentLang ne '') then $currentLang
                        else if ($langFromPath ne '') then $langFromPath
                        else string(($propertiesDoc/site/languages/lang[@default eq 'true']/@code,
                                     $propertiesDoc/site/languages/lang[1]/@code, 'en')[1])"/>
  <xsl:variable name="templatePath" as="xs:string"
                select="if ($langFromPath ne '') then '../templates/' || $lang || '/contentPage.xml'
                        else '../templates/contentPage.xml'"/>
  <xsl:variable name="template" as="document-node()" select="doc(resolve-uri($templatePath, static-base-uri()))"/>
  <xsl:variable name="contentRoot" as="document-node()" select="/"/>
  <xsl:variable name="siteTitle" as="xs:string" xpath-default-namespace=""
                select="normalize-space(string(($propertiesDoc/site/metadata/siteTitle/*[local-name() eq $lang],
                                                $propertiesDoc/site/metadata/siteTitle)[1]))"/>
  <xsl:variable name="pageTitle" as="xs:string" select="normalize-space(string($contentRoot/*/@data-page-title))"/>
  <!-- The homepage uses configured site metadata unless its content supplies a description. -->
  <xsl:variable name="metaDescription" as="xs:string" xpath-default-namespace=""
                select="if ($contentRoot/*/@data-meta-description) then normalize-space(string($contentRoot/*/@data-meta-description))
                        else if ($isHomepage) then normalize-space(string(($propertiesDoc/site/metadata/metaDescription/*[local-name() eq $lang],
                                                                          $propertiesDoc/site/metadata/metaDescription)[1]))
                        else ''"/>
  <xsl:variable name="configuredSiteUrl" as="xs:string" xpath-default-namespace=""
                select="normalize-space(string($propertiesDoc/site/metadata/siteUrl))"/>
  <xsl:variable name="siteUrl" as="xs:string"
                select="if (ends-with($configuredSiteUrl, '/')) then $configuredSiteUrl else $configuredSiteUrl || '/'"/>
  <!-- Whether resources are shared above language-specific output directories. -->
  <xsl:variable name="isMultilingual" as="xs:boolean" select="count(tokenize($languages, ',')) gt 1"/>
  <!-- Homepage canonical URLs retain the site or language root rather than index.html. -->
  <xsl:variable name="canonicalUrl" as="xs:string"
                select="$siteUrl || (if ($isMultilingual) then $lang || '/' else '') ||
                        (if ($isHomepage) then '' else $currentPage)"/>
  <xsl:variable name="txtDimensions" as="xs:string"
                select="unparsed-text(resolve-uri('../utilities/imageDimensions.txt', static-base-uri()))"/>
  <!-- Image paths mapped to intrinsic dimensions for hcmc:addImageDimensions. -->
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
  <!-- Render the generated shared template using the source content as context. -->
  <xsl:template match="/">
    <xsl:message>Rendering <xsl:value-of select="$currentPage"/> from content XML.</xsl:message>
    <xsl:apply-templates select="$template/*"/>
  </xsl:template>

  <!-- Add intrinsic image dimensions and the existing aspect class while preserving other attributes. -->
  <xsl:template name="hcmc:addImageDimensions">
    <xsl:param name="img" as="element(xh:img)"/>
    <xsl:variable name="normalizedSrc" as="xs:string" select="replace($img/@src, '^/', '')"/>
    <xsl:variable name="imgTag" as="element(xh:img)?" select="map:get($mapImgPathsToElements, $normalizedSrc)"/>
    <xsl:choose>
      <xsl:when test="exists($imgTag)">
        <!-- The aspect class used by existing site styles. -->
        <xsl:variable name="aspectClass" as="xs:string"
                      select="if (number($imgTag/@width) eq number($imgTag/@height)) then 'square'
                              else if (number($imgTag/@width) gt number($imgTag/@height)) then 'landscape'
                              else 'portrait'"/>
        <img>
          <xsl:sequence select="$imgTag/@width, $imgTag/@height"/>
          <xsl:attribute name="class" select="normalize-space(string-join(($img/@class, $aspectClass), ' '))"/>
          <xsl:attribute name="src" select="(if ($isMultilingual) then '../' else '') || $normalizedSrc"/>
          <xsl:sequence select="$img/@*[not(local-name() = ('width', 'height', 'class', 'src'))]"/>
        </img>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Warning: No dimensions found for <xsl:value-of select="$img/@src"/></xsl:message>
        <xsl:for-each select="$img">
          <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
          </xsl:copy>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Shared template mode. -->
  <!-- Set the generated page identifier while preserving an authored template identifier. -->
  <xsl:template match="html" priority="3">
    <xsl:copy>
      <xsl:sequence select="@*[local-name() ne 'lang']"/>
      <xsl:attribute name="lang" select="$lang"/>
      <xsl:if test="not(@id)">
        <xsl:attribute name="id" select="replace($currentPage, '\.html$', '')"/>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Supply page-specific title metadata. -->
  <xsl:template match="title" priority="5">
    <title><xsl:value-of select="if ($pageTitle eq '' or $pageTitle eq $siteTitle) then $siteTitle else $pageTitle || ' | ' || $siteTitle"/></title>
  </xsl:template>
  <!-- Supply the page description, including the configured homepage description. -->
  <xsl:template match="meta[@name eq 'description']" priority="5">
    <meta name="description" content="{$metaDescription}"/>
  </xsl:template>
  <!-- Supply the configured canonical URL. -->
  <xsl:template match="link[@rel eq 'canonical']" priority="5">
    <link rel="canonical" href="{$canonicalUrl}"/>
  </xsl:template>

  <!-- Omit the shared header and footer for complex homepages; otherwise use the normal template. -->
  <xsl:template match="div[tokenize(normalize-space(@class), '\s+') = 'top-wrapper'] | footer" priority="6">
    <xsl:if test="not($isComplexHomepage)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

  <!-- Resolve relative head assets above multilingual page directories. -->
  <xsl:template match="link/@href[not(starts-with(., 'http')) and not(starts-with(., '/'))] |
                       script/@src[not(starts-with(., 'http')) and not(starts-with(., '/'))]" priority="3">
    <xsl:attribute name="{local-name()}" select="(if ($isMultilingual) then '../' else '') || ."/>
  </xsl:template>
  <!-- Adjust relative image paths, including images without recorded dimensions. -->
  <xsl:template match="img/@src[starts-with(., 'images/')]" mode="#default content" priority="4">
    <xsl:attribute name="src" select="(if ($isMultilingual) then '../' else '') || ."/>
  </xsl:template>

  <!-- Preserve an authored homepage main and its sibling bands in their original positions. -->
  <xsl:template match="main" priority="5">
    <xsl:choose>
      <xsl:when test="$isHomepage and $contentRoot/*/main">
        <xsl:apply-templates select=".//processing-instruction('docContent')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--Replace the template's docContent instruction with the wrapper's child elements.-->
  <xsl:template match="processing-instruction('docContent')" priority="5">
    <xsl:message>Inserting content for page: <xsl:value-of select="$currentPage"/></xsl:message>
    <xsl:apply-templates select="$contentRoot/*/*" mode="content"/>
  </xsl:template>
  <!--Complete language-switch links using the generated filename.-->
  <xsl:template match="@href[contains(., '{{currentPage}}')]" priority="3">
    <xsl:attribute name="href" select="replace(., '\{\{currentPage\}\}', $currentPage)"/>
  </xsl:template>
  <!--Mark the current navigation item; root links identify the homepage.-->
  <xsl:template match="a[tokenize(normalize-space(@class), '\s+') = 'item'][@href]" priority="4">
    <!--The target filename with any query string or fragment removed.-->
    <xsl:variable name="targetPage" as="xs:string" select="replace(tokenize(string(@href), '[?#]')[1], '^.*/', '')"/>
    <!--Whether this link identifies the current page.-->
    <xsl:variable name="isActive" as="xs:boolean"
                  select="$targetPage eq $currentPage or ($isHomepage and @href eq '/')"/>
    <xsl:copy>
      <xsl:sequence select="@*[not(local-name() = ('class', 'aria-current'))]"/>
      <xsl:attribute name="class" select="normalize-space(string-join((string(@class), if ($isActive) then 'active' else ()), ' '))"/>
      <xsl:if test="$isActive">
        <xsl:attribute name="aria-current">page</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <!--Retain ordinary pages' automatic section navigation. Authored homepages keep their custom layout.-->
  <xsl:template match="body" priority="3">
    <!-- The localized secondary navigation label. -->
    <xsl:variable name="sectionNavLabel" as="xs:string" xpath-default-namespace=""
                  select="if ($propertiesDoc/site/subnav-aria-label/*[local-name() eq $lang])
                          then normalize-space(string($propertiesDoc/site/subnav-aria-label/*[local-name() eq $lang]))
                          else 'Section navigation'"/>
    <!-- Sections encoded in the source content, including unnamespaced content. -->
    <xsl:variable name="sections" as="element()*" select="$contentRoot/*/*/descendant-or-self::*[local-name() eq 'section']"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="not($isHomepage) and count($sections) ge 2">
        <xsl:message>Creating section navigation with <xsl:value-of select="count($sections)"/> sections</xsl:message>
        <nav class="subnav" aria-label="{$sectionNavLabel}">
          <ul>
            <xsl:for-each select="$sections">
             <!--The section's anchor identifier.-->
              <xsl:variable name="sectionId" as="attribute(id)?" select="@id"/>
              <!--The first heading within this section.-->
              <xsl:variable name="sectionTitle" as="element()?" select="(.//*[matches(local-name(), '^h[1-6]$')])[1]"/>
              <xsl:if test="$sectionId and $sectionTitle">
                <li><a href="#{$sectionId}"><xsl:value-of select="$sectionTitle"/></a></li>
              </xsl:if>
            </xsl:for-each>
          </ul>
        </nav>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Dimension local images in both the template and the authored content. -->
  <xsl:template match="img[starts-with(@src, 'images/') or starts-with(@src, '/images/')]"
                mode="#default content" priority="4">
    <xsl:call-template name="hcmc:addImageDimensions">
      <xsl:with-param name="img" as="element(xh:img)" select="."/>
    </xsl:call-template>
  </xsl:template>

  <!-- Accept legacy unnamespaced content and render it as XHTML. -->
  <xsl:template match="*[namespace-uri() eq '']" mode="content" priority="1">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="@* | node()" mode="content"/>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>
