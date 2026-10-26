<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:hcmc="http://hcmc.uvic.ca/ns"
  xpath-default-namespace="" exclude-result-prefixes="#all" version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>Renders eligible discovery records as priority-grouped cards on the index and category pages.</xd:desc>
    <xd:p><xd:b>Created on:</xd:b> 2026-10-22</xd:p>
    <xd:p><xd:b>Author:</xd:b> inokhrin</xd:p>
  </xd:doc>

  <xsl:output method="html" html-version="5" encoding="UTF-8" normalization-form="NFC" indent="yes" omit-xml-declaration="yes" include-content-type="no" exclude-result-prefixes="#all"/>
  <xsl:mode name="content" on-no-match="shallow-copy" exclude-result-prefixes="#all"/>

  <xd:doc><xd:desc>The generated XML catalogue URI.</xd:desc></xd:doc>
  <xsl:param name="discoveryDataUri" as="xs:string" select="resolve-uri('../data/items.xml', static-base-uri())"/>
  <xd:doc><xd:desc>An optional category override used by isolated rendering.</xd:desc></xd:doc>
  <xsl:param name="category" as="xs:string" select="''"/>

  <xd:doc>
    <xd:desc>Renders all eligible cards, or exact category matches for a category page.</xd:desc>
  </xd:doc>
  <xsl:template match="processing-instruction('discoveryCards')" mode="content" priority="5">
    <xsl:message>Rendering discovery cards.</xsl:message>
    <xsl:variable name="allItems" as="element(item)*" select="doc($discoveryDataUri)/items/item[@eligible eq 'true']"/>
    <xsl:variable name="pageCategory" as="xs:string" select="if ($category ne '') then $category else string(ancestor::*[@data-category][1]/@data-category)"/>
    <xsl:variable name="items" as="element(item)*" select="$allItems[if ($pageCategory eq '') then true() else @category eq $pageCategory]"/>
    <div class="discovery-catalogue">
      <div class="category-blurb">
        <xsl:if test="$pageCategory ne ''">
          <xsl:variable name="categorySlug" as="xs:string" select="replace(lower-case(replace(normalize-space($pageCategory), '[^A-Za-z0-9]+', '-')), '(^-+|-+$)', '')"/>
          <xsl:value-of select="doc(resolve-uri('../properties.xml', static-base-uri()))/site/categoryBlurbs/*[local-name() eq $categorySlug]"/>
        </xsl:if>
      </div>
      <xsl:if test="$pageCategory ne ''"><p class="discovery-item-count"><xsl:sequence select="count($items) || (if (count($items) eq 1) then ' item' else ' items')"/></p></xsl:if>
      <div class="discovery-results">
        <xsl:for-each-group select="$items" group-by="@priority">
          <xsl:sort select="xs:integer(current-grouping-key())"/>
          <ul class="discovery-tier" data-priority="{current-grouping-key()}">
            <xsl:for-each select="current-group()">
              <li class="discovery-card" id="{@id}" data-category="{@category}">
                <article aria-labelledby="{@id}-title">
                  <p class="discovery-card-category"><a href="category-{replace(lower-case(replace(normalize-space(@category), '[^A-Za-z0-9]+', '-')), '(^-+|-+$)', '')}.html"><xsl:sequence select="string(@category)"/></a></p>
                  <h3 id="{@id}-title">
                    <xsl:choose>
                      <xsl:when test="url ne ''"><a href="{url}"><xsl:sequence select="string(title)"/></a></xsl:when>
                      <xsl:otherwise><xsl:sequence select="string(title)"/></xsl:otherwise>
                    </xsl:choose>
                  </h3>
                  <xsl:if test="@priority eq '1' and image/@src ne ''">
                    <xsl:variable name="image" as="element(xh:img)">
                      <xh:img class="discovery-card-image" src="{image/@src}" alt="{image/@alt}" loading="lazy" decoding="async"/>
                    </xsl:variable>
                    <xsl:apply-templates select="$image" mode="content"/>
                  </xsl:if>
                  <!--<xsl:if test="url eq ''"><p class="discovery-link-unavailable">Link unavailable</p></xsl:if>
                  <p class="discovery-category-action"><a href="category-{replace(lower-case(replace(normalize-space(@category), '[^A-Za-z0-9]+', '-')), '(^-+|-+$)', '')}.html">See all items in this category</a></p>-->
                </article>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:for-each-group>
      </div>
    </div>
  </xsl:template>
</xsl:stylesheet>
