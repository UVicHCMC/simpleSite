<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:hcmc="http://hcmc.uvic.ca/ns"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xpath-default-namespace="" exclude-result-prefixes="#all" version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>Combines XML content with the generated shared template and optional discovery catalogue.</xd:desc>
    <xd:p><xd:b>Created on:</xd:b> 2026-10-02</xd:p>
    <xd:p><xd:b>Author:</xd:b> HCMC</xd:p>
  </xd:doc>

  <!--**************************************************************
       *                                                            *
       *                         Includes                           *
       *                                                            *
       **************************************************************-->
  <xsl:include href="module_discovery_cards.xsl"/>

  <!--**************************************************************
       *                                                            *
       *                          Output                            *
       *                                                            *
       **************************************************************-->
  <xsl:output method="html" html-version="5" encoding="UTF-8" normalization-form="NFC"
    indent="yes" omit-xml-declaration="yes" include-content-type="no" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                           Modes                            *
       *                                                            *
       **************************************************************-->
  <xsl:mode on-no-match="shallow-copy" exclude-result-prefixes="#all"/>
  <xsl:mode name="content" on-no-match="shallow-copy" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                         Parameters                         *
       *                                                            *
       **************************************************************-->
  <xd:doc><xd:desc>The language supplied by Ant.</xd:desc></xd:doc>
  <xsl:param name="currentLang" as="xs:string" select="'en'"/>
  <xd:doc><xd:desc>Comma-separated configured language codes.</xd:desc></xd:doc>
  <xsl:param name="languages" as="xs:string" select="'en'"/>
  <xd:doc><xd:desc>String flag omitting the shared shell on a complex homepage.</xd:desc></xd:doc>
  <xsl:param name="omitSiteChrome" as="xs:string" select="'false'"/>
  <xd:doc><xd:desc>The public URL shared with the sitemap build; blank omits canonical links.</xd:desc></xd:doc>
  <xsl:param name="publicSiteUrl" as="xs:string" select="normalize-space($propertiesDoc/site/metadata/siteUrl)"/>

  <!--**************************************************************
       *                                                            *
       *                          Variables                         *
       *                                                            *
       **************************************************************-->
  <xd:doc scope="component"><xd:desc>The source content document.</xd:desc></xd:doc>
  <xsl:variable name="contentRoot" as="document-node()" select="/"/>
  <xd:doc scope="component"><xd:desc>The corresponding HTML filename.</xd:desc></xd:doc>
  <xsl:variable name="currentPage" as="xs:string" select="replace(tokenize(base-uri(/), '/')[last()], '\.xml$', '.html')"/>
  <xd:doc scope="component"><xd:desc>The site configuration.</xd:desc></xd:doc>
  <xsl:variable name="propertiesDoc" as="document-node()" select="doc(resolve-uri('../properties.xml', static-base-uri()))"/>
  <xd:doc scope="component"><xd:desc>The source file's parent directory, possibly its language.</xd:desc></xd:doc>
  <xsl:variable name="parentDir" as="xs:string" select="tokenize(base-uri(/), '/')[last() - 1]"/>
  <xd:doc scope="component"><xd:desc>A language code detected in the source path.</xd:desc></xd:doc>
  <xsl:variable name="langFromPath" as="xs:string" select="if ($parentDir = $propertiesDoc/site/languages/lang/@code) then $parentDir else ''"/>
  <xd:doc scope="component"><xd:desc>The effective language.</xd:desc></xd:doc>
  <xsl:variable name="lang" as="xs:string" select="if ($langFromPath ne '') then $langFromPath else $currentLang"/>
  <xd:doc scope="component"><xd:desc>Whether the output uses language subdirectories.</xd:desc></xd:doc>
  <xsl:variable name="isMultilingual" as="xs:boolean" select="count(tokenize($languages, ',')) gt 1"/>
  <xd:doc scope="component"><xd:desc>The generated template for this source.</xd:desc></xd:doc>
  <xsl:variable name="template" as="document-node()" select="doc(resolve-uri('../templates/' || (if ($langFromPath ne '') then $lang || '/' else '') || 'contentPage.xml', static-base-uri()))"/>
  <xd:doc scope="component"><xd:desc>Whether to omit the homepage header and footer.</xd:desc></xd:doc>
  <xsl:variable name="isComplexHomepage" as="xs:boolean" select="$currentPage eq 'index.html' and $omitSiteChrome eq 'true'"/>
  <xd:doc scope="component"><xd:desc>The configured site title.</xd:desc></xd:doc>
  <xsl:variable name="siteTitle" as="xs:string" select="normalize-space(string(($propertiesDoc/site/metadata/siteTitle/*[local-name() eq $lang], $propertiesDoc/site/metadata/siteTitle)[1]))"/>
  <xd:doc scope="component"><xd:desc>The source's optional page title.</xd:desc></xd:doc>
  <xsl:variable name="pageTitle" as="xs:string" select="normalize-space($contentRoot/*/@data-page-title)"/>
  <xd:doc scope="component"><xd:desc>The page description, falling back to site metadata on the homepage.</xd:desc></xd:doc>
  <xsl:variable name="metaDescription" as="xs:string" select="if (normalize-space($contentRoot/*/@data-meta-description) ne '') then normalize-space($contentRoot/*/@data-meta-description) else if ($currentPage eq 'index.html') then normalize-space(string(($propertiesDoc/site/metadata/metaDescription/*[local-name() eq $lang], $propertiesDoc/site/metadata/metaDescription)[1])) else ''"/>
  <xd:doc scope="component"><xd:desc>The public base URL with exactly one trailing slash, or empty.</xd:desc></xd:doc>
  <xsl:variable name="siteUrl" as="xs:string" select="if (normalize-space($publicSiteUrl) eq '') then '' else replace(normalize-space($publicSiteUrl), '/+$', '') || '/'"/>
  <xd:doc scope="component"><xd:desc>The canonical destination, only when a public URL is configured.</xd:desc></xd:doc>
  <xsl:variable name="canonicalUrl" as="xs:string" select="if ($siteUrl eq '') then '' else $siteUrl || (if ($isMultilingual) then $lang || '/' else '') || (if ($currentPage eq 'index.html') then '' else $currentPage)"/>
  <xd:doc scope="component"><xd:desc>Image metadata produced by the existing build helper.</xd:desc></xd:doc>
  <xsl:variable name="dimensions" as="xs:string" select="unparsed-text(resolve-uri('../utilities/imageDimensions.txt', static-base-uri()))"/>
  <xd:doc scope="component"><xd:desc>Image paths mapped to their dimensions, ignoring malformed helper lines.</xd:desc></xd:doc>
  <xsl:variable name="imageDimensions" as="map(xs:string, xs:integer*)">
    <xsl:map>
      <xsl:for-each select="distinct-values(tokenize($dimensions, '&#10;'))[matches(., '^.+\s+[0-9]+x[0-9]+$')]">
        <xd:doc scope="component" xsl:use-when="false()"><xd:desc>The dimensions at the end of the line.</xd:desc></xd:doc>
        <xsl:variable name="size" as="xs:string" select="replace(., '^.*\s+([0-9]+x[0-9]+)$', '$1')"/>
        <xsl:map-entry key="replace(., '\s+[0-9]+x[0-9]+$', '')" select="tokenize($size, 'x') ! xs:integer(.)"/>
      </xsl:for-each>
    </xsl:map>
  </xsl:variable>

  <!--**************************************************************
       *                                                            *
       *                          Templates                         *
       *                                                            *
       **************************************************************-->
  <xd:doc><xd:desc>Processes the generated template in the context of the source content.</xd:desc></xd:doc>
  <xsl:template match="/">
    <xsl:message select="'Processing ' || $currentPage || (if ($isComplexHomepage) then ' without shared navigation and footer' else '') || '.'"/>
    <xsl:apply-templates select="$template/*"/>
  </xsl:template>

  <xd:doc><xd:desc>Adds a stable page ID.</xd:desc></xd:doc>
  <xsl:template match="xh:html" priority="3">
    <html><xsl:sequence select="@* except @id"/><xsl:attribute name="id" select="if (@id) then @id else replace($currentPage, '\.html$', '')"/><xsl:apply-templates/></html>
  </xsl:template>
  <xd:doc><xd:desc>Omits the shared shell only for a complex homepage.</xd:desc></xd:doc>
  <xsl:template match="xh:div[contains-token(@class, 'top-wrapper')] | xh:footer" priority="4">
    <xsl:if test="not($isComplexHomepage)"><xsl:next-match/></xsl:if>
  </xsl:template>
  <xd:doc><xd:desc>Supplies the page title without repeating the site title.</xd:desc></xd:doc>
  <xsl:template match="xh:title" priority="5">
    <title><xsl:sequence select="if ($pageTitle ne '' and $pageTitle ne $siteTitle) then $pageTitle || ' | ' || $siteTitle else $siteTitle"/></title>
  </xsl:template>
  <xd:doc><xd:desc>Supplies the page description.</xd:desc></xd:doc>
  <xsl:template match="xh:meta[@name eq 'description']" priority="5">
    <meta name="description" content="{$metaDescription}"/>
  </xsl:template>
  <xd:doc><xd:desc>Emits a canonical link only when the site's public address is known.</xd:desc></xd:doc>
  <xsl:template match="xh:link[@rel eq 'canonical']" priority="5">
    <xsl:if test="$canonicalUrl ne ''"><link rel="canonical" href="{$canonicalUrl}"/></xsl:if>
  </xsl:template>
  <xd:doc><xd:desc>Inserts wrapper children, including insertion-point processing instructions and prose.</xd:desc></xd:doc>
  <xsl:template match="processing-instruction('docContent')" priority="5">
    <xsl:message select="'Inserting content for page: ' || $currentPage"/>
    <xsl:apply-templates select="$contentRoot/*/node()" mode="content"/>
  </xsl:template>
  <xd:doc><xd:desc>Adds section navigation for ordinary multi-section pages.</xd:desc></xd:doc>
  <xsl:template match="xh:body" priority="3">
    <body>
      <xsl:sequence select="@*"/>
      <xd:doc scope="component" xsl:use-when="false()"><xd:desc>Source sections with an ID and a heading.</xd:desc></xd:doc>
      <xsl:variable name="sections" as="element()*" select="$contentRoot/*//*[local-name() eq 'section'][@id][.//*[matches(local-name(), '^h[1-6]$')]]"/>
      <xsl:if test="$currentPage ne 'index.html' and count($sections) ge 2">
        <nav class="subnav" aria-label="Section navigation"><ul>
          <xsl:for-each select="$sections"><li><a href="#{@id}"><xsl:sequence select="string((.//*[matches(local-name(), '^h[1-6]$')])[1])"/></a></li></xsl:for-each>
        </ul></nav>
      </xsl:if>
      <xsl:apply-templates/>
    </body>
  </xsl:template>

  <!-- Both template and content modes share namespace conversion and resource handling. -->
  <xd:doc><xd:desc>Serializes XHTML source elements as HTML5 while retaining their children.</xd:desc></xd:doc>
  <xsl:template match="xh:*" mode="#all" priority="2">
    <xsl:element name="{local-name()}" namespace=""><xsl:apply-templates select="@* | node()" mode="#current"/></xsl:element>
  </xsl:template>
  <xd:doc><xd:desc>Adjusts shared asset URLs for multilingual output directories.</xd:desc></xd:doc>
  <xsl:template match="xh:link/@href | xh:script/@src | xh:img/@src" mode="#all" priority="3">
    <xsl:attribute name="{local-name()}" select="(if ($isMultilingual and matches(., '^(css|js|images|fonts)/')) then '../' else '') || ."/>
  </xsl:template>
  <xd:doc><xd:desc>Replaces current-page placeholders in links.</xd:desc></xd:doc>
  <xsl:template match="@href[contains(., '{{currentPage}}')]" mode="#all" priority="4">
    <xsl:attribute name="href" select="replace(., '\{\{currentPage\}\}', $currentPage)"/>
  </xsl:template>
  <xd:doc><xd:desc>Marks links to the current content page in generated navigation.</xd:desc></xd:doc>
  <xsl:template match="xh:a[contains-token(@class, 'item')][@href]" mode="#all" priority="4">
    <xd:doc scope="component" xsl:use-when="false()"><xd:desc>Whether the link points at this page.</xd:desc></xd:doc>
    <xsl:variable name="active" as="xs:boolean" select="replace(tokenize(string(@href), '[?#]')[1], '^.*/', '') eq $currentPage"/>
    <a><xsl:sequence select="@* except (@class, @aria-current)"/><xsl:attribute name="class" select="normalize-space(string(@class) || (if ($active) then ' active' else ''))"/>
      <xsl:if test="$active"><xsl:attribute name="aria-current">page</xsl:attribute></xsl:if>
      <xsl:apply-templates mode="#current"/>
    </a>
  </xsl:template>
  <xd:doc><xd:desc>Adds image dimensions when available, preserving source attributes and alternative text.</xd:desc></xd:doc>
  <xsl:template match="xh:img[starts-with(@src, 'images/') or starts-with(@src, '/images/')]" mode="#all" priority="4">
    <xd:doc scope="component" xsl:use-when="false()"><xd:desc>The image's measured width and height, if known.</xd:desc></xd:doc>
    <xsl:variable name="size" as="xs:integer*" select="map:get($imageDimensions, replace(@src, '^/', ''))"/>
    <img>
      <xsl:apply-templates select="@* except (@width, @height, @class)" mode="#current"/>
      <xsl:choose>
        <xsl:when test="count($size) eq 2">
          <xsl:attribute name="width" select="$size[1]"/><xsl:attribute name="height" select="$size[2]"/>
          <xsl:attribute name="class" select="normalize-space(string(@class) || ' ' || (if ($size[1] eq $size[2]) then 'square' else if ($size[1] gt $size[2]) then 'landscape' else 'portrait'))"/>
        </xsl:when>
        <xsl:otherwise><xsl:sequence select="@width | @height | @class"/></xsl:otherwise>
      </xsl:choose>
    </img>
  </xsl:template>
</xsl:stylesheet>
