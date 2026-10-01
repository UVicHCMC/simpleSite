<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:hcmc="http://hcmc.uvic.ca/ns"
                exclude-result-prefixes="#all" 
                version="3.0">
  
  <xsl:output method="html" indent="yes" encoding="UTF-8" omit-xml-declaration="yes" exclude-result-prefixes="#all"/>
  
  <!-- Parameters passed from build -->
  <xsl:param name="currentLang" select="'en'"/>
  <xsl:param name="languages" select="'en'"/>
  <xd:doc>
    <xd:desc>Omits the shared top navigation area and footer for a complex homepage.</xd:desc>
  </xd:doc>
  <xsl:param name="omitSiteChrome" as="xs:string" select="'false'"/>
  
  <!-- Get current document filename and page name -->
  <xsl:variable name="currentFile" select="tokenize(base-uri(/), '/')[last()]"/>
  <xsl:variable name="currentPage" select="replace($currentFile, '\.xml$', '.html')"/>
  
  <!-- Load properties to get valid language codes (use static-base-uri to resolve relative to XSLT file) -->
  <xsl:variable name="propertiesDoc" select="document(resolve-uri('../properties.xml', static-base-uri()))"/>
  <xsl:variable name="validLangCodes" select="$propertiesDoc/site/languages/lang/@code"/>
  
  <!-- Determine language from path (for bilingual builds) or use parameter -->
  <xsl:variable name="pathParts" select="tokenize(base-uri(/), '/')"/>
  <xsl:variable name="langFromPath" select="
    if ($pathParts[last() - 1] = $validLangCodes) then
      $pathParts[last() - 1]
    else ''
                  "/>
  
  <!-- Use explicit parameter if provided, otherwise detect from path -->
  <xsl:variable name="lang" select="
    if ($currentLang != '' and $currentLang != 'en') then 
      $currentLang 
    else if ($langFromPath != '') then 
      $langFromPath
    else 
      'en'
  "/>
  
  <!-- Load the appropriate template -->
  <xd:doc scope="component">
    <xd:desc>Resolves the generated content template for this language.</xd:desc>
  </xd:doc>
  <xsl:variable name="templatePath" as="xs:string"
                select="if ($langFromPath ne '')
                        then '../templates/' || $lang || '/contentPage.xml'
                        else '../templates/contentPage.xml'"/>

  <xd:doc scope="component">
    <xd:desc>True only when a complex index page requests the page shell without navigation or footer.</xd:desc>
  </xd:doc>
  <xsl:variable name="isComplexHomepage" as="xs:boolean"
                select="$currentPage eq 'index.html' and $omitSiteChrome eq 'true'"/>

  <xsl:variable name="template" select="doc($templatePath)"/>
  
  <!-- Store the content document root for later use -->
  <xsl:variable name="contentRoot" select="/"/>

  <!-- Build page-specific search metadata from the content root and site properties. -->
  <xsl:variable name="siteTitle" as="xs:string" select="normalize-space(string(($propertiesDoc/site/metadata/siteTitle/*[local-name() = $lang], $propertiesDoc/site/metadata/siteTitle)[1]))"/>
  <xsl:variable name="pageTitle" as="xs:string" select="normalize-space(string($contentRoot/*/@data-page-title))"/>
  <xsl:variable name="metaDescription" as="xs:string"
                select="if (normalize-space(string($contentRoot/*/@data-meta-description)) ne '')
                        then normalize-space(string($contentRoot/*/@data-meta-description))
                        else if ($currentPage eq 'index.html')
                        then normalize-space(string(($propertiesDoc/site/metadata/metaDescription/*[local-name() eq $lang], $propertiesDoc/site/metadata/metaDescription)[1]))
                        else ''"/>
  <xsl:variable name="configuredSiteUrl" as="xs:string" select="normalize-space(string($propertiesDoc/site/metadata/siteUrl))"/>
  <xsl:variable name="siteUrl" as="xs:string" select="if (ends-with($configuredSiteUrl, '/')) then $configuredSiteUrl else concat($configuredSiteUrl, '/')"/>
  <xsl:variable name="isMultilingual" select="count(tokenize($languages, ',')) gt 1"/>
  <xsl:variable name="canonicalUrl" as="xs:string"
                select="$siteUrl || (if ($isMultilingual) then $lang || '/' else '') ||
                        (if ($currentPage eq 'index.html') then '' else $currentPage)"/>
  
  <!-- Image dimensions handling -->
  <xsl:variable name="txtDimensions" select="unparsed-text('../utilities/imageDimensions.txt')"/>
  
  <xsl:variable name="mapImgPathsToElements" as="map(xs:string, element(Q{http://www.w3.org/1999/xhtml}img))">
    <xsl:map>
      <xsl:for-each select="distinct-values(tokenize($txtDimensions, '&#x0A;'))">
        <xsl:variable name="bits" as="xs:string*" select="tokenize(., '\s+')"/>
        <xsl:variable name="wh" as="xs:string*" select="if (count($bits) gt 1) then tokenize($bits[2], 'x') else ()"/>
        <xsl:if test="count($bits) = 2 and count($wh) = 2">
          <xsl:map-entry key="$bits[1]">
            <img xmlns="http://www.w3.org/1999/xhtml" src="{$bits[1]}" width="{$wh[1]}" height="{$wh[2]}"/>
          </xsl:map-entry>
        </xsl:if>
      </xsl:for-each>
    </xsl:map>
  </xsl:variable>
  
  <!-- Main template: Process the template document, not the content -->
  <xsl:template match="/">
    <xsl:message select="'Processing ' || $currentPage || (if ($isComplexHomepage) then ' without shared navigation and footer' else '') || '.'"/>
    <xsl:apply-templates select="$template/*"/>
  </xsl:template>
  
  <!-- Add page id based on output filename -->
  <xsl:template match="xhtml:html" priority="3">
    <xsl:variable name="pageId" select="replace($currentPage, '\.html$', '')"/>
    <xsl:element name="html">
      <xsl:copy-of select="@*[not(local-name() = 'id')]"/>
      <xsl:if test="not(@id)">
        <xsl:attribute name="id" select="$pageId"/>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>

  <xd:doc>
    <xd:desc>Skips the shared top area and footer when processing a complex homepage.</xd:desc>
  </xd:doc>
  <xsl:template match="xhtml:div[contains-token(@class, 'top-wrapper')] | xhtml:footer" priority="4">
    <xsl:if test="not($isComplexHomepage)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

  <!-- Replace shared head placeholders with metadata for the current page. -->
  <xsl:template match="xhtml:title" priority="5">
    <xsl:element name="title">
      <xsl:value-of select="if ($pageTitle = '' or $pageTitle = $siteTitle) then $siteTitle else concat($pageTitle, ' | ', $siteTitle)"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="xhtml:meta[@name = 'description']" priority="5">
    <xsl:element name="meta">
      <xsl:attribute name="name">description</xsl:attribute>
      <xsl:attribute name="content" select="$metaDescription"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="xhtml:link[@rel = 'canonical']" priority="5">
    <xsl:element name="link">
      <xsl:attribute name="rel">canonical</xsl:attribute>
      <xsl:attribute name="href" select="$canonicalUrl"/>
    </xsl:element>
  </xsl:template>

  <!-- Convert XHTML-namespaced template elements to HTML5 (no namespace) -->
  <xsl:template match="xhtml:*" priority="2">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="@* | node()"/>
    </xsl:element>
  </xsl:template>

  <!-- Convert XHTML-namespaced content elements to no-namespace HTML in content mode -->
  <xsl:template match="xhtml:*" mode="content" priority="2">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="@* | node()" mode="content"/>
    </xsl:element>
  </xsl:template>

  <!-- Handle SVG elements - preserve SVG namespace -->
  <xsl:template match="*[namespace-uri() = 'http://www.w3.org/2000/svg']" priority="3">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/2000/svg">
      <xsl:apply-templates select="@* | node()"/>
    </xsl:element>
  </xsl:template>

  <!-- Handle SVG elements in content mode - preserve SVG namespace -->
  <xsl:template match="*[namespace-uri() = 'http://www.w3.org/2000/svg']" mode="content" priority="3">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/2000/svg">
      <xsl:apply-templates select="@* | node()" mode="content"/>
    </xsl:element>
  </xsl:template>

  <!-- Identity template for attributes -->
  <xsl:template match="@*" priority="1">
    <xsl:copy/>
  </xsl:template>
  
  <!-- Fix resource paths (CSS, JS, images) for multilingual builds. We do this because the resources are one level up from the HTML pages in bilingual builds. -->
  <xsl:template match="xhtml:link/@href[not(starts-with(., 'http')) and not(starts-with(., '/')) and (contains(., 'css/') or contains(., 'fonts/'))]" priority="3">
    <xsl:attribute name="href">
      <xsl:if test="$isMultilingual">../</xsl:if>
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="xhtml:script/@src[not(starts-with(., 'http')) and not(starts-with(., '/')) and contains(., 'js/')]" priority="3">
    <xsl:attribute name="src">
      <xsl:if test="$isMultilingual">../</xsl:if>
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="xhtml:img/@src[not(starts-with(., 'http')) and not(starts-with(., '/')) and starts-with(., 'images/')]" priority="4">
    <xsl:attribute name="src">
      <xsl:if test="$isMultilingual">../</xsl:if>
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
  
  <!-- Replace <?docContent?> with actual content -->
  <xsl:template match="processing-instruction('docContent')" priority="5">
    <xsl:message>Inserting content for page: <xsl:value-of select="$currentPage"/></xsl:message>
    <xsl:apply-templates select="$contentRoot/*/*" mode="content"/>
  </xsl:template>
  
  <!-- Replace {{currentPage}} placeholders in href attributes -->
  <xsl:template match="@href[contains(., '{{currentPage}}')]" priority="3">
    <xsl:attribute name="href" select="replace(., '\{\{currentPage\}\}', $currentPage)"/>
  </xsl:template>

  <!-- Mark current navigation item as active -->
  <xsl:template match="xhtml:a[contains(concat(' ', normalize-space(@class), ' '), ' item ')][@href]" priority="4">
    <xsl:variable name="targetPage" select="replace(tokenize(string(@href), '[?#]')[1], '^.*/', '')"/>
    <xsl:variable name="isActive" select="$targetPage = $currentPage"/>
    <xsl:element name="a">
      <xsl:copy-of select="@*[not(local-name() = 'class' or local-name() = 'aria-current')]"/>
      <xsl:attribute name="class" select="normalize-space(string-join((string(@class), if ($isActive) then 'active' else ()), ' '))"/>
      <xsl:if test="$isActive">
        <xsl:attribute name="aria-current">page</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>
  
  <!--If the input document has two or more section elements, create a subnav with links to each section-->
  <xsl:template match="xhtml:body" priority="3">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:variable name="sectionNavLabel" select="
        if ($propertiesDoc/site/subnav-aria-label/*[local-name() = $lang]) then
          normalize-space(string($propertiesDoc/site/subnav-aria-label/*[local-name() = $lang]))
        else
          'Section navigation'
                      "/>
      <xsl:variable name="contentNodes" select="$contentRoot/*/*"/>
      <xsl:variable name="sections" as="element()*" select="$contentNodes/descendant-or-self::*[local-name() = 'section']"/>
      <xsl:if test="$currentPage ne 'index.html' and count($sections) &gt;= 2">
        <xsl:message>Creating section navigation with <xsl:value-of select="count($sections)"/> sections</xsl:message>
        <nav class="subnav" aria-label="{$sectionNavLabel}">
          <ul>
            <xsl:for-each select="$sections">
              <xsl:variable name="sectionId" select="@id"/>
              <xsl:variable name="sectionTitle" select="(.//*[matches(local-name(), '^h[1-6]$')])[1]"/>
              <xsl:if test="$sectionId and $sectionTitle">
                <li>
                  <a href="#{$sectionId}">
                    <xsl:value-of select="$sectionTitle"/>
                  </a>
                </li>
              </xsl:if>
            </xsl:for-each>
          </ul>
        </nav>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Process content in content mode (identity transform with image handling) -->
  <xsl:template match="xhtml:* | @*" mode="content" priority="1">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="content"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Handle non-namespaced elements from content files -->
  <xsl:template match="*[not(namespace-uri())]" mode="content" priority="1">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="@* | node()" mode="content"/>
    </xsl:element>
  </xsl:template>
  
  <!-- Handle text nodes -->
  <xsl:template match="text() | comment() | processing-instruction()" mode="content">
    <xsl:copy/>
  </xsl:template>
  
  <!-- Replace img tags with dimensioned versions (for template images) -->
  <xsl:template match="xhtml:img[starts-with(@src, 'images/') or starts-with(@src, '/images/')]" priority="4">
    <xsl:call-template name="add-image-dimensions">
      <xsl:with-param name="img" select="."/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- Replace img tags with dimensioned versions (for content images) -->
  <xsl:template match="xhtml:img[starts-with(@src, 'images/') or starts-with(@src, '/images/')]" mode="content" priority="4">
    <xsl:call-template name="add-image-dimensions">
      <xsl:with-param name="img" select="."/>
    </xsl:call-template>
  </xsl:template>

  <!-- Named template to add image dimensions -->
  <xsl:template name="add-image-dimensions">
    <xsl:param name="img" as="element(xhtml:img)"/>
    
    <!-- Normalize the src path (remove leading slash if present) -->
    <xsl:variable name="normalizedSrc" select="replace($img/@src, '^/', '')"/>
    <xsl:variable name="imgTag" select="map:get($mapImgPathsToElements, $normalizedSrc)" as="element(xhtml:img)*"/>
    
    <xsl:choose>
      <xsl:when test="count($imgTag) > 0">
        <xsl:for-each select="$imgTag">
          <xsl:copy>
            <xsl:copy-of select="@width"/>
            <xsl:copy-of select="@height"/>
            <xsl:variable name="aspectClass">
              <xsl:choose>
                <xsl:when test="number(@width) = number(@height)">
                  <xsl:value-of select="'square'"/>
                </xsl:when>
                <xsl:when test="number(@width) &gt; number(@height)">
                  <xsl:value-of select="'landscape'"/>
                </xsl:when>
                <xsl:when test="number(@width) &lt; number(@height)">
                  <xsl:value-of select="'portrait'"/>
                </xsl:when>
              </xsl:choose>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$img/@class">
                <xsl:attribute name="class" select="normalize-space(string-join(($img/@class, $aspectClass), ' '))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="class" select="$aspectClass"/>
              </xsl:otherwise>
            </xsl:choose>
            <!-- Fix src path for multilingual builds -->
            <xsl:attribute name="src">
              <xsl:if test="$isMultilingual">../</xsl:if>
              <xsl:value-of select="@src"/>
            </xsl:attribute>
            <xsl:copy-of select="$img/@*[not(local-name() = 'width' or local-name() = 'height' or local-name() = 'class' or local-name() = 'src')]"/>
          </xsl:copy>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Warning: No dimensions found for <xsl:value-of select="$img/@src"/></xsl:message>
        <xsl:copy>
          <xsl:apply-templates select="$img/@* | $img/node()" mode="#current"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
