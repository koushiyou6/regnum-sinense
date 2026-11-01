<?xml version="1.0" encoding="UTF-8"?>
<!--
  TRIAL RUN — text / translation / notes page.

  Adapted from the Parlamentos project stylesheet
  XSLT/negrete-text-trans-notes-divs.xsl (https://github.com/haggis78/parla,
  CC BY-NC-SA 4.0). The HTML it produces has the same structure and class names,
  so the Parlamentos CSS applies unchanged.

  Differences from the original:
   - single-edition source: no <app>/<rdg> filtering, no witness modes
   - writes to the file the runner names; no xsl:result-document
   - CSS is inlined with unparsed-text() so the output is one self-contained file
   - lang attributes on source (zh) and translation (en) cells
   - empty-field guards in the place display name and the term headword
   - part of speech taken from the English entry, falling back to the source entry
   - note numbering handled by one function for both the intro and the text
   - the "Encoded in TEI XML" credit is computed from the files, not hard-coded

  Run with:  python3 build.py        (uses saxonche; XSLT 3.0 required)
  The input document is XML/source.xml; the other files are loaded with document().
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:local="urn:trial:local"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs local"
    xmlns="http://www.w3.org/1999/xhtml"
    version="3.0">

    <xsl:output method="xhtml" html-version="5" encoding="utf-8" indent="yes" omit-xml-declaration="yes"/>

    <!-- ===== parameters set by build.py ===== -->
    <xsl:param name="root" select="'../'"/>       <!-- relative path from this page to the site root -->
    <xsl:param name="year" select="''"/>          <!-- the era label of the year this document is filed under, e.g. "256 BC" -->
    <xsl:param name="dir" select="''"/>           <!-- this document's dir in site.xml, e.g. "256bc/shiji" -->
    <xsl:param name="bracket" select="''"/>       <!-- bracket number: the page shows only <div n="$bracket"> and sits in <dir>/<n>.html -->

    <!-- ===== inputs =====
         The document's own files are siblings of source.xml, so one stylesheet serves every document. -->
    <xsl:variable name="src"    select="/"/>
    <xsl:variable name="trans"  select="document('english.xml', /)"/>
    <xsl:variable name="intro"  select="if (doc-available(resolve-uri('intro.xml', base-uri(/)))) then document('intro.xml', /) else ()"/>
    <xsl:variable name="notes"  select="document('notes.xml', /)"/>
    <xsl:variable name="lex"    select="document('../XML/auth-files/lexicon.xml')"/>
    <xsl:variable name="pers"   select="document('../XML/auth-files/persons.xml')"/>
    <xsl:variable name="places" select="document('../XML/auth-files/locations.xml')"/>
    <xsl:variable name="site"   select="document('../XML/site.xml')"/>
    <xsl:variable name="css"    select="unparsed-text('../css/style.css')"/>

    <xsl:variable name="manifest-doc" select="$site/*:site/*:year/*:document[@dir = $dir]"/>
    <xsl:variable name="this-bracket" select="if ($bracket != '') then $manifest-doc/*:bracket[position() = xs:integer($bracket)] else ()"/>
    <xsl:variable name="year-href" select="if ($bracket != '') then '../index.html' else 'index.html'"/>
    <xsl:variable name="source-title" select="string($src//titleStmt/title)"/>
    <!-- the page's year as a number (BC negative), for entries whose notes are dated -->
    <xsl:variable name="year-n" as="xs:integer?" select="if (matches($year, '^\d+ BC$')) then -xs:integer(replace($year, ' BC', '')) else if (matches($year, '^AD \d+$')) then xs:integer(replace($year, 'AD ', '')) else ()"/>
    <!-- this page's place in the year's reading order: documents in manifest order, brackets within them -->
    <xsl:variable name="page-seq" as="xs:integer" select="if ($bracket != '') then count($manifest-doc/preceding-sibling::*:document/*:bracket) + xs:integer($bracket) else 0"/>
    <!-- the version of an entry's note current as of this page: notes carry from="year" (BC negative) and seq="n"
         (the bracket, in the year's reading order) of the bracket that introduced them; the latest note at or before
         this page is shown, else the undated note. Earlier pages therefore keep the earlier text. -->
    <xsl:function name="local:note-for-year" as="element()?">
        <xsl:param name="notes" as="element()*"/>
        <xsl:variable name="dated" select="$notes[@from][xs:integer(@from) lt $year-n or (xs:integer(@from) eq $year-n and (if (@seq) then xs:integer(@seq) else 1) le $page-seq)]"/>
        <xsl:variable name="sorted" as="element()*">
            <xsl:perform-sort select="$dated">
                <xsl:sort select="xs:integer(@from)" order="descending"/>
                <xsl:sort select="if (@seq) then xs:integer(@seq) else 1" order="descending"/>
            </xsl:perform-sort>
        </xsl:variable>
        <xsl:sequence select="if ($sorted) then $sorted[1] else $notes[not(@from)][1]"/>
    </xsl:function>

    <!-- ===== site settings ===== -->
    <xsl:variable name="site-name"   select="string($site/*:site/*:name)"/>
    <xsl:variable name="source-lang" select="'zh'"/>
    <xsl:variable name="source-label" select="'Text: Chinese source'"/>
    <xsl:variable name="trans-label"  select="'Text: English Translation'"/>

    <!-- ===== helpers ===== -->

    <!-- note number = position of this span among the @corresp spans of the same section -->
    <xsl:function name="local:note-number" as="xs:integer">
        <xsl:param name="span" as="element()"/>
        <xsl:variable name="section" select="$span/ancestor::div[1]"/>
        <xsl:sequence select="count($span/preceding::span[@corresp][ancestor::div[1] is $section]) + 1"/>
    </xsl:function>

    <!-- display name for a place: the name alone (the state and modern location belong in the expanded note) -->
    <xsl:function name="local:place-name" as="xs:string">
        <xsl:param name="place" as="element()?"/>
        <xsl:sequence select="normalize-space(string-join(($place/geogName, $place/placeName), ' '))"/>
    </xsl:function>

    <!-- ===== the annotation panel, shared by the intro sidebar and every text section ===== -->
    <!-- $scope: the element whose descendants are scanned for entities
         $note-div: the <div n="…"> of notes.xml holding this section's notes -->
    <xsl:template name="annotation-panel">
        <xsl:param name="scope" as="element()"/>
        <xsl:param name="note-div" as="element()?"/>

        <xsl:if test="$scope//term">
            <h3><b>Terms</b></h3>
            <xsl:for-each-group select="$scope//term" group-by="data(@n)">
                <xsl:variable name="id" select="current-grouping-key()"/>
                <xsl:variable name="entry-src" select="$lex//superEntry[data(@n) = $id]/entry[not(@xml:lang = 'eng')]"/>
                <xsl:variable name="entry-eng" select="$lex//superEntry[data(@n) = $id]/entry[@xml:lang = 'eng']"/>
                <xsl:variable name="orth-src" select="string-join($entry-src/form/orth, '; ')"/>
                <xsl:variable name="orth-eng" select="string-join($entry-eng/form/orth, '; ')"/>
                <xsl:variable name="sense-n" select="if (@select) then data(@select) else '1'"/>
                <details>
                    <summary><b><span class="term">
                        <xsl:choose>
                            <xsl:when test="@type = 'untrans' or $orth-eng = '' or $orth-eng = $orth-src">
                                <i lang="{$source-lang}"><xsl:value-of select="$orth-src"/></i>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$orth-eng"/>
                                <xsl:text> / </xsl:text>
                                <i lang="{$source-lang}"><xsl:value-of select="$orth-src"/></i>
                            </xsl:otherwise>
                        </xsl:choose>
                    </span></b></summary>
                    <xsl:variable name="pos" select="($entry-eng/gramGrp/pos, $entry-src/gramGrp/pos)[normalize-space(.) != ''][1]"/>
                    <xsl:if test="$pos"><i><xsl:value-of select="$pos"/></i><xsl:text>. </xsl:text></xsl:if>
                    <xsl:apply-templates select="$entry-eng/sense[data(@n) = $sense-n]/def"/>
                    <xsl:if test="normalize-space($entry-eng/note) != ''"><xsl:text> </xsl:text><span class="status">(<xsl:value-of select="normalize-space($entry-eng/note)"/>)</span></xsl:if>
                    <br/>
                </details>
            </xsl:for-each-group>
        </xsl:if>

        <xsl:if test="$scope//persName">
            <h3><b>Persons</b></h3>
            <xsl:for-each-group select="$scope//persName" group-by="data(@n)">
                <xsl:variable name="p" select="$pers//person[data(@n) = current-grouping-key()]"/>
                <details>
                    <summary><b><span class="pers"><xsl:value-of select="$p/persName/name"/></span></b></summary>
                    <xsl:apply-templates select="local:note-for-year($p/note[@xml:lang = 'eng'])/p/node()"/>
                    <br/>
                </details>
            </xsl:for-each-group>
        </xsl:if>

        <xsl:if test="$scope//placeName">
            <h3><b>Places</b></h3>
            <xsl:for-each-group select="$scope//placeName" group-by="data(@n)">
                <xsl:variable name="pl" select="$places//place[data(@n) = current-grouping-key()]"/>
                <details>
                    <summary><b><span class="place"><xsl:value-of select="local:place-name($pl)"/></span></b></summary>
                    <xsl:apply-templates select="local:note-for-year($pl/note[@xml:lang = 'eng'])/node()"/>
                    <br/>
                </details>
            </xsl:for-each-group>
        </xsl:if>

        <xsl:if test="$scope//span[@corresp]">
            <h3><b>Notes</b></h3>
            <xsl:for-each select="$scope//span[@corresp]">
                <xsl:variable name="key" select="data(@corresp)"/>
                <details>
                    <summary><b><span class="note"><sup><xsl:value-of select="local:note-number(.)"/></sup>
                        <xsl:text> </xsl:text><xsl:value-of select="replace($key, '_', ' ')"/></span></b></summary>
                    <xsl:apply-templates select="$note-div/interp[data(@corresp) = $key]/node()"/>
                    <br/>
                </details>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- ===== page ===== -->
    <xsl:template match="/">
        <html lang="en" class="notranslate" translate="no">
            <head>
                <meta charset="utf-8"/>
                <meta name="google" content="notranslate"/>
                <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                <link rel="icon" href="{$root}favicon.ico" sizes="any"/>
                <link rel="icon" type="image/png" sizes="32x32" href="{$root}favicon-32.png"/>
                <link rel="icon" type="image/png" sizes="192x192" href="{$root}favicon-192.png"/>
                <link rel="apple-touch-icon" href="{$root}apple-touch-icon.png"/>
                <meta name="description">
                    <xsl:attribute name="content">
                        <xsl:if test="$this-bracket"><xsl:value-of select="normalize-space($this-bracket)"/><xsl:if test="$this-bracket/@en != ''"><xsl:text> (</xsl:text><xsl:value-of select="$this-bracket/@en"/><xsl:text>)</xsl:text></xsl:if><xsl:text>, </xsl:text></xsl:if>
                        <xsl:value-of select="$manifest-doc/@label"/><xsl:text>, </xsl:text><xsl:value-of select="$year"/>
                        <xsl:if test="$manifest-doc/../@label != ''"><xsl:text> (</xsl:text><xsl:value-of select="$manifest-doc/../@label"/><xsl:text>)</xsl:text></xsl:if>
                        <xsl:text>: Chinese text with English translation and notes on terms, persons and places. Regnum Sinense.</xsl:text>
                    </xsl:attribute>
                </meta>
                <title><xsl:value-of select="$source-title"/><xsl:if test="$this-bracket"> · <xsl:value-of select="normalize-space($this-bracket)"/></xsl:if></title>
                <style><xsl:value-of select="$css" disable-output-escaping="yes"/><xsl:value-of select="replace(unparsed-text('../css/font-cjk.css'), 'FONTROOT/', $root)" disable-output-escaping="yes"/></style>
            </head>
            <body>
                <div class="header">
                    <div class="figure"><a class="wordmark" href="{$root}index.html"><xsl:value-of select="$site-name"/></a></div>
                </div>

                <!-- nav: Home (the list of years) and this document's year page (index.html in the same folder) -->
                <div id="navbar">
                    <div class="navbar">
                        <a href="{$root}index.html">Home</a>
                        <a href="{$root}about.html">About</a>
                        <xsl:if test="$year != ''"><a href="{$year-href}"><xsl:value-of select="$year"/></a></xsl:if>
                        <form class="search" action="{$root}search.html" method="get" role="search"><input type="search" name="q" placeholder="Search" aria-label="Search the site"/></form>
                    </div>
                    <div class="footer"></div>
                </div>

                <div class="content">
                    <div class="indent">
                        <xsl:choose>
                            <xsl:when test="$this-bracket">
                                <!-- one bracket: its name is the title; the source and year sit beneath -->
                                <h1><span lang="{$source-lang}"><xsl:value-of select="normalize-space($this-bracket)"/></span></h1>
                                <xsl:if test="$this-bracket/@en != ''"><p class="era-line"><xsl:value-of select="$this-bracket/@en"/></p></xsl:if>
                                <p class="era-line"><xsl:value-of select="$manifest-doc/@label"/><xsl:text> · </xsl:text><a href="{$year-href}"><xsl:value-of select="$year"/></a><xsl:if test="$manifest-doc/../@label != ''"><xsl:text> · </xsl:text><span lang="{$source-lang}"><xsl:value-of select="$manifest-doc/../@label"/></span></xsl:if></p>
                            </xsl:when>
                            <xsl:otherwise>
                                <h1><xsl:value-of select="$source-title"/></h1>
                                <xsl:if test="$year != ''"><p class="era-line"><a href="{$year-href}"><xsl:value-of select="$year"/></a></p></xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                        <hr/>

                        <!-- ===== introduction + sidebar (only when intro.xml has text for this page) =====
                             intro.xml holds one <div n="N"> per bracket (and <div n="0"> for the whole source);
                             a bracket page shows its own div, the whole-source page shows div 0 -->
                        <xsl:variable name="intro-div" select="$intro//body/div[@n = (if ($bracket != '') then $bracket else '0')]"/>
                        <xsl:if test="$intro-div/p[normalize-space()]">
                        <h2 id="introduction">Introduction</h2>
                        <div class="intro">
                            <xsl:for-each select="$intro-div/p">
                                <p><xsl:apply-templates/></p>
                            </xsl:for-each>
                        </div>
                        <hr/>
                        </xsl:if>

                        <!-- ===== text and translation ===== -->
                        <h2 id="text">Text and Translation</h2>
                        <!-- the brackets of this source, as subcategories; translated ones link to their page (or section) -->
                        <xsl:choose>
                            <xsl:when test="$manifest-doc">
                                <ul class="sections" id="skip">
                                    <xsl:for-each select="$manifest-doc/*:bracket">
                                        <xsl:variable name="i" select="position()"/>
                                        <xsl:variable name="translated" select="exists($trans//body/div[@n = string($i)][p or ab or head])"/>
                                        <xsl:variable name="href" select="if ($bracket != '') then concat($i, '.html') else concat('#sect-', $i)"/>
                                        <li>
                                            <xsl:if test="$bracket != '' and string($i) = $bracket"><xsl:attribute name="class">current</xsl:attribute></xsl:if>
                                            <span class="sect">§<xsl:value-of select="$i"/></span><xsl:text> </xsl:text>
                                            <xsl:choose>
                                                <xsl:when test="$bracket != '' and string($i) = $bracket"><span lang="{$source-lang}"><xsl:value-of select="normalize-space(.)"/></span></xsl:when>
                                                <xsl:when test="$translated"><a href="{$href}" lang="{$source-lang}"><xsl:value-of select="normalize-space(.)"/></a></xsl:when>
                                                <xsl:otherwise><span class="unbuilt" lang="{$source-lang}"><xsl:value-of select="normalize-space(.)"/></span></xsl:otherwise>
                                            </xsl:choose>
                                            <xsl:if test="@en != ''"><span class="gloss"><xsl:value-of select="@en"/></span></xsl:if>
                                        </li>
                                    </xsl:for-each>
                                </ul>
                            </xsl:when>
                            <xsl:otherwise>
                                <h3 id="skip">Skip to section:<xsl:text>   </xsl:text>
                                    <xsl:for-each select="$src//body/div[@n]"><a href="#sect-{@n}"><xsl:value-of select="@n"/></a><xsl:text>   </xsl:text></xsl:for-each>
                                </h3>
                            </xsl:otherwise>
                        </xsl:choose>

                        <div class="responsive-three-column-grid" id="document">

                            <!-- (the Parlamentos metadata row — source bibliography / digital metadata / research credits — is omitted;
                                  the TEI headers still carry that information if it is wanted later) -->

                            <!-- row 1: column headers -->
                            <div><h2><xsl:value-of select="$source-label"/></h2></div>
                            <div><h2><xsl:value-of select="$trans-label"/></h2></div>
                            <div><h2>Annotations</h2></div>

                            <!-- one row per numbered section (a bracket page has just the one) -->
                            <xsl:for-each select="$src//body/div[@n][$bracket = '' or data(@n) = $bracket]">
                                <xsl:variable name="n" select="data(@n)"/>
                                <xsl:variable name="eng" select="$trans//body/div[data(@n) = $n]"/>
                                <xsl:variable name="label">[&#167;<xsl:value-of select="$n"/>]</xsl:variable>

                                <!-- paragraph pairs: the bracket heading is one row, then one row per paragraph,
                                     so the Chinese and English paragraphs stay level with each other -->
                                <xsl:variable name="src-paras" select="p | ab"/>
                                <xsl:variable name="eng-paras" select="$eng/p | $eng/ab"/>
                                <xsl:variable name="rows" select="max((count($src-paras), count($eng-paras), 1))"/>
                                <xsl:variable name="has-head" select="exists(head) or exists($eng/head)"/>

                                <!-- the bracket's text: a subgrid of the first two columns, so the paragraph rows are sized
                                     by the text alone and a long annotation column cannot push them apart -->
                                <div class="bracket-text">
                                <!-- heading row (only when the bracket has a column heading) -->
                                <xsl:if test="$has-head">
                                    <div id="sect-{$n}" class="cell-src bracket-head" lang="{$source-lang}"><p class="bracket"><b><xsl:value-of select="$label"/><xsl:text> </xsl:text><xsl:apply-templates select="head/node()"/></b></p></div>
                                    <div class="cell-eng bracket-head" lang="en"><p class="bracket"><b><xsl:value-of select="$label"/><xsl:text> </xsl:text><xsl:choose><xsl:when test="$eng/head"><xsl:apply-templates select="$eng/head/node()"/></xsl:when><xsl:otherwise><i>[Translation pending.]</i></xsl:otherwise></xsl:choose></b></p></div>
                                </xsl:if>
                                <!-- paragraph rows -->
                                <xsl:for-each select="1 to $rows">
                                    <xsl:variable name="i" select="."/>
                                    <div class="cell-src para" lang="{$source-lang}">
                                        <xsl:if test="not($has-head) and $i = 1"><xsl:attribute name="id">sect-<xsl:value-of select="$n"/></xsl:attribute></xsl:if>
                                        <p><xsl:if test="not($has-head) and $i = 1"><b><xsl:value-of select="$label"/><xsl:text> </xsl:text></b></xsl:if><xsl:apply-templates select="$src-paras[$i]/node()"/></p>
                                    </div>
                                    <div class="cell-eng para" lang="en">
                                        <p><xsl:if test="not($has-head) and $i = 1"><b><xsl:value-of select="$label"/><xsl:text> </xsl:text></b></xsl:if>
                                            <xsl:choose>
                                                <xsl:when test="$eng-paras[$i]"><xsl:apply-templates select="$eng-paras[$i]/node()"/></xsl:when>
                                                <xsl:when test="not($eng) and $i = 1 and not($has-head)"><i>[Translation pending.]</i></xsl:when>
                                            </xsl:choose>
                                        </p>
                                    </div>
                                </xsl:for-each>
                                </div>
                                <!-- annotation cell: built from the TRANSLATION, as in the original; sits beside the bracket's text -->
                                <div class="notes cell-notes">
                                    <xsl:choose>
                                        <xsl:when test="$eng//term or $eng//persName or $eng//placeName or $eng//span[@corresp]">
                                            <p><b><xsl:value-of select="$label"/></b><xsl:text>  </xsl:text>
                                                <i>Click each triangle to expand/collapse note</i><br/>
                                                <a href="#">Top of page</a><xsl:text> | </xsl:text><a href="#document">Top of text</a></p>
                                            <xsl:call-template name="annotation-panel">
                                                <xsl:with-param name="scope" select="$eng"/>
                                                <xsl:with-param name="note-div" select="$notes//body/div[data(@n) = $n]"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <p><b><xsl:value-of select="$label"/></b><xsl:text>  </xsl:text>
                                                <i>No annotations on this section.</i><br/>
                                                <a href="#">Top of page</a><xsl:text> | </xsl:text><a href="#document">Top of text</a></p>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </div>
                            </xsl:for-each>
                        </div>
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

    <!-- one section's cell: [§N] + heading line (the bracket's column), then its paragraphs -->
    <xsl:template name="section-body">
        <xsl:param name="div" as="element()"/>
        <xsl:param name="label"/>
        <xsl:choose>
            <xsl:when test="$div/head and ($div/p or $div/ab)">
                <p class="bracket"><b><xsl:value-of select="$label"/><xsl:text> </xsl:text><xsl:apply-templates select="$div/head/node()"/></b></p>
                <xsl:for-each select="$div/p | $div/ab"><p><xsl:apply-templates/></p></xsl:for-each>
            </xsl:when>
            <xsl:when test="$div/head">
                <p><b><xsl:value-of select="$label"/><xsl:text> </xsl:text><xsl:apply-templates select="$div/head/node()"/></b></p>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$div/p | $div/ab">
                    <p><xsl:if test="position() = 1"><b><xsl:value-of select="$label"/><xsl:text> </xsl:text></b></xsl:if><xsl:apply-templates/></p>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ===== inline entity rendering (same classes as Parlamentos) ===== -->
    <xsl:template match="body//persName"><span class="pers"><xsl:apply-templates/></span></xsl:template>
    <xsl:template match="body//placeName"><span class="place"><xsl:apply-templates/></span></xsl:template>
    <xsl:template match="body//term[not(@type = 'untrans')]"><span class="term"><xsl:apply-templates/></span></xsl:template>
    <xsl:template match="body//term[@type = 'untrans']"><span class="term"><i><xsl:apply-templates/></i></span></xsl:template>
    <xsl:template match="body//span[@corresp]"><xsl:apply-templates/><sup><b><xsl:value-of select="local:note-number(.)"/></b></sup></xsl:template>
    <xsl:template match="body//date"><xsl:apply-templates/></xsl:template>
    <xsl:template match="body//title"><i class="chapter"><xsl:apply-templates/></i></xsl:template>
    <xsl:template match="lb"><br/></xsl:template>
    <xsl:template match="body//ref[@target]"><a href="{@target}"><xsl:apply-templates/></a></xsl:template>
    <xsl:template match="body//hi"><i><xsl:apply-templates/></i></xsl:template>
    <xsl:template match="metamark[@rend = 'horizontal-line']"><hr/></xsl:template>
    <xsl:template match="table">
        <table><xsl:for-each select="row"><tr><xsl:for-each select="cell"><td><xsl:apply-templates/></td></xsl:for-each></tr></xsl:for-each></table>
    </xsl:template>

</xsl:stylesheet>
