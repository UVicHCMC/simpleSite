<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all" xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:hcmc="http://hcmc.uvic.ca/ns" version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> March 5, 2018</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b>
                <xd:a href="mol:HOLM3">mholmes</xd:a>
            </xd:p>
            <xd:p>Creates a sitemap file for Google Search.</xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:output method="xml" indent="yes" encoding="UTF-8" normalization-form="NFC"/>

    <!-- Keep sitemap and canonical URLs aligned with the project metadata. -->
    <xsl:variable name="propertiesDoc" as="document-node()"
        select="document(resolve-uri('../properties.xml', static-base-uri()))"/>

    <xd:doc>
        <xd:desc>The public base URL for the deployed site, sourced from properties.xml.</xd:desc>
    </xd:doc>
    <xsl:param name="siteUrl" as="xs:string"
        select="normalize-space(string($propertiesDoc/*[local-name() = 'site']/*[local-name() = 'metadata']/*[local-name() = 'siteUrl']))"/>

    <xsl:variable name="normalizedSiteUrl" as="xs:string"
        select="if (ends-with($siteUrl, '/')) then $siteUrl else concat($siteUrl, '/')"/>

    <xd:doc>
        <xd:desc>The relative directory containing generated site HTML files.</xd:desc>
    </xd:doc>
    <xsl:param name="outputDir" as="xs:string" select="'site'"/>

    <xsl:template match="/">
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            <xsl:for-each select="uri-collection(concat('../', $outputDir, '/?select=*.html;recurse=yes'))">
                <xsl:sort select="."/>
                <xsl:variable name="relativePath" as="xs:string"
                    select="substring-after(string(.), '/site/')"/>
                <!-- Publish directory indexes at their clean canonical URLs. -->
                <xsl:variable name="canonicalPath" as="xs:string"
                    select="replace($relativePath, '(^|/)index\.html$', '$1')"/>
                <url>
                    <loc>
                        <xsl:value-of select="concat($normalizedSiteUrl, $canonicalPath)"/>
                    </loc>
                </url>
            </xsl:for-each>
        </urlset>
        <xsl:call-template name="robotsTxt"/>
    </xsl:template>

    <xd:doc>
        <xd:desc>Create a robots.txt file which points at the sitemap.</xd:desc>
    </xd:doc>
    <xsl:template name="robotsTxt">
        <xsl:result-document method="text" href="robots.txt" indent="no"
            encoding="UTF-8">
            <xsl:text>Sitemap: </xsl:text>
            <xsl:value-of select="concat($normalizedSiteUrl, 'sitemap.xml')"/>
            <xsl:text>&#x0a;</xsl:text>
        </xsl:result-document>
    </xsl:template>


</xsl:stylesheet>
