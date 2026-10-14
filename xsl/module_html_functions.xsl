<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
                xmlns:hcmc="http://hcmc.uvic.ca/ns"
                xmlns:xh="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/1999/xhtml"
                xpath-default-namespace="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="#all" version="3.0">
  <xd:doc scope="stylesheet">
    <xd:p><xd:b>Created on:</xd:b> 2026-10-09</xd:p>
    <xd:p><xd:b>Author:</xd:b> inokhrin</xd:p>
    <xd:desc>Build-time event and newsletter cards for processContent.xsl, using its
      <xd:ref name="contentRoot" type="variable">contentRoot</xd:ref> and
      <xd:ref name="isMultilingual" type="variable">isMultilingual</xd:ref> variables
      and its declared content mode.</xd:desc>
  </xd:doc>

  <xsl:param name="buildDateTime" as="xs:dateTime" select="current-dateTime()"/>

  <xsl:variable name="calendarEvents" as="element(xh:article)*"
                select="doc(resolve-uri('calendar.xml', base-uri($contentRoot)))//article
                        [tokenize(normalize-space(@class), '\s+') = 'calendar-event']"/>
  <xsl:variable name="forthcomingEvents" as="element(xh:article)*">
    <xsl:perform-sort select="$calendarEvents[
                        if (string((.//time/@datetime)[1]) castable as xs:date)
                        then xs:date(hcmc:eventStart(.)) ge xs:date($buildDateTime)
                        else hcmc:eventStart(.) gt $buildDateTime]">
      <xsl:sort select="hcmc:eventStart(.)"/>
    </xsl:perform-sort>
  </xsl:variable>

  <xsl:variable name="newsletterUris" as="xs:anyURI*"
                select="uri-collection(resolve-uri('../pdf/newsletters/', static-base-uri()) ||
                        '?select=*.[pP][dD][fF];recurse=no')"/>

  <xsl:variable name="sortedNewsletters" as="xs:anyURI*">
    <xsl:perform-sort select="$newsletterUris">
      <xsl:sort select="hcmc:newsletterDate(.)" order="descending"/>
      <xsl:sort select="lower-case(string(.))"/>
    </xsl:perform-sort>
  </xsl:variable>

  <xsl:variable name="currentNewsletter" as="xs:anyURI?"
                select="$sortedNewsletters[exists(hcmc:newsletterDate(.))][1]"/>
  <xsl:variable name="archivedNewsletters" as="xs:anyURI*"
                select="$sortedNewsletters[not(. = $currentNewsletter)]"/>

  <xd:doc>
    <xd:desc>We retain the authored event section and add display-none when no forthcoming
      events remain. All surrounding homepage content is processed normally.</xd:desc>
  </xd:doc>
  <xsl:template match="section[.//processing-instruction('upcomingEvents')]" mode="content">
    <xsl:message>Selecting the next forthcoming calendar event at <xsl:value-of select="$buildDateTime"/>:
      <xsl:value-of select="count($forthcomingEvents[1])"/> card(s).</xsl:message>
    <xsl:copy>
      <xsl:sequence select="@*[local-name() ne 'class']"/>
      <xsl:attribute name="class" select="string-join((
        tokenize(normalize-space(@class), '\s+')[. ne 'display-none'],
        if (empty($forthcomingEvents)) then 'display-none' else ()), ' ')"/>
      <xsl:apply-templates select="node()" mode="content"/>
    </xsl:copy>
  </xsl:template>

  <xd:doc>
    <xd:desc>We insert only the earliest forthcoming event, if any exist.</xd:desc>
  </xd:doc>
  <xsl:template match="processing-instruction('upcomingEvents')" mode="content">
    <xsl:apply-templates select="$forthcomingEvents[1]" mode="content"/>
  </xsl:template>

  <xd:doc>
    <xd:desc>We generate the current newspaper issue and an expandable archive of past issues. The subscription card
      is taken from resources.xml. If no date in filename, order alphabetically.</xd:desc>
  </xd:doc>
  <xsl:template match="processing-instruction('newsletterCards')" mode="content">
    <xsl:message>Generating newsletter and archive cards from
      <xsl:value-of select="count($newsletterUris)"/> PDF(s) in pdf/newsletters/.</xsl:message>
    <article class="publication-card" aria-labelledby="newsletter-current-issue">
      <h3 id="newsletter-current-issue">Newsletter</h3>
      <xsl:choose>
        <xsl:when test="exists($currentNewsletter)">
          <p><xsl:value-of select="hcmc:newsletterTitle($currentNewsletter)"/></p>
          <a class="publication-link" href="{hcmc:newsletterUrl($currentNewsletter)}"
             type="application/pdf">Download newsletter</a>
        </xsl:when>
        <xsl:otherwise>
          <p>No current newsletter is available yet.</p>
        </xsl:otherwise>
      </xsl:choose>
    </article>
    <article class="publication-card" aria-labelledby="newsletter-archive-heading">
      <h3 id="newsletter-archive-heading">Newsletter Archive</h3>
      <xsl:choose>
        <xsl:when test="exists($archivedNewsletters)">
          <details class="newsletter-archive">
            <summary>Choose a newsletter</summary>
            <ul>
              <xsl:for-each select="$archivedNewsletters">
                <li>
                  <a href="{hcmc:newsletterUrl(.)}" type="application/pdf">
                    <xsl:value-of select="hcmc:newsletterTitle(.)"/>
                  </a>
                </li>
              </xsl:for-each>
            </ul>
          </details>
        </xsl:when>
        <xsl:otherwise>
          <p>No archived newsletters yet.</p>
        </xsl:otherwise>
      </xsl:choose>
    </article>
  </xsl:template>

  <xd:doc>
    <xd:desc>Function to get a calendar card's machine-readable date. Malformed or missing dates stop the build with the card identifier.</xd:desc>
    <xd:param name="event">The calendar event article.</xd:param>
    <xd:return>The event start as an xs:dateTime.</xd:return>
  </xd:doc>
  <xsl:function name="hcmc:eventStart" as="xs:dateTime">
    <xsl:param name="event" as="element(xh:article)"/>
    <xsl:variable name="value" as="xs:string" select="string(($event//time/@datetime)[1])"/>
    <xsl:variable name="start" as="xs:dateTime"
                  select="if ($value castable as xs:dateTime) then xs:dateTime($value)
                          else if ($value castable as xs:date) then dateTime(xs:date($value), xs:time('00:00:00'))
                          else error(QName('http://hcmc.uvic.ca/ns', 'invalidEventDate'),
                            string($event/@aria-labelledby) || ': PROBLEM: Invalid or missing event datetime: ' || $value)"/>
    <xsl:sequence select="if (exists(timezone-from-dateTime($start))) then $start
                          else adjust-dateTime-to-timezone($start, timezone-from-dateTime($buildDateTime))"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Function to extract a date from the established CHCNewsletter_MonthYYYY.pdf filename
      convention, using the first day of the named month.</xd:desc>
    <xd:param name="uri">The newsletter PDF URI.</xd:param>
    <xd:return>The issue date, or an empty sequence for filenames outside that convention.</xd:return>
  </xd:doc>
  <xsl:function name="hcmc:newsletterDate" as="xs:date?">
    <xsl:param name="uri" as="xs:anyURI"/>
    <xsl:variable name="filename" as="xs:string" select="tokenize(string($uri), '/')[last()]"/>
    <xsl:variable name="pattern" as="xs:string" select="'^CHCNewsletter_([A-Za-z]+)([0-9]{4})\.pdf$'"/>
    <xsl:variable name="month" as="xs:integer?" select="index-of(
      ('january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september',
       'october', 'november', 'december'), lower-case(replace($filename, $pattern, '$1', 'i')))"/>
    <xsl:variable name="date" as="xs:string" select="replace($filename, $pattern, '$2', 'i') || '-' ||
                  (if (exists($month)) then format-integer($month, '00') else '00') || '-01'"/>
    <xsl:sequence select="if (matches($filename, $pattern, 'i') and $date castable as xs:date)
                          then xs:date($date) else ()"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Function to construct a download URL for newsletter PDFs.</xd:desc>
    <xd:param name="uri">The discovered PDF URI.</xd:param>
    <xd:return>The relative newsletter PDF URL.</xd:return>
  </xd:doc>
  <xsl:function name="hcmc:newsletterUrl" as="xs:string">
    <xsl:param name="uri" as="xs:anyURI"/>
    <xsl:sequence select="(if ($isMultilingual) then '../' else '') || 'pdf/newsletters/' ||
                          tokenize(string($uri), '/')[last()]"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Function to create a Month YYYY issue title for newsletter PDFs.</xd:desc>
    <xd:param name="uri">The newsletter PDF URI.</xd:param>
    <xd:return>The card's human-readable title.</xd:return>
  </xd:doc>
  <xsl:function name="hcmc:newsletterTitle" as="xs:string">
    <xsl:param name="uri" as="xs:anyURI"/>
    <xsl:variable name="date" as="xs:date?" select="hcmc:newsletterDate($uri)"/>
    <xsl:sequence select="if (exists($date)) then format-date($date, '[MNn] [Y]', 'en', (), ())
                          else replace(replace(replace(tokenize(string($uri), '/')[last()],
                               '\.[pP][dD][fF]$', ''), '^CHCNewsletter_', ''), '[_-]|%20', ' ')"/>
  </xsl:function>
</xsl:stylesheet>
