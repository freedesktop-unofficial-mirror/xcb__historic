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

  <!--
    Top-level processing.  Check various conditions, then recurse to the root
    node, xcb.
  -->
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

    <xsl:apply-templates />
  </xsl:template>

  <!--
    Process the root node, xcb.
  -->
  <xsl:template match="xcb">
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

    <xsl:if test="$h">
      <xsl:apply-templates mode="declaration" />
      <xsl:apply-templates mode="prototype" />
    </xsl:if>
    <xsl:if test="$c">
      <xsl:apply-templates mode="variable" />
      <xsl:apply-templates mode="function" />
    </xsl:if>

<xsl:if test="$h">
<xsl:text>
#endif
</xsl:text>
</xsl:if>
  </xsl:template>

  <!--
    Process an extension node.
  -->
  <xsl:template match="extension" mode="declaration">
    <xsl:text>extern const char XCB</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>Id[];

</xsl:text>
    <xsl:apply-templates mode="declaration">
      <xsl:with-param name="extension" select="@name" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="extension" mode="variable">
    <xsl:text>const char XCB</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>Id[] = "</xsl:text>
    <xsl:value-of select="@xname" />
    <xsl:text>";

</xsl:text>
    <xsl:apply-templates mode="variable" />
  </xsl:template>

  <xsl:template match="extension" mode="function">
    <xsl:text>const XCBQueryExtensionRep *XCB</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>Init(XCBConnection *c)
{
    return XCBQueryExtensionCached(c, XCB</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>Id, 0);
}

</xsl:text>

    <xsl:apply-templates mode="function">
      <xsl:with-param name="extension" select="@name" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="extension" mode="prototype">
    <xsl:text>const XCBQueryExtensionRep *XCB</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>Init(XCBConnection *c);
</xsl:text>

    <xsl:apply-templates mode="prototype">
      <xsl:with-param name="extension" select="@name" />
    </xsl:apply-templates>
  </xsl:template>

  <!--
    Process a request node and generate the relevant structure declarations.
  -->
  <xsl:template match="request" mode="declaration">
    <xsl:param name="extension" />

    <!-- If there are any replies, define a reply cookie. -->
    <xsl:if test="reply">
      <xsl:call-template name="struct">
        <xsl:with-param name="extension" select="$extension" />
        <xsl:with-param name="name" select="concat(@name, 'Cookie')" />
        <xsl:with-param name="fields">
          <field type="unsigned int" name="sequence" />
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <!-- Define the request structure -->
    <xsl:call-template name="packet-struct">
      <xsl:with-param name="name" select="@name" />
      <xsl:with-param name="extension" select="$extension" />
      <xsl:with-param name="kind" select="'Req'" />
      <xsl:with-param name="fields" select="*[not(self::reply)]" />
    </xsl:call-template>

    <!-- If there are any replies, define the reply structure -->
    <xsl:if test="reply">
      <xsl:call-template name="packet-struct">
        <xsl:with-param name="name" select="@name" />
        <xsl:with-param name="extension" select="$extension" />
        <xsl:with-param name="kind" select="'Rep'" />
        <xsl:with-param name="fields" select="reply/*" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="request" mode="prototype">
    <!-- If there are any replies, the return type is the reply cookie.
         Otherwise, the return type is a void cookie. -->
    <xsl:call-template name="cookie-type" />
    
    <xsl:text> XCB</xsl:text>
    <xsl:call-template name="current-extension" />
    <xsl:value-of select="@name" />
    <xsl:text>(</xsl:text>
    <xsl:call-template name="list">
      <xsl:with-param name="separator" select="', '" />
      <xsl:with-param name="items">
        <item>XCBConnection *c</item>
        <xsl:for-each select="*[not(self::reply)]">
          <item><xsl:apply-templates select="." mode="param" /></item>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:text>);
</xsl:text>

    <!-- If there are any replies, prototype a function to retrieve the
         reply. -->
    <xsl:if test="reply">
      <xsl:text>XCB</xsl:text>
      <xsl:call-template name="current-extension" />
      <xsl:value-of select="@name" />
      <xsl:text>Rep *XCB</xsl:text>
      <xsl:call-template name="current-extension" />
      <xsl:value-of select="@name" />
      <xsl:text>Reply(</xsl:text>
      
      <xsl:call-template name="list">
        <xsl:with-param name="separator" select="', '" />
        <xsl:with-param name="items">
          <item>XCBConnection *c</item>
          <item><xsl:call-template name="cookie-type" /> cookie</item>
          <item>XCBGenericError **e</item>
        </xsl:with-param>
      </xsl:call-template>

      <xsl:text>);
</xsl:text>
    </xsl:if>

  </xsl:template>

  <xsl:template match="request" mode="function">
    <xsl:variable name="in-extension" select="ancestor-or-self::extension" />

    <xsl:call-template name="cookie-type" />
    
    <xsl:text> XCB</xsl:text>
    <xsl:call-template name="current-extension" />
    <xsl:value-of select="@name" />
    <xsl:text>(</xsl:text>
    <xsl:call-template name="list">
      <xsl:with-param name="separator" select="', '" />
      <xsl:with-param name="items">
        <item>XCBConnection *c</item>
        <xsl:for-each select="*[not(self::reply)]">
          <item><xsl:apply-templates select="." mode="param" /></item>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:text>)
{
    struct iovec parts[</xsl:text>
    <!-- FIXME: Variable-length requests are not yet handled. -->
    <xsl:text>1</xsl:text>
    <xsl:text>];
    </xsl:text>
<xsl:call-template name="cookie-type" />
<xsl:text> ret;
    XCB</xsl:text>
    <xsl:call-template name="current-extension" />
    <xsl:value-of select="@name" />
    <xsl:text>Req out;
</xsl:text>
    <xsl:if test="$in-extension">
      <xsl:text>    const XCBQueryExtensionRep *extension = XCB</xsl:text>
      <xsl:call-template name="current-extension" />
      <xsl:text>Init(c);
    const CARD8 major_opcode = extension->major_opcode;
    const CARD8 minor_opcode = </xsl:text>
      <xsl:value-of select="@opcode"/>
      <xsl:text>;

    assert(extension &amp;&amp; extension->present);

    out.major_opcode = major_opcode;
    out.minor_opcode = minor_opcode;
</xsl:text>
    </xsl:if>
    <xsl:if test="not($in-extension)">
      <xsl:text>    const CARD8 major_opcode = </xsl:text>
      <xsl:value-of select="@opcode"/>
      <xsl:text>;

    out.major_opcode = major_opcode;
</xsl:text>
    </xsl:if>

    <xsl:apply-templates select="*[not(self::reply)]" mode="assign" />

    <xsl:text>
    parts[0].iov_base = &amp;out;
    parts[0].iov_len = sizeof(out);
    XCBSendRequest(c, &amp;ret.sequence, /* isvoid */ </xsl:text>
    <xsl:choose>
      <xsl:when test="reply">0</xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
    <xsl:text>, parts, /* partqty */ 1);
    return ret;
}

</xsl:text>

    <xsl:if test="reply">
      <xsl:text>XCB</xsl:text>
      <xsl:call-template name="current-extension" />
      <xsl:value-of select="@name" />
      <xsl:text>Rep *XCB</xsl:text>
      <xsl:call-template name="current-extension" />
      <xsl:value-of select="@name" />
      <xsl:text>Reply(</xsl:text>

      <xsl:call-template name="list">
        <xsl:with-param name="separator" select="', '" />
        <xsl:with-param name="items">
          <item>XCBConnection *c</item>
          <item><xsl:call-template name="cookie-type" /> cookie</item>
          <item>XCBGenericError **e</item>
        </xsl:with-param>
      </xsl:call-template>

      <xsl:text>)
{
    return (XCB</xsl:text>
    <xsl:call-template name="current-extension" />
    <xsl:value-of select="@name" />
    <xsl:text>Rep *) XCBWaitReply(c, cookie.sequence, e);
}
</xsl:text>
    </xsl:if>
<!-- FIXME: Working here. -->
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

  <xsl:template match="field" mode="declaration">
    <xsl:text>    </xsl:text>
    <xsl:value-of select="@type" />
    <xsl:text> </xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>;
</xsl:text>
  </xsl:template>

  <xsl:template match="field" mode="param">
    <xsl:value-of select="@type" />
    <xsl:text> </xsl:text>
    <xsl:value-of select="@name" />
  </xsl:template>

  <xsl:template match="field" mode="assign">
    <xsl:text>    out.</xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text> = </xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>;
</xsl:text>
  </xsl:template>

  <xsl:template match="pad" mode="declaration">
    <xsl:variable name="padnum"><xsl:number /></xsl:variable>

    <xsl:text>    CARD8 pad</xsl:text>
    <xsl:value-of select="$padnum - 1" />
    <xsl:if test="@bytes > 1">
      <xsl:text>[</xsl:text>
      <xsl:value-of select="@bytes" />
      <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>;
</xsl:text>
  </xsl:template>

  <!--
    Helper function to output the name of the current extension, if any.
  -->
  <xsl:template name="current-extension">
    <xsl:value-of select="ancestor-or-self::extension/@name" />
  </xsl:template>

  <!--
    Generate an Event, Error, Rep, or Req structure.
  -->
  <xsl:template name="packet-struct">
    <xsl:param name="name" />      <!-- Structure name -->
    <xsl:param name="extension" /> <!-- The current extension name, if any. -->
    <xsl:param name="kind" />      <!-- Event, Error, Rep, or Req -->
    <xsl:param name="fields" />    <!-- The structure fields. -->

    <!-- Check that the kind parameter is one of the supported kinds. -->
    <xsl:if test="not($kind='Event') and not($kind='Error')
                  and not($kind='Rep') and not($kind='Req')">
      <xsl:message terminate="yes"><!--
        -->Error: Invalid value for kind in packet-struct.<!--
      --></xsl:message>
    </xsl:if>

    <!-- packet-struct collects the provided structure fields together with
         the standard fields for each structure kind, and puts the resulting
         list of fields in fields2.  It then adds the length and/or sequence
         fields at the appropriate location. -->
    <xsl:variable name="fields2-rtf">
      <!-- Add the opcode fields. -->
      <xsl:if test="$kind = 'Req'">
        <field type="CARD8" name="major_opcode" />
        <xsl:if test="$extension">
          <field type="CARD8" name="minor_opcode" />        
        </xsl:if>
      </xsl:if>
      
      <!-- Everything except requests has a response type field. -->
      <xsl:if test="not($kind = 'Req')">
        <field type="BYTE" name="response_type" />
      </xsl:if>
      
      <!-- Errors have an error code field. -->
      <xsl:if test="$kind = 'Error'">
        <field type="BYTE" name="error_code" />
      </xsl:if>
      
      <!-- Add the remaining fields. -->
      <xsl:copy-of select="e:node-set($fields)" />
    </xsl:variable>
    <xsl:variable name="fields2" select="e:node-set($fields2-rtf)/*" />

    <xsl:call-template name="struct">
      <xsl:with-param name="extension" select="$extension" />
      <xsl:with-param name="name" select="concat($name, $kind)" />
      <xsl:with-param name="fields">
        <!-- FIXME: This should go by size, not number of fields. -->
        <xsl:copy-of select="$fields2[position() &lt; 3]" />
        <xsl:if test="count($fields2) &lt; 2">
          <pad bytes="{2 - count($fields2)}" />
        </xsl:if>
        <!-- Everything except requests has a sequence field. -->
        <xsl:if test="not($kind = 'Req')">
          <field type="CARD16" name="sequence" />
        </xsl:if>
        <!-- Requests have a CARD16 length field. -->
        <xsl:if test="$kind = 'Req'">
          <field type="CARD16" name="length" />
        </xsl:if>
        <!-- Replies have a CARD32 length field. -->
        <xsl:if test="$kind = 'Rep'">
          <field type="CARD32" name="length" />
        </xsl:if>
        <xsl:copy-of select="$fields2[position() > 2]" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!--
    Output a structure definition.
  -->
  <xsl:template name="struct">
    <xsl:param name="extension" />
    <xsl:param name="name" />
    <xsl:param name="fields" />
    
    <xsl:text>typedef struct {
</xsl:text>
    <xsl:apply-templates select="e:node-set($fields)" mode="declaration" />
    <xsl:text>} XCB</xsl:text>
    <xsl:value-of select="$extension" />
    <xsl:value-of select="$name" />
    <xsl:text>;

</xsl:text>
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