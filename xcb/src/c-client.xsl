<?xml version="1.0" encoding="utf-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               version="1.0"
               xmlns:e="http://exslt.org/common">
  
  <xsl:output method="text" />

  <xsl:strip-space elements="*" />

  <xsl:param name="mode" /> <!-- "header" or "source" -->

  <xsl:variable name="h" select="$mode = 'header'" />
  <xsl:variable name="c" select="$mode = 'source'" />
  
  <xsl:variable name="ucase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
  <xsl:variable name="lcase" select="'abcdefghijklmnopqrstuvwxyz'" />

  <xsl:variable name="header" select="/xcb/@header" />
  <xsl:variable name="ucase-header"
                select="translate($header,$lcase,$ucase)" />
  
  <!-- First pass: Store everything in a variable. -->
  <xsl:variable name="pass1-rtf">
    <xsl:apply-templates select="/" mode="pass1" />
  </xsl:variable>
  <xsl:variable name="pass1" select="e:node-set($pass1-rtf)" />
  
  <xsl:template match="/" mode="pass1">
    <xsl:apply-templates mode="pass1" />
  </xsl:template>

  <xsl:template match="xcb" mode="pass1">
    <xcb header="{@header}">
      <xsl:apply-templates mode="pass1" />
    </xcb>
  </xsl:template>

  <xsl:template match="extension" mode="pass1">
    <extension xname="{@xname}" name="{@name}">
      <constant type="string" name="XCB{@name}Id" value="{@xname}" />
      <function type="const XCBQueryExtensionRep *" name="XCB{@name}Init">
        <field type="XCBConnection *" name="c" />
        <l>return XCBQueryExtensionCached(c, XCB<!--
        --><xsl:call-template name="current-extension" />Id, 0);</l>
      </function>
      <xsl:apply-templates mode="pass1" />
    </extension>
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
    XCB{current-extension}Type if the type exists in the current extension or
    the current top-level description if not in an extension, XCBType if the
    type exists in xproto or xcb_types, and Type otherwise.  If the type
    parameter is not specified, it defaults to the value of the type attribute
    on the context node.
  -->
  <xsl:template name="canonical-type-name">
    <xsl:param name="type" select="@type" />
    <xsl:variable name="ext-retval"><!--
      --><xsl:call-template name="current-extension" /><!--
    --></xsl:variable>
    <xsl:variable name="ext" select="string($ext-retval)" />
    <xsl:choose>
      <!-- First search the current extension/top-level. -->
      <xsl:when test="(/xcb[not($ext)]
                      |/xcb/extension[@name=$ext]
                      )/*[((self::struct or self::union
                            or self::xidtype or self::enum
                            or self::event or self::eventcopy
                            or self::error or self::errorcopy) and @name=$type)
                          or (self::typedef and @newname=$type)]">
        <xsl:text>XCB</xsl:text>
        <xsl:value-of select="concat($ext, $type)" />
      </xsl:when>
      <!-- If this is not xproto or xcb_types, search xproto next (which will
           then search xcb_types if necessary). -->
      <xsl:when test="/xcb[not(@header='xcb_types')
                           and not(@header='xproto')]">
        <xsl:for-each select="document('xproto.xml')/xcb">
          <xsl:call-template name="canonical-type-name">
            <xsl:with-param name="type" select="$type" />
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <!-- If this is xproto, search xcb_types next. -->
      <xsl:when test="/xcb[@header='xproto']">
        <xsl:for-each select="document('xcb_types.xml')/xcb">
          <xsl:call-template name="canonical-type-name">
            <xsl:with-param name="type" select="$type" />
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <!-- The type was not found; assume it is already defined somewhere. -->
      <xsl:otherwise>
        <xsl:value-of select="$type" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Helper template for requests, that outputs the cookie type.  The
       context node must be the request. -->
  <xsl:template name="cookie-type">
    <xsl:text>XCB</xsl:text>
    <xsl:choose>
      <xsl:when test="reply">
        <xsl:call-template name="current-extension" />
        <xsl:value-of select="@name" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Void</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>Cookie</xsl:text>
  </xsl:template>

  <xsl:template match="request" mode="pass1">
    <xsl:variable name="ext-retval"><!--
      --><xsl:call-template name="current-extension" /><!--
    --></xsl:variable>
    <xsl:variable name="ext" select="string($ext-retval)" />
    <xsl:if test="reply">
      <struct name="XCB{$ext}{@name}Cookie">
        <field type="unsigned int" name="sequence" />
      </struct>
    </xsl:if>
    <struct name="XCB{$ext}{@name}Req">
      <field type="CARD8" name="major_opcode" />
      <xsl:if test="$ext"><field type="CARD8" name="minor_opcode" /></xsl:if>
      <xsl:apply-templates select="*[not(self::reply)]" mode="field" />
      <middle>
        <field type="CARD16" name="length" />
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
          <xsl:attribute name="has-reply">yes</xsl:attribute>
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
      <function type="XCB{$ext}{@name}Rep *" name="XCB{$ext}{@name}Reply">
        <field type="XCBConnection *" name="c" />
        <field name="cookie">
          <xsl:attribute name="type">
            <xsl:call-template name="cookie-type" />
          </xsl:attribute>
        </field>
        <field type="XCBGenericError **" name="e" />
        <l>return (XCB<xsl:value-of select="concat($ext, @name)" />Rep *)<!--
        --> XCBWaitReply(c, cookie.sequence, e);</l>
      </function>
    </xsl:if>
  </xsl:template>

  <!-- Create the Iter structure for a structure with the given name.  If the
       name is not supplied, it defaults to the value of the name attribute of
       the context node. -->
  <xsl:template name="make-iterator">
    <xsl:param name="name" select="@name" />
    <xsl:variable name="ext-retval"><!--
      --><xsl:call-template name="current-extension" /><!--
    --></xsl:variable>
    <xsl:variable name="ext" select="string($ext-retval)" />
    <struct name="XCB{$ext}{$name}Iter">
      <field type="XCB{$ext}{$name} *" name="data" />
      <field type="int" name="rem" />
      <field type="int" name="index" />
    </struct>
  </xsl:template>

  <xsl:template match="xidtype" mode="pass1">
    <xsl:variable name="ext-retval"><!--
      --><xsl:call-template name="current-extension" /><!--
    --></xsl:variable>
    <xsl:variable name="ext" select="string($ext-retval)" />
    <struct name="XCB{$ext}{@name}">
      <field type="CARD32" name="xid" />
    </struct>
    <function type="XCB{$ext}{@name}" name="XCB{$ext}{@name}New">
      <field type="XCBConnection *" name="c" />
      <l>XCB<xsl:value-of select="concat($ext, @name)" /> ret;</l>
      <l>ret.xid = XCBGenerateID(c);</l>
      <l>return ret;</l>
    </function>
    <xsl:call-template name="make-iterator" />
  </xsl:template>

  <xsl:template match="struct|union" mode="pass1">
    <xsl:variable name="ext-retval"><!--
      --><xsl:call-template name="current-extension" /><!--
    --></xsl:variable>
    <xsl:variable name="ext" select="string($ext-retval)" />
    <struct name="XCB{$ext}{@name}">
      <xsl:if test="self::union">
        <xsl:attribute name="kind">union</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="*" mode="field" />
    </struct>
    <xsl:call-template name="make-iterator" />
  </xsl:template>

  <xsl:template match="event|eventcopy|error|errorcopy" mode="pass1">
    <xsl:variable name="ext-retval"><!--
      --><xsl:call-template name="current-extension" /><!--
    --></xsl:variable>
    <xsl:variable name="ext" select="string($ext-retval)" />
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

  <!--
    Templates for processing fields.
  -->

  <xsl:template match="pad" mode="field">
    <xsl:copy-of select="." />
  </xsl:template>
  
  <xsl:template match="field" mode="field">
    <field>
      <xsl:attribute name="type">
        <xsl:call-template name="canonical-type-name" />
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:call-template name="canonical-var-name" />
      </xsl:attribute>
    </field>
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
    
    <!-- Second pass: Process the variable. -->
    <xsl:apply-templates select="$pass1/*" mode="pass2" />
  </xsl:template>

  <xsl:template match="xcb" mode="pass2">
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

</xsl:text></xsl:if>

<xsl:if test="$c"><xsl:text>
#include &lt;assert.h&gt;
#include "xcb.h"
#include "</xsl:text><xsl:value-of select="$header" /><xsl:text>.h"

</xsl:text></xsl:if>

    <xsl:apply-templates mode="pass2" select="//constant|//struct|//typedef" />
    <xsl:apply-templates mode="pass2" select="//function" />

<xsl:if test="$h">
<xsl:text>
#endif
</xsl:text>
</xsl:if>
  </xsl:template>

  <xsl:template match="constant" mode="pass2">
    <xsl:if test="(@type = 'number') and $h">
      <xsl:text>#define </xsl:text>
      <xsl:value-of select="@name" />
      <xsl:text> </xsl:text>
      <xsl:value-of select="@value" />
      <xsl:text>

</xsl:text>
    </xsl:if>
    <xsl:if test="@type = 'string'">
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
    </xsl:if>
  </xsl:template>

  <xsl:template match="typedef" mode="pass2">
    <xsl:if test="$h">
      <xsl:text>typedef </xsl:text>
      <xsl:value-of select="@oldname" />
      <xsl:text> </xsl:text>
      <xsl:value-of select="@newname" />
      <xsl:text>;

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="struct" mode="pass2">
    <xsl:if test="$h">
      <xsl:variable name="fields">
        <!-- FIXME: This should go by size, not number of fields. -->
        <xsl:copy-of select="node()[not(self::middle)
                                    and position() &lt; 3]" />
        <xsl:if test="middle and (count(*[not(self::middle)]) &lt; 2)">
          <pad bytes="{2 - count(*[not(self::middle)])}" />
        </xsl:if>
        <xsl:copy-of select="middle/*" />
        <xsl:copy-of select="node()[not(self::middle) and (position() > 2)]" />
      </xsl:variable>

      <xsl:text>typedef </xsl:text>
      <xsl:if test="not(@kind)">struct</xsl:if><xsl:value-of select="@kind" />
      <xsl:text> {
</xsl:text>
      <xsl:for-each select="e:node-set($fields)/*">
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

  <xsl:template match="function" mode="pass2">
    <xsl:variable name="ext-retval"><!--
      --><xsl:call-template name="current-extension" /><!--
    --></xsl:variable>
    <xsl:variable name="ext" select="string($ext-retval)" />

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
      <xsl:for-each select="l|do-request">
        <xsl:if test="self::l">
          <xsl:text>    </xsl:text><xsl:value-of select="." /><xsl:text>
</xsl:text>
        </xsl:if>
        <xsl:if test="self::do-request">
<xsl:text>    struct iovec parts[</xsl:text>
<!-- FIXME: Variable-length requests are not yet handled. -->
<xsl:text>1</xsl:text>
<xsl:text>];
    </xsl:text><xsl:value-of select="../@type" /><xsl:text> ret;
    </xsl:text><xsl:value-of select="@ref" /><xsl:text> out;
</xsl:text>
<xsl:if test="$ext">
<xsl:text>    const XCBQueryExtensionRep *extension = XCB</xsl:text>
<xsl:value-of select="$ext" />
<xsl:text>Init(c);
    const CARD8 major_opcode = extension->major_opcode;
    const CARD8 minor_opcode = </xsl:text><xsl:value-of select="@opcode"/>
<xsl:text>;

    assert(extension &amp;&amp; extension->present);

</xsl:text>
</xsl:if>
<xsl:if test="not($ext)">
<xsl:text>    const CARD8 major_opcode = </xsl:text>
<xsl:value-of select="@opcode" />
<xsl:text>;

</xsl:text>
</xsl:if>

<xsl:for-each select="$pass1//struct[@name = current()/@ref]/*">
  <xsl:choose>
    <xsl:when test="self::field">
      <xsl:text>    out.</xsl:text><xsl:value-of select="@name" />
      <xsl:text> = </xsl:text><xsl:value-of select="@name" /><xsl:text>;
</xsl:text>
    </xsl:when>
  </xsl:choose>
</xsl:for-each>

<xsl:text>
    parts[0].iov_base = &amp;out;
    parts[0].iov_len = sizeof(out);
    XCBSendRequest(c, &amp;ret.sequence, /* isvoid */ </xsl:text>
    <xsl:choose>
      <xsl:when test="@has-reply = 'yes'">0</xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
    <xsl:text>, parts, /* partqty */ 1);
    return ret;
</xsl:text>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>}

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="field">
    <xsl:call-template name="type-and-name" />
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

  <!--
    Helper function to output the name of the current extension, if any.
  -->
  <xsl:template name="current-extension">
    <xsl:value-of select="string(ancestor-or-self::extension/@name)" />
  </xsl:template>
</xsl:transform>
