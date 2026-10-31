<?xml version="1.0" encoding="UTF-8"?>
<!--
  Navigator pages, generated from XML/site.xml.

  Without the $year parameter: the Home page — the chronology, one line per year   →  site/index.html
  With $year = "-256":          that year's page — its concurrent regnal years and its sources  →  site/256bce/index.html

  A source page is linked only when its XML/<dir>/source.xml exists (doc-available), so the
  whole corpus can be listed while translations fill in one bracket at a time.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei"
    xmlns="http://www.w3.org/1999/xhtml"
    version="3.0">

    <xsl:output method="xhtml" html-version="5" encoding="utf-8" indent="yes" omit-xml-declaration="yes"/>

    <xsl:param name="year" select="''"/>
    <xsl:param name="page" select="''"/>   <!-- '' = Home or a year page; 'about' = the About page -->
    <xsl:variable name="about" select="document('about.xml', /)/about"/>

    <xsl:variable name="site-name" select="string(/site/name)"/>
    <xsl:variable name="css" select="unparsed-text('../css/style.css')"/>
    <xsl:variable name="root" select="if ($year = '') then '' else '../'"/>
    <xsl:variable name="this-year" select="/site/year[@n = $year]"/>

    <!-- is a source page built yet? -->
    <xsl:function name="tei:built" as="xs:boolean">
        <xsl:param name="dir" as="xs:string"/>
        <xsl:sequence select="doc-available(resolve-uri(concat('../XML/', $dir, '/source.xml'), static-base-uri()))"/>
    </xsl:function>
    <!-- the folder a year's pages live in: 256bce, 210bce -->
    <xsl:function name="tei:year-dir" as="xs:string">
        <xsl:param name="y" as="element()"/>
        <xsl:sequence select="tokenize($y/document[1]/@dir, '/')[1]"/>
    </xsl:function>

    <!-- the reign a year label belongs to: 周赧王五十九年 → 周赧王 -->
    <xsl:function name="tei:reign" as="xs:string">
        <xsl:param name="label" as="xs:string"/>
        <!-- a double label (秦王政二十六年 / 秦始皇帝元年) is grouped under the new reign, its last part -->
        <xsl:sequence select="replace(normalize-space(tokenize($label, '/')[last()]), '[元一二三四五六七八九十百]+年$', '')"/>
    </xsl:function>

    <!-- compact chronology for the sidebar; $current = the year being shown, if any -->
    <xsl:template name="year-list">
        <xsl:param name="current" select="''"/>
        <nav class="chrono" aria-label="Chronology">
            <!-- sources that belong to an era rather than a single year; listed above the chronology,
                 grouped by the same reign headings so the two align. Entries are added later. -->
            <div class="era-sources">
                <h2>Sources by era</h2>
                <xsl:for-each select="/site/side-group">
                    <h3><span lang="zh"><xsl:value-of select="@label"/></span><xsl:if test="@en != ''"><span class="gloss"><xsl:value-of select="@en"/></span></xsl:if></h3>
                    <ul>
                        <xsl:if test="not(side-source)"><li><span class="unbuilt">to be added</span></li></xsl:if>
                        <xsl:for-each select="side-source">
                            <xsl:variable name="built" select="doc-available(resolve-uri(concat('../XML/', @id, '/source.xml'), static-base-uri()))"/>
                            <li>
                                <xsl:choose>
                                    <xsl:when test="$built"><a href="{$root}{@id}.html" lang="zh"><xsl:value-of select="@label"/></a></xsl:when>
                                    <xsl:otherwise><span class="unbuilt" lang="zh"><xsl:value-of select="@label"/></span></xsl:otherwise>
                                </xsl:choose>
                                <xsl:if test="@en != ''"><span class="gloss"><xsl:value-of select="@en"/></span></xsl:if>
                            </li>
                        </xsl:for-each>
                    </ul>
                </xsl:for-each>
            </div>
            <h2>Chronology</h2>
            <xsl:for-each-group select="/site/year" group-adjacent="tei:reign(@label)">
                <xsl:sort select="xs:integer(@n)"/>
                <h3><span lang="zh"><xsl:value-of select="current-grouping-key()"/></span><xsl:if test="current-group()[1]/@reign-en != ''"><span class="gloss"><xsl:value-of select="current-group()[1]/@reign-en"/></span></xsl:if></h3>
                <ul>
                    <xsl:for-each select="current-group()">
                        <xsl:variable name="any-built" select="some $d in document satisfies tei:built($d/@dir)"/>
                        <li>
                            <xsl:if test="@n = $current"><xsl:attribute name="class">current</xsl:attribute></xsl:if>
                            <xsl:choose>
                                <xsl:when test="$any-built">
                                    <a href="{$root}{tei:year-dir(.)}/index.html"><span class="era"><xsl:value-of select="@era"/></span><xsl:text> </xsl:text><span lang="zh"><xsl:value-of select="@label"/></span></a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <span class="unbuilt"><span class="era"><xsl:value-of select="@era"/></span><xsl:text> </xsl:text><span lang="zh"><xsl:value-of select="@label"/></span></span>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="@en != ''"><span class="gloss"><xsl:value-of select="@en"/></span></xsl:if>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:for-each-group>
        </nav>
    </xsl:template>

    <xsl:template match="/">
        <html lang="en" class="notranslate" translate="no">
            <head>
                <meta charset="utf-8"/>
                <meta name="google" content="notranslate"/>
                <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                <title><xsl:value-of select="$site-name"/><xsl:choose><xsl:when test="$page = 'about'">: About</xsl:when><xsl:when test="$year != ''"><xsl:text>: </xsl:text><xsl:value-of select="$this-year/@era"/></xsl:when></xsl:choose></title>
                <style><xsl:value-of select="$css" disable-output-escaping="yes"/><xsl:value-of select="replace(unparsed-text('../css/font-cjk.css'), 'FONTROOT/', $root)" disable-output-escaping="yes"/></style>
            </head>
            <body>
                <div class="header">
                    <div class="figure"><a class="wordmark" href="{$root}index.html"><xsl:value-of select="$site-name"/></a></div>
                </div>
                <div id="navbar">
                    <div class="navbar">
                        <a href="{$root}index.html">Home</a>
                        <a href="{$root}about.html">About</a>
                        <xsl:if test="$year != ''"><a href="index.html"><xsl:value-of select="$this-year/@era"/></a></xsl:if>
                    </div>
                    <div class="footer"></div>
                </div>

                <div class="content">
                    <div class="indent">
                        <xsl:choose>

                            <!-- ===== About ===== -->
                            <xsl:when test="$page = 'about'">
                                <div class="about">
                                    <h1>About</h1>
                                    <hr/>
                                    <xsl:apply-templates select="$about/section"/>
                                </div>
                            </xsl:when>

                            <!-- ===== Home: chronology sidebar + overview ===== -->
                            <xsl:when test="$year = ''">
                                <div class="nav-grid">
                                    <xsl:call-template name="year-list"/>
                                    <div class="overview">
                                        <h1>Regnum Sinense</h1>
                                        <hr/>
                                        <p>A year-by-year reading of the sources, from <span lang="zh"><xsl:value-of select="/site/year[1]/@label"/></span> (<xsl:value-of select="/site/year[1]/@era"/>) onward. Each year lists its sources; each source page gives the Chinese text, an English translation, and notes on the terms, persons and places.</p>
                                        <p>The site accompanies the historical atlases and videomaps of <a href="https://www.youtube.com/@AtriumConcordiae">Atrium Concordiae</a>; see <a href="about.html">About</a>.</p>
                                        <p class="hint">Years in grey have no translated sources yet.</p>
                                        <p class="hint"><xsl:value-of select="count(/site/year)"/> years · <xsl:value-of select="count(/site/year/document)"/> source pages · <xsl:value-of select="count(/site/year/document/bracket)"/> brackets</p>
                                    </div>
                                </div>
                            </xsl:when>

                            <!-- ===== one year ===== -->
                            <xsl:otherwise>
                                <div class="nav-grid">
                                <xsl:call-template name="year-list"><xsl:with-param name="current" select="$year"/></xsl:call-template>
                                <div class="overview">
                                <h1><span lang="zh"><xsl:value-of select="$this-year/@label"/></span></h1>
                                <p class="era-line"><xsl:value-of select="$this-year/@era"/><xsl:if test="$this-year/@en != ''"> · <xsl:value-of select="$this-year/@en"/></xsl:if></p>
                                <hr/>
                                <div class="responsive-two-column-grid">
                                    <div>
                                        <h2>Sources</h2>
                                        <ul class="documents">
                                            <xsl:for-each select="$this-year/document">
                                                <xsl:variable name="built" select="tei:built(@dir)"/>
                                                <xsl:variable name="total" select="count(bracket)"/>
                                                <!-- brackets translated so far = numbered divs with content in the document's english.xml -->
                                                <xsl:variable name="eng-uri" select="resolve-uri(concat('../XML/', @dir, '/english.xml'), static-base-uri())"/>
                                                <xsl:variable name="done" select="if ($built and doc-available($eng-uri)) then count(doc($eng-uri)//tei:body/tei:div[@n][tei:p or tei:ab or tei:head]) else 0"/>
                                                <li>
                                                    <xsl:choose>
                                                        <xsl:when test="$built"><span class="src-label"><xsl:value-of select="@label"/></span></xsl:when>
                                                        <xsl:otherwise><span class="unbuilt"><xsl:value-of select="@label"/></span></xsl:otherwise>
                                                    </xsl:choose>
                                                    <xsl:choose>
                                                        <xsl:when test="$done &gt;= $total"/>
                                                        <xsl:when test="$done = 0"><xsl:text> </xsl:text><span class="count">not yet translated · <xsl:value-of select="$total"/><xsl:text> </xsl:text><xsl:value-of select="if ($total = 1) then 'bracket' else 'brackets'"/></span></xsl:when>
                                                        <xsl:otherwise><xsl:text> </xsl:text><span class="count"><xsl:value-of select="$done"/> of <xsl:value-of select="$total"/> brackets translated</span></xsl:otherwise>
                                                    </xsl:choose>
                                                    <!-- the brackets, as subcategories of the source; a link once that bracket is translated -->
                                                    <xsl:variable name="page" select="tokenize(@dir, '/')[last()]"/>
                                                    <xsl:variable name="eng" select="if ($built and doc-available($eng-uri)) then doc($eng-uri) else ()"/>
                                                    <ul class="brackets">
                                                        <xsl:for-each select="bracket">
                                                            <xsl:variable name="i" select="position()"/>
                                                            <xsl:variable name="translated" select="exists($eng//tei:body/tei:div[@n = string($i)][tei:p or tei:ab or tei:head])"/>
                                                            <li>
                                                                <span class="sect">§<xsl:value-of select="$i"/></span>
                                                                <xsl:text> </xsl:text>
                                                                <xsl:choose>
                                                                    <xsl:when test="$translated"><a href="{$page}/{$i}.html" lang="zh"><xsl:value-of select="normalize-space(.)"/></a></xsl:when>
                                                                    <xsl:otherwise><span class="unbuilt" lang="zh"><xsl:value-of select="normalize-space(.)"/></span></xsl:otherwise>
                                                                </xsl:choose>
                                                                <xsl:if test="@en != ''"><span class="gloss"><xsl:value-of select="@en"/></span></xsl:if>
                                                            </li>
                                                        </xsl:for-each>
                                                    </ul>
                                                </li>
                                            </xsl:for-each>
                                        </ul>
                                    </div>
                                    <div>
                                        <h2>Concurrent regnal years</h2>
                                        <ul class="concurrent">
                                            <xsl:for-each select="$this-year/concurrent">
                                                <li><span lang="zh"><xsl:value-of select="."/></span><xsl:if test="@en != ''"><span class="gloss"><xsl:value-of select="@en"/></span></xsl:if></li>
                                            </xsl:for-each>
                                        </ul>
                                    </div>
                                </div>
                                </div>
                                </div>
                            </xsl:otherwise>

                        </xsl:choose>
                    </div>
                </div>

                <div id="footer">
                    <div class="copyright">
                        <ul class="menu">
                            <li>&#169; <xsl:value-of select="$site-name"/>. All rights reserved</li>
                            <li>Page structure and stylesheet adapted from the <a href="https://parlamentos.pitt.edu/">Parlamentos</a> project (CC BY-NC-SA 4.0).</li>
                        </ul>
                    </div>
                </div>
            </body>
        </html>
    </xsl:template>

    <!-- ===== About page content (XML/about.xml) ===== -->
    <xsl:template match="section">
        <h2><xsl:apply-templates select="head/node()"/></h2>
        <xsl:apply-templates select="* except head"/>
    </xsl:template>
    <xsl:template match="p"><p><xsl:apply-templates/></p></xsl:template>
    <xsl:template match="ul"><ul class="{@class}"><xsl:apply-templates/></ul></xsl:template>
    <xsl:template match="li"><li><xsl:apply-templates/></li></xsl:template>
    <xsl:template match="a"><a href="{@href}"><xsl:apply-templates/></a></xsl:template>
    <xsl:template match="i"><i><xsl:apply-templates/></i></xsl:template>
    <xsl:template match="zh"><span lang="zh"><xsl:apply-templates/></span></xsl:template>

</xsl:stylesheet>
