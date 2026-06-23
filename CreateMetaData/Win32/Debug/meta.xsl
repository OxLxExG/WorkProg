<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:array="http://www.w3.org/2005/xpath-functions/array"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:math="http://www.w3.org/2005/xpath-functions/math"
                exclude-result-prefixes="#all"
                expand-text="yes"
                version="3.0">
  
  <xsl:output method="xhtml" indent="yes"/>
  <xsl:mode on-no-match="shallow-copy"/>
  
  <xsl:template match="/" mode="#all">
    <html>
      <head>
        <!-- <link rel="stylesheet" type="text/css" href="file:///C:/XE/Projects/Device2/CreateMetaData/formats.css"></link> -->
      </head>
      <body>
        <div>
          <xsl:apply-templates select="//struct_t[@WRK]" />
        </div>
        <!-- <script>
        <xsl:text disable-output-escaping="yes">          
          var toggler = document.getElementsByClassName("caret");
          var i;          
          for (i = 0; i != toggler.length; i++) 
            toggler[i].addEventListener("click", function() 
              {string("{")}
                this.parentElement.querySelector(".nested").classList.toggle("active")
                this.classList.toggle("caret-down")
              {string("}")}
             )
        </xsl:text>
        </script> -->
        </body>
      </html>
    </xsl:template>
    
    <xsl:template match="struct_t[@WRK]" mode="#default">        
      device: <b style="color:teal"><xsl:value-of select="../@name"/></b>
      <xsl:for-each select="../@*[name() != 'name']">
        <div style="margin-left: 16px">
          <small style="color:#923800"> 
            <xsl:value-of select="name()"/>=<xsl:value-of select="."/> 
          </small>  
        </div>
      </xsl:for-each>
      <ul style="margin-top: 4px">
        <xsl:call-template name="struct">
          <xsl:with-param name="caption" select="'Режим информации'"/>
        </xsl:call-template>    
      </ul>
    </xsl:template>
    
    <xsl:template name="struct">
      <xsl:param name="caption" select="@name"/>
      <b style="color:blue" class="caret"><xsl:value-of select="$caption"/> </b>
      <xsl:if test="@arrayIdx">
        [<xsl:value-of select="@arrayIdx"/>]
      </xsl:if>
      <small style="color:gray"> 
        <sub>
          <xsl:if test="@metr">
            <xsl:value-of select="@metr"/>
          </xsl:if>     
          sz: <xsl:value-of select="@size"/>
        </sub> 
      </small>     
      <xsl:call-template name="attr"/>
      <ul class="nested"> 
        <xsl:for-each select="*">  
          <li> 
            <xsl:if test="name() != 'struct_t'">
              <xsl:call-template name="data"/>
            </xsl:if>   
            <xsl:if test="name() = 'struct_t'">
              <xsl:call-template name="struct"/>
            </xsl:if>   
          </li>
        </xsl:for-each>
      </ul>
    </xsl:template>
    
    <xsl:template name="data">
      <xsl:value-of select="name()"/>  
      <small style="color:gray"> 
        <sub>
          <xsl:value-of select="@tip "/> 
        </sub> 
      </small>      
      <xsl:choose>
        <xsl:when test="@name">
          : <b style="color:green"> <xsl:value-of select="@name"/> </b>        
        </xsl:when>
        <xsl:otherwise>
          : <b style="color:red"> noname </b>        
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="@array">
        [<xsl:value-of select="@array"/>]
      </xsl:if>
      = <b><xsl:value-of select="text()"/><xsl:value-of select="@eu"/></b>
      <xsl:call-template name="attr"/>
    </xsl:template>           
    
    <xsl:template name="attr">
      <small style="color:#6CA2BB"> 
        <xsl:for-each select="./@*[(name() != 'tip') 
            and (name() != 'array')
            and (name() != 'name')
            and (name() != 'eu')
            and (name() != 'size') 
            and (name() != 'WRK') 
            and (name() != 'arrayIdx')
            and (name() != 'metr')]">
          : <xsl:value-of select="name()"/>=<xsl:value-of select="."/> 
        </xsl:for-each>
      </small>  
    </xsl:template>
    
  </xsl:stylesheet>
  
  
