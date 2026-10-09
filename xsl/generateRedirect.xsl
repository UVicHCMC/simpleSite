<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:hcmc="http://hcmc.uvic.ca/ns"
                xmlns="http://www.w3.org/1999/xhtml"
                xpath-default-namespace=""
                exclude-result-prefixes="#all" version="3.0">
  <!-- Create the root redirect for multilingual sites without a language selector.
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
  <xsl:mode on-no-match="shallow-skip" exclude-result-prefixes="#all"/>

  <!--**************************************************************
       *                                                            *
       *                      Parameters                            *
       *                                                            *
       **************************************************************-->
  <!-- The default language chosen by the build. -->
  <xsl:param name="defaultLang" as="xs:string" select="'en'"/>

  <!--**************************************************************
       *                                                            *
       *                        Templates                           *
       *                                                            *
       **************************************************************-->
  <!-- Emit a redirect with a visible link for browsers that do not follow refresh metadata. -->
  <xsl:template match="/">
    <xsl:message>Creating root redirect to <xsl:value-of select="$defaultLang"/>/index.html.</xsl:message>
    <html lang="{$defaultLang}">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <meta http-equiv="refresh" content="{'0; url=' || $defaultLang || '/index.html'}"/>
        <title><xsl:value-of select="(site/metadata/siteTitle/*[local-name() eq $defaultLang], site/metadata/siteTitle)[1]"/></title>
      </head>
      <body>
        <p><a href="{$defaultLang || '/index.html'}">Continue to the site</a></p>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
