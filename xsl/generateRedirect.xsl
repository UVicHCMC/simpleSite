<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:hcmc="http://hcmc.uvic.ca/ns"
                xmlns="http://www.w3.org/1999/xhtml"
                xpath-default-namespace=""
                exclude-result-prefixes="#all"
                version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>Creates the root redirect for a multilingual site without a language selector.</xd:desc>
    <xd:p><xd:b>Created on:</xd:b> 2026-09-29</xd:p>
    <xd:p><xd:b>Author:</xd:b> HCMC</xd:p>
  </xd:doc>

  <!--**************************************************************
       *                                                            *
       *                         Output                             *
       *                                                            *
       **************************************************************-->
  <xsl:output method="xhtml" html-version="5" encoding="UTF-8"
              normalization-form="NFC" indent="yes"
              exclude-result-prefixes="#all" omit-xml-declaration="yes"
              include-content-type="no"/>

  <!--**************************************************************
       *                                                            *
       *                        Parameters                          *
       *                                                            *
       **************************************************************-->
  <xd:doc>
    <xd:desc>The configured default language code.</xd:desc>
  </xd:doc>
  <xsl:param name="defaultLang" as="xs:string" select="'en'"/>

  <!--**************************************************************
       *                                                            *
       *                        Variables                           *
       *                                                            *
       **************************************************************-->
  <xd:doc scope="component">
    <xd:desc>The relative address of the default-language homepage.</xd:desc>
  </xd:doc>
  <xsl:variable name="targetUrl" as="xs:string" select="$defaultLang || '/index.html'"/>

  <!--**************************************************************
       *                                                            *
       *                        Templates                           *
       *                                                            *
       **************************************************************-->
  <xd:doc>
    <xd:desc>Writes a redirect with an accessible fallback link.</xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:message select="'Creating root redirect to ' || $targetUrl || '.'"/>
    <html lang="{$defaultLang}">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta http-equiv="refresh" content="0;url={$targetUrl}"/>
        <title>Continue to the site</title>
      </head>
      <body>
        <main>
          <p><a href="{$targetUrl}">Continue to the site</a></p>
        </main>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
