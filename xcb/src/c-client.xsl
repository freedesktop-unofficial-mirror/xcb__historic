<?xml version="1.0" encoding="utf-8"?>
<!--
Copyright (C) 2004 Josh Triplett.  All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the names of the authors or their
institutions shall not be used in advertising or otherwise to promote the
sale, use or other dealings in this Software without prior written
authorization from the authors.
-->
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               version="1.0"
               xmlns:e="http://exslt.org/common">
  
  <xsl:output method="text" />

  <xsl:strip-space elements="*" />

  <!-- "header" or "source" -->
  <xsl:param name="mode" />

  <!-- Path to the core protocol descriptions. -->
  <xsl:param name="base-path" />

  <!-- Path to the extension protocol descriptions. -->
  <xsl:param name="extension-path" select="$base-path" />

  <xsl:variable name="h" select="$mode = 'header'" />
  <xsl:variable name="c" select="$mode = 'source'" />
  
  <!-- String used to indent lines of code. -->
  <xsl:variable name="indent-string" select="'    '" />

  <xsl:variable name="ucase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
  <xsl:variable name="lcase" select="'abcdefghijklmnopqrstuvwxyz'" />

  <xsl:variable name="header" select="/xcb/@header" />
  <xsl:variable name="ucase-header"
                select="translate($header,$lcase,$ucase)" />

  <xsl:variable name="ext" select="/xcb/@extension-name" />

  <!-- Other protocol descriptions to search for types in, after checking the
       current protocol description. -->
  <xsl:variable name="search-path-rtf">
    <xsl:for-each select="/xcb/import">
      <path><xsl:value-of select="concat($extension-path, ., '.xml')" /></path>
    </xsl:for-each>
    <xsl:choose>
      <xsl:when test="$header='xproto'">
        <path><xsl:value-of select="concat($base-path,
                                           'xcb_types.xml')" /></path>
      </xsl:when>
      <xsl:when test="$header='xcb_types'" />
      <xsl:otherwise>
        <path><xsl:value-of select="concat($base-path,
                                           'xproto.xml')" /></path>
        <path><xsl:value-of select="concat($base-path,
                                           'xcb_types.xml')" /></path>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="search-path" select="e:node-set($search-path-rtf)/path"/>

  <xsl:variable name="root" select="/" />
  
  <!-- First pass: Store everything in a variable. -->
  <xsl:variable name="pass1-rtf">
    <xsl:apply-templates select="/" mode="pass1" />
  </xsl:variable>
  <xsl:variable name="pass1" select="e:node-set($pass1-rtf)" />
  
  <xsl:template match="xcb" mode="pass1">
    <xcb>
      <xsl:copy-of select="@*" />
      <xsl:if test="$ext">
        <constant type="XCBExtension" name="XCB{$ext}Id"
                  value='{{ "{@extension-xname}" }}' />
        <function type="const XCBQueryExtensionRep *" name="XCB{$ext}Init">
          <field type="XCBConnection *" name="c" />
          <l>return XCBGetExtensionData(c, &amp;XCB<!--
          --><xsl:value-of select="$ext" />Id);</l>
        </function>
      </xsl:if>
      <xsl:apply-templates mode="pass1" />
    </xcb>
  </xsl:template>

  <!-- Modify names that conflict with C++ keywords by prefixing them with an
       underscore.  If the name parameter is not specified, it defaults to the
       value of the name attribute on the context node. -->
  <xsl:template name="canonical-var-name">
    <xsl:param name="name" select="@name" />
    <xsl:if test="$name='new' or $name='delete'
                  or $name='class' or $name='operator'">
      <xsl:text>_</xsl:text>
    </xsl:if>
    <xsl:value-of select="$name" />
  </xsl:template>

  <!--
    Output the canonical name for a type.  This will be
    XCB{extension-containing-Type-if-any}Type, wherever the type is found in
    the search path, or just Type if not found.  If the type parameter is not
    specified, it defaults to the value of the type attribute on the context
    node.
  -->
  <xsl:template name="canonical-type-name">
    <xsl:param name="type" select="string(@type)" />
    <xsl:for-each select="(/xcb|document($search-path)/xcb
                          )/*[((self::struct or self::union
                                or self::xidtype or self::enum
                                or self::event or self::eventcopy
                                or self::error or self::errorcopy)
                               and @name=$type)
                              or (self::typedef and @newname=$type)][1]">
      <xsl:text>XCB</xsl:text>
      <xsl:value-of select="/xcb/@extension-name" />
    </xsl:for-each>
    <xsl:value-of select="$type" />
  </xsl:template>
  
  <!-- Helper template for requests, that outputs the cookie type.  The
       context node must be the request. -->
  <xsl:template name="cookie-type">
    <xsl:text>XCB</xsl:text>
    <xsl:choose>
      <xsl:when test="reply">
        <xsl:value-of select="concat($ext, @name)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Void</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>Cookie</xsl:text>
  </xsl:template>

  <xsl:template match="request" mode="pass1">
    <xsl:if test="reply">
      <struct name="XCB{$ext}{@name}Cookie">
        <field type="unsigned int" name="sequence" />
      </struct>
    </xsl:if>
    <struct name="XCB{$ext}{@name}Req">
      <field type="CARD8" name="major_opcode" no-assign="true" />
      <xsl:if test="$ext">
        <field type="CARD8" name="minor_opcode" no-assign="true" />
      </xsl:if>
      <xsl:apply-templates select="*[not(self::reply)]" mode="field" />
      <middle>
        <field type="CARD16" name="length" no-assign="true" />
      </middle>
    </struct>
    <function name="XCB{$ext}{@name}">
      <xsl:attribute name="type">
        <xsl:call-template name="cookie-type" />
      </xsl:attribute>
      <field type="XCBConnection *" name="c" />
      <xsl:apply-templates select="*[not(self::reply)]" mode="param" />
      <do-request ref="XCB{$ext}{@name}Req" opcode="{@opcode}">
        <xsl:if test="reply">
          <xsl:attribute name="has-reply">true</xsl:attribute>
        </xsl:if>
      </do-request>
    </function>
    <xsl:if test="reply">
      <struct name="XCB{$ext}{@name}Rep">
        <field type="BYTE" name="response_type" />
        <xsl:apply-templates select="reply/*" mode="field" />
        <middle>
          <field type="CARD16" name="sequence" />
          <field type="CARD32" name="length" />
        </middle>
      </struct>
      <iterator-functions ref="XCB{$ext}{@name}" kind="Rep" />
      <function type="XCB{$ext}{@name}Rep *" name="XCB{$ext}{@name}Reply">
        <field type="XCBConnection *" name="c" />
        <field name="cookie">
          <xsl:attribute name="type">
            <xsl:call-template name="cookie-type" />
          </xsl:attribute>
        </field>
        <field type="XCBGenericError **" name="e" />
        <l>return (XCB<xsl:value-of select="concat($ext, @name)" />Rep *)<!--
        --> XCBWaitForReply(c, cookie.sequence, e);</l>
      </function>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xidtype" mode="pass1">
    <struct name="XCB{$ext}{@name}">
      <field type="CARD32" name="xid" />
    </struct>
    <iterator ref="XCB{$ext}{@name}" />
    <iterator-functions ref="XCB{$ext}{@name}" />
    <function type="XCB{$ext}{@name}" name="XCB{$ext}{@name}New">
      <field type="XCBConnection *" name="c" />
      <l>XCB<xsl:value-of select="concat($ext, @name)" /> ret;</l>
      <l>ret.xid = XCBGenerateID(c);</l>
      <l>return ret;</l>
    </function>
  </xsl:template>

  <xsl:template match="struct|union" mode="pass1">
    <struct name="XCB{$ext}{@name}">
      <xsl:if test="self::union">
        <xsl:attribute name="kind">union</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="*" mode="field" />
    </struct>
    <iterator ref="XCB{$ext}{@name}" />
    <iterator-functions ref="XCB{$ext}{@name}" />
  </xsl:template>

  <xsl:template match="event|eventcopy|error|errorcopy" mode="pass1">
    <xsl:variable name="suffix">
      <xsl:choose>
        <xsl:when test="self::event|self::eventcopy">
          <xsl:text>Event</xsl:text>
        </xsl:when>
        <xsl:when test="self::error|self::errorcopy">
          <xsl:text>Error</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <constant type="number" name="XCB{$ext}{@name}" value="{@number}" />
    <xsl:choose>
      <xsl:when test="self::event|self::error">
        <struct name="XCB{$ext}{@name}{$suffix}">
          <field type="BYTE" name="response_type" />
          <xsl:if test="self::error">
            <field type="BYTE" name="error_code" />
          </xsl:if>
          <xsl:apply-templates select="*" mode="field" />
          <xsl:if test="not(self::event and boolean(@no-sequence-number))">
            <middle>
              <field type="CARD16" name="sequence" />
            </middle>
          </xsl:if>
        </struct>
      </xsl:when>
      <xsl:when test="self::eventcopy|self::errorcopy">
        <typedef newname="XCB{$ext}{@name}{$suffix}">
          <xsl:attribute name="oldname">
            <xsl:call-template name="canonical-type-name">
              <xsl:with-param name="type" select="@ref" />
            </xsl:call-template>
            <xsl:value-of select="$suffix" />
          </xsl:attribute>
        </typedef>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="typedef" mode="pass1">
    <typedef>
      <xsl:attribute name="oldname">
        <xsl:call-template name="canonical-type-name">
          <xsl:with-param name="type" select="@oldname" />
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="newname">
        <xsl:call-template name="canonical-type-name">
          <xsl:with-param name="type" select="@newname" />
        </xsl:call-template>
      </xsl:attribute>
    </typedef>
  </xsl:template>

  <xsl:template match="enum" mode="pass1">
    <enum name="XCB{$ext}{@name}">
      <xsl:for-each select="item">
        <item name="XCB{$ext}{../@name}{@name}">
          <xsl:copy-of select="*" />
        </item>
      </xsl:for-each>
    </enum>
  </xsl:template>

  <!--
    Templates for processing fields.
  -->

  <xsl:template match="pad" mode="field">
    <xsl:copy-of select="." />
  </xsl:template>
  
  <xsl:template match="field|exprfield" mode="field">
    <xsl:copy>
      <xsl:attribute name="type">
        <xsl:call-template name="canonical-type-name" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:call-template name="canonical-var-name" />
      </xsl:attribute>
      <xsl:copy-of select="*" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="list" mode="field">
    <xsl:variable name="type"><!--
      --><xsl:call-template name="canonical-type-name" /><!--
    --></xsl:variable>
    <list type="{$type}">
      <xsl:attribute name="name">
        <xsl:call-template name="canonical-var-name" />
      </xsl:attribute>
      <xsl:if test="not(parent::request) and node()
                    and not(.//*[not(self::value or self::op)])">
        <xsl:attribute name="fixed">true</xsl:attribute>
      </xsl:if>
      <!-- Handle lists with no length expressions. -->
      <xsl:if test="not(node())">
        <xsl:choose>
          <!-- In a request, refer to an implicit localparam for length. -->
          <xsl:when test="parent::request">
            <fieldref>
              <xsl:value-of select="concat(@name, '_len')" />
            </fieldref>
          </xsl:when>
          <!-- In a reply, use the length of the reply to determine the length
               of the list. -->
          <xsl:when test="parent::reply">
            <op op="/">
              <fieldref>length</fieldref>
              <op op=">>">
                <function-call name="sizeof">
                  <param><xsl:value-of select="$type" /></param>
                </function-call>
                <value>2</value>
              </op>
            </op>
          </xsl:when>
          <!-- Other cases generate an error. -->
          <xsl:otherwise>
            <xsl:message terminate="yes"><!--
              -->Encountered a list with no length expresssion outside a<!--
              --> request or reply.<!--
            --></xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:copy-of select="*" />
    </list>
  </xsl:template>

  <xsl:template match="valueparam" mode="field">
    <field>
      <xsl:attribute name="type">
        <xsl:call-template name="canonical-type-name">
          <xsl:with-param name="type" select="@value-mask-type" />
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:call-template name="canonical-var-name">
          <xsl:with-param name="name" select="@value-mask-name" />
        </xsl:call-template>
      </xsl:attribute>
    </field>
    <list type="CARD32">
      <xsl:attribute name="name">
        <xsl:call-template name="canonical-var-name">
          <xsl:with-param name="name" select="@value-list-name" />
        </xsl:call-template>
      </xsl:attribute>
      <function-call name="XCBPopcount">
        <param>
          <fieldref>
            <xsl:call-template name="canonical-var-name">
              <xsl:with-param name="name" select="@value-mask-name" />
            </xsl:call-template>
          </fieldref>
        </param>
      </function-call>
    </list>
  </xsl:template>

  <xsl:template match="field|localfield" mode="param">
    <field>
      <xsl:attribute name="type">
        <xsl:call-template name="canonical-type-name" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:call-template name="canonical-var-name" />
      </xsl:attribute>
    </field>
  </xsl:template>

  <xsl:template match="list" mode="param">
    <!-- If no length expression is provided, use a CARD32 localfield. -->
    <xsl:if test="not(node())">
      <field type="CARD32" name="{@name}_len" />
    </xsl:if>
    <field>
      <xsl:attribute name="type">
        <xsl:text>const </xsl:text>
        <xsl:call-template name="canonical-type-name" />
        <xsl:text> *</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:call-template name="canonical-var-name" />
      </xsl:attribute>
    </field>
  </xsl:template>

  <xsl:template match="valueparam" mode="param">
    <field>
      <xsl:attribute name="type">
        <xsl:call-template name="canonical-type-name">
          <xsl:with-param name="type" select="@value-mask-type" />
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:call-template name="canonical-var-name">
          <xsl:with-param name="name" select="@value-mask-name" />
        </xsl:call-template>
      </xsl:attribute>
    </field>
    <field type="const CARD32 *">
      <xsl:attribute name="name">
        <xsl:call-template name="canonical-var-name">
          <xsl:with-param name="name" select="@value-list-name" />
        </xsl:call-template>
      </xsl:attribute>
    </field>
  </xsl:template>

  <!-- Second pass: Process the variable. -->
  <xsl:variable name="result-rtf">
    <xsl:apply-templates select="$pass1/*" mode="pass2" />
  </xsl:variable>
  <xsl:variable name="result" select="e:node-set($result-rtf)" />

  <xsl:template match="xcb" mode="pass2">
    <xcb>
      <xsl:copy-of select="@*" />
      <xsl:apply-templates mode="pass2"
                           select="constant|enum|struct|typedef|iterator" />
      <xsl:apply-templates mode="pass2"
                           select="function|iterator-functions" />
    </xcb>
  </xsl:template>

  <!-- Generic rules for nodes that don't need further processing: copy node
       with attributes, and recursively process the child nodes. -->
  <xsl:template match="*" mode="pass2">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:apply-templates mode="pass2" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="struct" mode="pass2">
    <xsl:if test="@kind='union' and list">
      <xsl:message terminate="yes">Unions must be fixed length.</xsl:message>
    </xsl:if>
    <struct name="{@name}">
      <xsl:if test="@kind">
        <xsl:attribute name="kind">
          <xsl:value-of select="@kind" />
        </xsl:attribute>
      </xsl:if>
      <!-- FIXME: This should go by size, not number of fields. -->
      <xsl:copy-of select="node()[not(self::middle)
                   and position() &lt; 3]" />
      <xsl:if test="middle and (count(*[not(self::middle)]) &lt; 2)">
        <pad bytes="{2 - count(*[not(self::middle)])}" />
      </xsl:if>
      <xsl:copy-of select="middle/*" />
      <xsl:copy-of select="node()[not(self::middle) and (position() > 2)]" />
    </struct>
  </xsl:template>

  <xsl:template match="do-request" mode="pass2">
    <xsl:variable name="struct"
                  select="$pass1/xcb/struct[@name=current()/@ref]" />

    <xsl:variable name="num-parts" select="1+count($struct/list)" />

    <l>static const XCBProtocolRequest xcb_req = {</l>
    <indent>
      <l>/* count */ <xsl:value-of select="$num-parts" />,</l>
      <l>/* ext */ <xsl:choose>
                     <xsl:when test="$ext">
                       <xsl:text>&amp;XCB</xsl:text>
                       <xsl:value-of select="$ext" />
                       <xsl:text>Id</xsl:text>
                     </xsl:when>
                     <xsl:otherwise>0</xsl:otherwise>
                   </xsl:choose>,</l>
      <l>/* opcode */ <xsl:value-of select="@opcode" />,</l>
      <l>/* isvoid */ <xsl:value-of select="1-boolean(@has-reply)" /></l>
    </indent>
    <l>};</l>

    <l />
    <l>struct iovec xcb_parts[<!--
    --><xsl:value-of select="1+count($struct/list)" />];</l>
    <l><xsl:value-of select="../@type" /> xcb_ret;</l>
    <l><xsl:value-of select="@ref" /> xcb_out;</l>

    <l />
    <xsl:apply-templates select="$struct//*[(self::field or self::exprfield)
                                            and not(boolean(@no-assign))]"
                         mode="assign" />

    <l />
    <l>xcb_parts[0].iov_base = &amp;xcb_out;</l>
    <l>xcb_parts[0].iov_len = sizeof(xcb_out);</l>

    <xsl:for-each select="$struct/list">
      <l>xcb_parts[<xsl:number />].iov_base = (void *) <!--
      --><xsl:value-of select="@name" />;</l>
      <l>xcb_parts[<xsl:number />].iov_len = <!--
      --><xsl:apply-templates mode="output-expression" /><!--
      --><xsl:if test="not(@type = 'void')">
        <xsl:text> * sizeof(</xsl:text>
        <xsl:value-of select="@type" />
        <xsl:text>)</xsl:text>
      </xsl:if>;</l>
    </xsl:for-each>

    <l>XCBSendRequest(c, &amp;xcb_ret.sequence, xcb_parts, &amp;xcb_req);</l>
    <l>return xcb_ret;</l>
  </xsl:template>

  <xsl:template match="field" mode="assign">
    <l>
      <xsl:text>xcb_out.</xsl:text>
      <xsl:value-of select="@name" />
      <xsl:text> = </xsl:text>
      <xsl:value-of select="@name" />
      <xsl:text>;</xsl:text>
    </l>
  </xsl:template>

  <xsl:template match="exprfield" mode="assign">
    <l>
      <xsl:text>xcb_out.</xsl:text>
      <xsl:value-of select="@name" />
      <xsl:text> = </xsl:text>
      <xsl:apply-templates mode="output-expression" />
      <xsl:text>;</xsl:text>
    </l>
  </xsl:template>

  <xsl:template match="iterator" mode="pass2">
    <struct name="{@ref}Iter">
      <field type="{@ref} *" name="data" />
      <field type="int" name="rem" />
      <field type="int" name="index" />
    </struct>
  </xsl:template>

  <!-- Change a_name_like_this to ANameLikeThis.  If the parameter name is not
       given, it defaults to the name attribute of the context node. -->
  <xsl:template name="capitalize">
    <xsl:param name="name" select="string(@name)" />
    <xsl:if test="$name">
      <xsl:value-of select="translate(substring($name,1,1), $lcase, $ucase)" />
      <xsl:choose>
        <xsl:when test="contains($name, '_')">
          <xsl:value-of select="substring(substring-before($name, '_'), 2)" />
          <xsl:call-template name="capitalize">
            <xsl:with-param name="name" select="substring-after($name, '_')" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring($name, 2)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="iterator-functions" mode="pass2">
    <xsl:variable name="ref" select="@ref" />
    <xsl:variable name="kind" select="@kind" />
    <xsl:variable name="struct"
                  select="$pass1/xcb/struct[@name=concat($ref,$kind)]" />
    <xsl:variable name="nextfields-rtf">
      <nextfield>R + 1</nextfield>
      <xsl:for-each select="$struct/list[not(@fixed)]">
        <xsl:choose>
          <xsl:when test="substring(@type, 1, 3) = 'XCB'">
            <nextfield><xsl:value-of select="@type" />End(<!--
            --><xsl:value-of select="$ref" /><!--
            --><xsl:call-template name="capitalize" />Iter(R))</nextfield>
          </xsl:when>
          <xsl:otherwise>
            <nextfield><xsl:value-of select="$ref" /><!--
            --><xsl:call-template name="capitalize" />End(R)</nextfield>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="nextfields" select="e:node-set($nextfields-rtf)" />
    <xsl:for-each select="$struct/list[not(@fixed)]">
      <xsl:variable name="number"
                    select="1+count(preceding-sibling::list[not(@fixed)])" />
      <xsl:variable name="nextfield" select="$nextfields/nextfield[$number]" />
      <xsl:variable name="is-first"
                    select="not(preceding-sibling::list[not(@fixed)])" />
      <xsl:variable name="field-name"><!--
        --><xsl:call-template name="capitalize" /><!--
      --></xsl:variable>
      <xsl:variable name="is-variable"
                    select="$pass1/xcb/struct[@name=current()/@type]/list
                            or document($search-path)/xcb
                               /struct[concat('XCB',
                                              ancestor::xcb/@extension-name,
                                              @name) = current()/@type]
                               /*[self::valueparam or self::list]" />
      <xsl:if test="not($is-variable)">
        <function type="{@type} *" name="{$ref}{$field-name}">
          <field type="{$ref}{$kind} *" name="R" />
          <xsl:choose>
            <xsl:when test="$is-first">
              <l>return (<xsl:value-of select="@type" /> *) <!--
              -->(<xsl:value-of select="$nextfield" />);</l>
            </xsl:when>
            <xsl:otherwise>
              <l>XCBGenericIter prev = <!--
              --><xsl:value-of select="$nextfield" />;</l>
              <l>return (<xsl:value-of select="@type" /> *) <!--
              -->((char *) prev.data + XCB_TYPE_PAD(<!--
              --><xsl:value-of select="@type" />, prev.index));</l>
            </xsl:otherwise>
          </xsl:choose>
        </function>
      </xsl:if>
      <function type="int" name="{$ref}{$field-name}Length">
        <field type="{$ref}{$kind} *" name="R" />
        <l>return <xsl:apply-templates mode="output-expression">
                    <xsl:with-param name="field-prefix" select="'R->'" />
                  </xsl:apply-templates>;</l>
      </function>
      <xsl:choose>
        <xsl:when test="substring(@type, 1, 3) = 'XCB'">
          <function type="{@type}Iter" name="{$ref}{$field-name}Iter">
            <field type="{$ref}{$kind} *" name="R" />
            <l><xsl:value-of select="@type" />Iter i;</l>
            <xsl:choose>
              <xsl:when test="$is-first">
                <l>i.data = (<xsl:value-of select="@type" /> *) <!--
                -->(<xsl:value-of select="$nextfield" />);</l>
              </xsl:when>
              <xsl:otherwise>
                <l>XCBGenericIter prev = <!--
                --><xsl:value-of select="$nextfield" />;</l>
                <l>i.data = (<xsl:value-of select="@type" /> *) <!--
                -->((char *) prev.data + XCB_TYPE_PAD(<!--
                --><xsl:value-of select="@type" />, prev.index));</l>
              </xsl:otherwise>
            </xsl:choose>
            <l>i.rem = <xsl:apply-templates mode="output-expression">
                         <xsl:with-param name="field-prefix" select="'R->'" />
                       </xsl:apply-templates>;</l>
            <l>i.index = (char *) i.data - (char *) R;</l>
            <l>return i;</l>
          </function>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="cast">
            <xsl:choose>
              <xsl:when test="@type='void'">char</xsl:when>
              <xsl:otherwise><xsl:value-of select="@type" /></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <function type="XCBGenericIter" name="{$ref}{$field-name}End">
            <field type="{$ref}{$kind} *" name="R" />
            <l>XCBGenericIter i;</l>
            <xsl:choose>
              <xsl:when test="$is-first">
                <l>i.data = ((<xsl:value-of select="$cast" /> *) <!--
                -->(<xsl:value-of select="$nextfield" />)) + (<!--
                --><xsl:apply-templates mode="output-expression">
                     <xsl:with-param name="field-prefix" select="'R->'" />
                   </xsl:apply-templates>);</l>
              </xsl:when>
              <xsl:otherwise>
                <l>XCBGenericIter child = <!--
                --><xsl:value-of select="$nextfield" />;</l>
                <l>i.data = ((<xsl:value-of select="$cast" /> *) <!--
                -->child.data) + (<!--
                --><xsl:apply-templates mode="output-expression">
                     <xsl:with-param name="field-prefix" select="'R->'" />
                   </xsl:apply-templates>);</l>
              </xsl:otherwise>
            </xsl:choose>
            <l>i.rem = 0;</l>
            <l>i.index = (char *) i.data - (char *) R;</l>
            <l>return i;</l>
          </function>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:if test="not($kind)">
      <function type="void" name="{$ref}Next">
        <field type="{$ref}Iter *" name="i" />
        <xsl:choose>
          <xsl:when test="$struct/list[not(@fixed)]">
            <l><xsl:value-of select="$ref" /> *R = i->data;</l>
            <l>XCBGenericIter child = <!--
            --><xsl:value-of select="$nextfields/nextfield[last()]" />;</l>
            <l>--i->rem;</l>
            <l>i->data = (<xsl:value-of select="$ref" /> *) child.data;</l>
            <l>i->index = child.index;</l>
          </xsl:when>
          <xsl:otherwise>
            <l>--i->rem;</l>
            <l>++i->data;</l>
            <l>i->index += sizeof(<xsl:value-of select="$ref" />);</l>
          </xsl:otherwise>
        </xsl:choose>
      </function>
      <function type="XCBGenericIter" name="{$ref}End">
        <field type="{$ref}Iter" name="i" />
        <l>XCBGenericIter ret;</l>
        <xsl:choose>
          <xsl:when test="$struct/list[not(@fixed)]">
            <l>while(i.rem > 0)</l>
            <indent>
              <l><xsl:value-of select="$ref" />Next(&amp;i);</l>
            </indent>
            <l>ret.data = i.data;</l>
            <l>ret.rem = i.rem;</l>
            <l>ret.index = i.index;</l>
          </xsl:when>
          <xsl:otherwise>
            <l>ret.data = i.data + i.rem;</l>
            <l>ret.index = i.index + ((char *) ret.data - (char *) i.data);</l>
            <l>ret.rem = 0;</l>
          </xsl:otherwise>
        </xsl:choose>
        <l>return ret;</l>
      </function>
    </xsl:if>
  </xsl:template>

  <!-- Output the results. -->
  <xsl:template match="/">
    <xsl:if test="not(function-available('e:node-set'))">
      <xsl:message terminate="yes"><!--
        -->Error: This stylesheet requires the EXSL node-set extension.<!--
      --></xsl:message>
    </xsl:if>

    <xsl:if test="not($h) and not($c)">
      <xsl:message terminate="yes"><!--
        -->Error: Parameter "mode" must be "header" or "source".<!--
      --></xsl:message>
    </xsl:if>

    <xsl:apply-templates select="$result/*" mode="output" />
  </xsl:template>

  <xsl:template match="xcb" mode="output">
    <xsl:variable name="guard"><!--
      -->__<xsl:value-of select="$ucase-header" />_H<!--
    --></xsl:variable>

<xsl:text>/*
 * This file generated automatically from </xsl:text>
<xsl:value-of select="$header" /><xsl:text>.xml by c-client.xsl using XSLT.
 * Edit at your peril.
 */
</xsl:text>

<xsl:if test="$h"><xsl:text>
#ifndef </xsl:text><xsl:value-of select="$guard" /><xsl:text>
#define </xsl:text><xsl:value-of select="$guard" /><xsl:text>
</xsl:text>
<xsl:for-each select="$root/xcb/import">
<xsl:text>#include "</xsl:text><xsl:value-of select="." /><xsl:text>.h"
</xsl:text>
</xsl:for-each>
<xsl:text>
</xsl:text>
</xsl:if>

<xsl:if test="$c"><xsl:text>
#include &lt;assert.h&gt;
#include "xcb.h"
#include "xcbext.h"
#include "</xsl:text><xsl:value-of select="$header" /><xsl:text>.h"

</xsl:text></xsl:if>

    <xsl:apply-templates mode="output" />

<xsl:if test="$h">
<xsl:text>
#endif
</xsl:text>
</xsl:if>
  </xsl:template>

  <xsl:template match="constant" mode="output">
    <xsl:choose>
      <xsl:when test="@type = 'number'">
        <xsl:if test="$h">
          <xsl:text>#define </xsl:text>
          <xsl:value-of select="@name" />
          <xsl:text> </xsl:text>
          <xsl:value-of select="@value" />
          <xsl:text>

</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:when test="@type = 'string'">
        <xsl:if test="$h">
          <xsl:text>extern </xsl:text>
        </xsl:if>
        <xsl:text>const char </xsl:text>
        <xsl:value-of select="@name" />
        <xsl:text>[]</xsl:text>
        <xsl:if test="$c">
          <xsl:text> = "</xsl:text>
          <xsl:value-of select="@value" />
          <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>;

</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$h">
          <xsl:text>extern </xsl:text>
        </xsl:if>
        <xsl:call-template name="type-and-name" />
        <xsl:if test="$c">
          <xsl:text> = </xsl:text>
          <xsl:value-of select="@value" />
        </xsl:if>
        <xsl:text>;

</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="typedef" mode="output">
    <xsl:if test="$h">
      <xsl:text>typedef </xsl:text>
      <xsl:value-of select="@oldname" />
      <xsl:text> </xsl:text>
      <xsl:value-of select="@newname" />
      <xsl:text>;

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="struct" mode="output">
    <xsl:if test="$h">
      <xsl:text>typedef </xsl:text>
      <xsl:if test="not(@kind)">struct</xsl:if><xsl:value-of select="@kind" />
      <xsl:text> {
</xsl:text>
      <xsl:for-each select="exprfield|field|list[@fixed]|pad">
        <xsl:text>    </xsl:text>
        <xsl:apply-templates select="." />
        <xsl:text>;
</xsl:text>
      </xsl:for-each>
      <xsl:text>} </xsl:text>
      <xsl:value-of select="@name" />
      <xsl:text>;

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="enum" mode="output">
    <xsl:if test="$h">
      <xsl:text>typedef enum {
    </xsl:text>
      <xsl:call-template name="list">
        <xsl:with-param name="separator"><xsl:text>,
    </xsl:text></xsl:with-param>
        <xsl:with-param name="items">
          <xsl:for-each select="item">
            <item>
              <xsl:value-of select="@name" />
              <xsl:if test="node()"> <!-- If there is an expression -->
                <xsl:text> = </xsl:text>
                <xsl:apply-templates mode="output-expression" />
              </xsl:if>
            </item>
          </xsl:for-each>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:text>
} </xsl:text><xsl:value-of select="@name" /><xsl:text>;

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="function" mode="output">
    <xsl:call-template name="type-and-name" />
    <xsl:text>(</xsl:text>
    <xsl:call-template name="list">
      <xsl:with-param name="separator" select="', '" />
      <xsl:with-param name="items">
        <xsl:for-each select="field">
          <item><xsl:apply-templates select="." /></item>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:text>)</xsl:text>

    <xsl:if test="$h"><xsl:text>;
</xsl:text></xsl:if>

    <xsl:if test="$c">
      <xsl:text>
{
</xsl:text>
      <xsl:apply-templates select="l|indent" mode="function-body">
        <xsl:with-param name="indent" select="$indent-string" />
      </xsl:apply-templates>
      <xsl:text>}

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="l" mode="function-body">
    <xsl:param name="indent" />
    <xsl:value-of select="concat($indent, .)" /><xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="indent" mode="function-body">
    <xsl:param name="indent" />
    <xsl:apply-templates select="l|indent" mode="function-body">
      <xsl:with-param name="indent" select="concat($indent, $indent-string)" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="value" mode="output-expression">
    <xsl:value-of select="." />
  </xsl:template>

  <xsl:template match="fieldref" mode="output-expression">
    <xsl:param name="field-prefix" />
    <xsl:value-of select="concat($field-prefix, .)" />
  </xsl:template>

  <xsl:template match="op" mode="output-expression">
    <xsl:param name="field-prefix" />
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="node()[1]" mode="output-expression">
      <xsl:with-param name="field-prefix" select="$field-prefix" />
    </xsl:apply-templates>
    <xsl:text> </xsl:text>
    <xsl:value-of select="@op" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="node()[2]" mode="output-expression">
      <xsl:with-param name="field-prefix" select="$field-prefix" />
    </xsl:apply-templates>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template match="function-call" mode="output-expression">
    <xsl:value-of select="@name" />
    <xsl:text>(</xsl:text>
    <xsl:call-template name="list">
      <xsl:with-param name="separator" select="', '" />
      <xsl:with-param name="items">
        <xsl:for-each select="param">
          <item><xsl:apply-templates mode="output-expression" /></item>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:text>)</xsl:text>
  </xsl:template>

  <xsl:template match="field|exprfield">
    <xsl:call-template name="type-and-name" />
  </xsl:template>

  <xsl:template match="list[@fixed]">
    <xsl:call-template name="type-and-name" />
    <xsl:text>[</xsl:text>
    <xsl:apply-templates mode="output-expression" />
    <xsl:text>]</xsl:text>
  </xsl:template>

  <xsl:template match="pad">
    <xsl:variable name="padnum"><xsl:number /></xsl:variable>

    <xsl:text>CARD8 pad</xsl:text>
    <xsl:value-of select="$padnum - 1" />
    <xsl:if test="@bytes > 1">
      <xsl:text>[</xsl:text>
      <xsl:value-of select="@bytes" />
      <xsl:text>]</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Output the type and name attributes of the context node, with the
       appropriate spacing. -->
  <xsl:template name="type-and-name">
    <xsl:value-of select="@type" />
    <xsl:if test="not(substring(@type, string-length(@type)) = '*')">
      <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:value-of select="@name" />
  </xsl:template>

  <!-- Output a list with a given separator.  Empty items are skipped. -->
  <xsl:template name="list">
    <xsl:param name="separator" />
    <xsl:param name="items" />

    <xsl:for-each select="e:node-set($items)/*">
      <xsl:value-of select="." />
      <xsl:if test="not(position() = last())">
        <xsl:value-of select="$separator" />
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
</xsl:transform>
