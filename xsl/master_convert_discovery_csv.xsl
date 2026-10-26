<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:hcmc="http://hcmc.uvic.ca/ns"
  xpath-default-namespace="" exclude-result-prefixes="#all" version="3.0">
  <xd:doc xsl:use-when="false()" scope="stylesheet">
    <xd:desc>Converts discovery CSV records to XML, retaining unpublished records and source fields.</xd:desc>
    <xd:p><xd:b>Created on:</xd:b> 2026-10-02</xd:p>
    <xd:p><xd:b>Author:</xd:b> inokhrin</xd:p>
  </xd:doc>

  <!--**************************************************************
       *                                                            *
       *                         Output                             *
       *                                                            *
       **************************************************************-->
  <xsl:output method="xml" encoding="UTF-8" normalization-form="NFC" indent="yes" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                          Modes                             *
       *                                                            *
       **************************************************************-->
  <xsl:mode on-no-match="shallow-skip" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                        Parameters                          *
       *                                                            *
       **************************************************************-->
  <xsl:param name="csvUri" as="xs:string" select="let $properties := doc(resolve-uri('../properties.xml', static-base-uri())) return resolve-uri(normalize-space($properties/site/files/dataFile), base-uri($properties))"/>

  <!--**************************************************************
       *                                                            *
       *                         Templates                          *
       *                                                            *
       **************************************************************-->
  <xd:doc>
    <xd:desc>Parses, validates, and writes all source records with publication eligibility.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:message select="'Converting discovery CSV: ' || $csvUri"/>
    <xsl:variable name="rows" as="element(row)*" select="hcmc:parseCsv(unparsed-text($csvUri, 'UTF-8'))"/>
    <xsl:variable name="headers" as="xs:string*" select="$rows[1]/field ! normalize-space(.)"/>
    <xsl:variable name="requiredHeaders" as="xs:string*" select="('Number', 'Asset Name', 'Priority Level', 'Category', 'Current URL', 'Notes')"/>
    <xsl:if test="not(every $header in $requiredHeaders satisfies $header = $headers)">
      <xsl:message terminate="yes" select="'CSV: PROBLEM: Missing required columns: ' || string-join($requiredHeaders[not(. = $headers)], ', ')"/>
    </xsl:if>
    <xsl:if test="count($headers[. ne '']) ne count(distinct-values($headers[. ne '']))">
      <xsl:message terminate="yes">CSV: PROBLEM: Duplicate named column headings.</xsl:message>
    </xsl:if>
    <xsl:for-each-group select="$rows[position() gt 1]" group-by="normalize-space(hcmc:csvField(., $headers, 'Number'))">
      <xsl:if test="current-grouping-key() ne '' and count(current-group()) gt 1">
        <xsl:message terminate="yes" select="current-grouping-key() || ': PROBLEM: Duplicate Number; item identifiers must be unique.'"/>
      </xsl:if>
    </xsl:for-each-group>
    <items>
      <xsl:for-each select="$rows[position() gt 1]">
        <xsl:variable name="number" as="xs:string" select="normalize-space(hcmc:csvField(., $headers, 'Number'))"/>
        <xsl:variable name="title" as="xs:string" select="normalize-space(hcmc:csvField(., $headers, 'Asset Name'))"/>
        <xsl:variable name="priority" as="xs:string" select="normalize-space(hcmc:csvField(., $headers, 'Priority Level'))"/>
        <xsl:variable name="category" as="xs:string" select="normalize-space(hcmc:csvField(., $headers, 'Category'))"/>
        <xsl:variable name="rawUrl" as="xs:string" select="normalize-space(hcmc:csvField(., $headers, 'Current URL'))"/>
        <xsl:variable name="url" as="xs:string" select="hcmc:discoveryUrl($rawUrl)"/>
        <xsl:variable name="issues" as="xs:string*" select="(
          if (not(matches($number, '^[1-9][0-9]*$'))) then 'Number must be a positive integer' else (),
          if ($title eq '') then 'Asset Name is missing' else (),
          if (not($priority = ('1', '2', '3', '4'))) then 'Priority Level must be 1–4' else (),
          if ($category eq '') then 'Category is missing' else (),
          if (count(field) ne count($headers)) then 'row has ' || count(field) || ' fields; expected ' || count($headers) else ())"/>
        <xd:doc xsl:use-when="false()" scope="component"><xd:desc>An identifier for warnings, even when Number is absent.</xd:desc></xd:doc>
        <xsl:variable name="label" as="xs:string" select="if ($number ne '') then $number else 'row ' || (position() + 1)"/>
        <xsl:for-each select="$issues">
          <xsl:message select="$label || ': PROBLEM: ' || . || '; card omitted.'"/>
        </xsl:for-each>
        <xsl:if test="$url ne '' and $url ne $rawUrl">
          <xsl:message select="$label || ': URL is OK. Extracted ' || $url || ' from Current URL.'"/>
        </xsl:if>
        <xsl:if test="empty($issues) and $url eq ''">
          <xsl:message select="$label || ': PROBLEM: No usable HTTP(S) URL; card will display Link unavailable.'"/>
        </xsl:if>
        <item row="{position() + 1}" number="{$number}" priority="{$priority}" category="{$category}" eligible="{empty($issues)}">
          <xsl:if test="matches($number, '^[1-9][0-9]*$')"><xsl:attribute name="id" select="'item-' || $number"/></xsl:if>
          <title><xsl:sequence select="$title"/></title>
          <url><xsl:sequence select="$url"/></url>
          <image src="{normalize-space(hcmc:csvField(., $headers, 'Image'))}" alt="{hcmc:csvField(., $headers, 'Image Alt')}"/>
          <source>
            <xsl:for-each select="field">
              <xd:doc xsl:use-when="false()" scope="component"><xd:desc>The source column position.</xd:desc></xd:doc>
              <xsl:variable name="column" as="xs:integer" select="position()"/>
              <field name="{$headers[$column]}" column="{$column}"><xsl:sequence select="string(.)"/></field>
            </xsl:for-each>
          </source>
          <xsl:for-each select="$issues"><issue><xsl:sequence select="."/></issue></xsl:for-each>
        </item>
      </xsl:for-each>
    </items>
  </xsl:template>

  <!--**************************************************************
       *                                                            *
       *                         Functions                          *
       *                                                            *
       **************************************************************-->
  <!--*** FUNCTIONS INCLUDED HERE ARE NOT SHARED WITH OTHER PROCESSES. ***-->
  <xd:doc>
    <xd:desc>Reads a named CSV column; optional absent columns return an empty string.</xd:desc>
  </xd:doc>
  <xsl:function name="hcmc:csvField" as="xs:string">
    <xd:doc xsl:use-when="false()"><xd:desc>The row to inspect.</xd:desc></xd:doc><xsl:param name="row" as="element(row)"/>
    <xd:doc xsl:use-when="false()"><xd:desc>The column headings.</xd:desc></xd:doc><xsl:param name="headers" as="xs:string*"/>
    <xd:doc xsl:use-when="false()"><xd:desc>The requested column.</xd:desc></xd:doc><xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="string($row/field[index-of($headers, $name)])"/>
  </xsl:function>

  <xd:doc xsl:use-when="false()">
    <xd:desc>Accepts HTTP(S) destinations, including a single URL with an editorial prefix.</xd:desc>
  </xd:doc>
  <xsl:function name="hcmc:discoveryUrl" as="xs:string">
    <xd:doc xsl:use-when="false()"><xd:desc>The original destination field.</xd:desc></xd:doc><xsl:param name="value" as="xs:string"/>
    <xd:doc xsl:use-when="false()" scope="component"><xd:desc>HTTP(S) tokens found in the field.</xd:desc></xd:doc>
    <xsl:variable name="urls" as="xs:string*" select="tokenize($value, '\s+')[matches(., '^https?://[^/\s?#]+[^\s]*$', 'i')]"/>
    <xsl:sequence select="if (count($urls) eq 1 and ($urls[1] eq $value or starts-with($value, 'Various URLS:'))) then $urls[1] else ''"/>
  </xsl:function>

  <xd:doc xsl:use-when="false()">
    <xd:desc>Parses CSV character by character, preserving quoted field delimiters and newlines.</xd:desc>
  </xd:doc>
  <xsl:function name="hcmc:parseCsv" as="element(row)*">
    <xsl:param name="text" as="xs:string"/>
    <xsl:variable name="csv" as="xs:string" select="replace(if (starts-with($text, codepoints-to-string(65279))) then substring($text, 2) else $text, '\r\n?', '&#10;')"/>
    <xsl:iterate select="string-to-codepoints($csv)">
      <xsl:param name="state" as="xs:string" select="'start'"/>
      <xsl:param name="chars" as="xs:string*" select="()"/>
      <xsl:param name="fields" as="element(field)*" select="()"/>
      <xsl:on-completion>
        <xsl:if test="$state eq 'quoted'"><xsl:sequence select="error(QName('http://hcmc.uvic.ca/ns', 'hcmc:malformedCsv'), 'CSV: PROBLEM: Unterminated quoted field.')"/></xsl:if>
        <xsl:if test="exists($fields) or $state ne 'start'"><row><xsl:sequence select="$fields"/><field><xsl:sequence select="string-join($chars)"/></field></row></xsl:if>
      </xsl:on-completion>
      <xsl:variable name="char" as="xs:string" select="codepoints-to-string(.)"/>
      <xsl:choose>
        <xsl:when test=". eq 34">
          <xsl:if test="$state eq 'bare'"><xsl:sequence select="error(QName('http://hcmc.uvic.ca/ns', 'hcmc:malformedCsv'), 'CSV: PROBLEM: Quote inside an unquoted field at character ' || position() || '.')"/></xsl:if>
          <xsl:next-iteration>
            <xsl:with-param name="state" as="xs:string" select="if ($state eq 'quoted') then 'afterQuote' else 'quoted'"/>
            <xsl:with-param name="chars" as="xs:string*" select="if ($state eq 'afterQuote') then ($chars, $char) else $chars"/>
          </xsl:next-iteration>
        </xsl:when>
        <xsl:when test="$state ne 'quoted' and . = (44, 10)">
          <xsl:variable name="field" as="element(field)"><field><xsl:sequence select="string-join($chars)"/></field></xsl:variable>
          <xsl:if test=". eq 10 and (exists($fields) or $state ne 'start')"><row><xsl:sequence select="($fields, $field)"/></row></xsl:if>
          <xsl:next-iteration>
            <xsl:with-param name="state" as="xs:string" select="'start'"/>
            <xsl:with-param name="chars" as="xs:string*" select="()"/>
            <xsl:with-param name="fields" as="element(field)*" select="if (. eq 44) then ($fields, $field) else ()"/>
          </xsl:next-iteration>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="$state eq 'afterQuote'"><xsl:sequence select="error(QName('http://hcmc.uvic.ca/ns', 'hcmc:malformedCsv'), 'CSV: PROBLEM: Unexpected text after a closing quote at character ' || position() || '.')"/></xsl:if>
          <xsl:next-iteration>
            <xsl:with-param name="state" as="xs:string" select="if ($state eq 'quoted') then 'quoted' else 'bare'"/>
            <xsl:with-param name="chars" as="xs:string*" select="($chars, $char)"/>
          </xsl:next-iteration>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:iterate>
  </xsl:function>
</xsl:stylesheet>
