<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xh="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all" version="3.0">

    <xd:doc scope="stylesheet">
        <xd:p><xd:b>Created on:</xd:b> 2026-11-04</xd:p>
        <xd:p><xd:b>Author:</xd:b> inokhrin</xd:p>
        <xd:p>Comments out past calendar events using a Vancouver
            timestamp supplied by ant and replaces the XML file only when this transform results in an updated file.</xd:p>
    </xd:doc>

    <xsl:output method="xml" encoding="UTF-8" normalization-form="NFC" indent="yes"
        suppress-indentation="xh:div" exclude-result-prefixes="#all"/>

    <xsl:mode on-no-match="shallow-copy" exclude-result-prefixes="#all"/>

    <xsl:param name="buildDateTime" as="xs:dateTime" required="yes"/>
    <xsl:param name="archiveUri" as="xs:string" required="yes"/>
    <xsl:variable name="pastEvents" as="element(li)*"
        select="//ol[contains-token(@class, 'calendar-events-list')]/li
            [hcmc:eventHasPassed(string((.//time[@datetime]/@datetime)[1]), $buildDateTime)]"/>


    <!-- Writes an updated calendar only when there are events to archive. -->  
    <xsl:template match="/">
        <xsl:message select="'Checking calendar events in ' || base-uri(.) ||
            ' at ' || $buildDateTime || ': ' || count($pastEvents) || ' past event(s).'"/>
        <xsl:if test="exists($pastEvents)">
            <xsl:result-document href="{$archiveUri}" exclude-result-prefixes="#all">
                <xsl:apply-templates/>
            </xsl:result-document>
        </xsl:if>
    </xsl:template>

    <!-- Retains each expired li in a comment -->
    <xsl:template match="ol[contains-token(@class, 'calendar-events-list')]/li">
        <xsl:choose>
            <xsl:when test="exists(. intersect $pastEvents)">
                <xsl:variable name="eventXml" as="xs:string"
                    select="serialize(., map{'method': 'xml', 'omit-xml-declaration': true(), 'indent': false()})"/>
                <!-- XML comments cannot contain nested comments or double hyphens. -->
                <xsl:if test="contains($eventXml, '--')">
                    <xsl:message terminate="yes" select="string((.//@aria-labelledby, @id)[1]) ||
                        ': PROBLEM: Cannot archive an event containing comments or double hyphens. ' ||
                        'The calendar source has not been replaced.'"/>
                </xsl:if>
                <xsl:comment select="$eventXml"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xd:doc>
        <xd:desc>Uses the build's local date for date-only events and its timezone for
            datetimes without an explicit offset. Unrecognized values remain active.</xd:desc>
        <xd:param name="datetime">The event's datetime attribute.</xd:param>
        <xd:param name="reference">The build timestamp, including its timezone.</xd:param>
        <xd:return>Whether the event's date or instant precedes the build.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:eventHasPassed" as="xs:boolean">
        <xsl:param name="datetime" as="xs:string"/>
        <xsl:param name="reference" as="xs:dateTime"/>
        <xsl:choose>
            <xsl:when test="$datetime castable as xs:date">
                <xsl:sequence select="adjust-date-to-timezone(xs:date($datetime), ()) lt
                    adjust-date-to-timezone(xs:date($reference), ())"/>
            </xsl:when>
            <xsl:when test="$datetime castable as xs:dateTime">
                <xsl:sequence select="adjust-dateTime-to-timezone(xs:dateTime($datetime),
                    timezone-from-dateTime($reference)) lt $reference"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'calendar: PROBLEM: Unrecognized event datetime &quot;' ||
                    $datetime || '&quot;; leaving the event active.'"/>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>
