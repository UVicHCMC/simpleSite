<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xpath-default-namespace="" exclude-result-prefixes="#all" version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>Generates editable XML source pages for each eligible discovery category.</xd:desc>
    <xd:p><xd:b>Created on:</xd:b> 2026-10-22</xd:p>
    <xd:p><xd:b>Author:</xd:b> inokhrin</xd:p>
  </xd:doc>
  <xsl:output method="xml" encoding="UTF-8" normalization-form="NFC" indent="yes" exclude-result-prefixes="#all"/>
  <xsl:mode on-no-match="shallow-skip" exclude-result-prefixes="#all"/>
  <xsl:param name="outputDir" as="xs:string" select="'content/generated'"/>
  <xsl:template match="/">
    <xsl:message>Generating category page XML sources.</xsl:message>
    <xsl:variable name="categories" as="xs:string*" select="sort(distinct-values(/items/item[@eligible eq 'true']/@category ! string(.)))"/>
    <xsl:variable name="filenames" as="xs:string*" select="$categories ! ('category-' || replace(lower-case(replace(normalize-space(.), '[^A-Za-z0-9]+', '-')), '(^-+|-+$)', '') || '.xml')"/>
    <xsl:if test="some $filename in $filenames satisfies $filename eq 'category-.xml'">
      <xsl:message terminate="yes">Categories: PROBLEM: A category produced an empty filename.</xsl:message>
    </xsl:if>
    <xsl:if test="count($filenames) ne count(distinct-values($filenames))">
      <xsl:message terminate="yes">Categories: PROBLEM: Category labels collide after filename normalization.</xsl:message>
    </xsl:if>
    <xsl:for-each select="$categories">
      <xsl:variable name="category" as="xs:string" select="."/>
      <xsl:variable name="filename" as="xs:string" select="'category-' || replace(lower-case(replace(normalize-space($category), '[^A-Za-z0-9]+', '-')), '(^-+|-+$)', '') || '.xml'"/>
      <xsl:result-document href="{$outputDir || '/' || $filename}" method="xml" encoding="UTF-8" normalization-form="NFC" indent="yes" exclude-result-prefixes="#all">
        <div xmlns="http://www.w3.org/1999/xhtml" id="root" data-category="{$category}" data-page-title="{$category}" data-meta-description="Explore {$category} resources in the Landscapes of Injustice and Past Wrongs Future Choices collection.">
          <h1><xsl:value-of select="$category"/></h1>
          <xsl:processing-instruction name="discoveryCards"/>
        </div>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
