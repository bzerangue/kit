<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:str="http://exslt.org/strings"
	exclude-element-prefixes="str">

<!--
	Twitter
-->
<xsl:template match="statuses" mode="twitter">
	<xsl:param name="tweeted" select="'tweeted at {$date}'" />
	<xsl:param name="retweeted" select="'retweeted at {$date}'" />
	<xsl:param name="replies" select="true()" />
	<xsl:param name="max" select="10" />
	<xsl:param name="format" />

	<ul class="twitter">
		<xsl:choose>
			
			<!-- Include replies -->
			<xsl:when test="$replies = true()">
				<xsl:apply-templates select="status[position() &lt;= $max]" mode="twitter">
					<xsl:with-param name="tweeted" select="$tweeted" />
					<xsl:with-param name="retweeted" select="$retweeted" />
					<xsl:with-param name="format" select="$format" />
				</xsl:apply-templates>
			</xsl:when>
			
			<!-- Exclude replies -->
			<xsl:otherwise>
				<xsl:apply-templates select="status[not(starts-with(text, '@'))][position() &lt;= $max]" mode="twitter">
					<xsl:with-param name="tweeted" select="$tweeted" />
					<xsl:with-param name="retweeted" select="$retweeted" />
					<xsl:with-param name="format" select="$format" />
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</ul>
</xsl:template>

<!-- List of tweets -->
<xsl:template match="status" mode="twitter">
	<xsl:param name="tweeted" />
	<xsl:param name="retweeted" />
	<xsl:param name="format" />

	<li>
		<xsl:apply-templates select="." mode="tweet">
			<xsl:with-param name="tweeted" select="$tweeted" />
			<xsl:with-param name="retweeted" select="$retweeted" />
			<xsl:with-param name="format" select="$format" />
		</xsl:apply-templates>
	</li>
</xsl:template>

<!-- Tweet -->
<xsl:template match="status" mode="tweet">
	<xsl:param name="tweeted" />
	<xsl:param name="retweeted" />
	<xsl:param name="format" />

	<xsl:choose>
	
		<!-- Retweet -->
		<xsl:when test="retweeted_status/*">
			<p>
				<xsl:if test="retweeted_status/*">
					<xsl:attribute name="class">retweeted</xsl:attribute>
				</xsl:if>
				
				<!-- Author -->
				<xsl:value-of select="retweeted_status/user/name" />
				<xsl:text>, @</xsl:text>
				<a href="https://twitter.com/{retweeted_status/user/screen_name}" title="{retweeted_status/user/name}" class="author">
					<xsl:value-of select="retweeted_status/user/screen_name" />
				</a>
				<xsl:text>:</xsl:text>
				<br />
		
				<!-- Text -->
				<xsl:apply-templates select="str:tokenize(retweeted_status/text,' ')" mode="tweet">
					<xsl:with-param name="tweet" select="." />
				</xsl:apply-templates>
			</p>
				
			<!-- Reference -->
			<xsl:call-template name="twitter-reference">
				<xsl:with-param name="text" select="$retweeted" />
				<xsl:with-param name="user" select="retweeted_status/user/screen_name" />
				<xsl:with-param name="date" select="created_at" />
				<xsl:with-param name="format" select="$format" />
				<xsl:with-param name="link" select="concat('https://twitter.com/', user/screen_name, '/status/', id)" />
			</xsl:call-template>
		</xsl:when>
		
		<!-- Original Tweet -->
		<xsl:otherwise>
			<p>
			
				<!-- Text -->
				<xsl:apply-templates select="str:tokenize(text,' ')" mode="tweet">
					<xsl:with-param name="tweet" select="." />
				</xsl:apply-templates>
			</p>
				
			<!-- Reference -->
			<xsl:call-template name="twitter-reference">
				<xsl:with-param name="text" select="$tweeted" />
				<xsl:with-param name="date" select="created_at" />
				<xsl:with-param name="format" select="$format" />
				<xsl:with-param name="link" select="concat('https://twitter.com/', user/screen_name, '/status/', id)" />
			</xsl:call-template>
		</xsl:otherwise>			
	</xsl:choose>
</xsl:template>

<!-- Text -->
<xsl:template match="token" mode="tweet">
	<xsl:value-of select="." />
	<xsl:text> </xsl:text>
</xsl:template>

<!-- Username -->
<xsl:template match="token[starts-with(., '@')]" mode="tweet" priority="1">
	<xsl:param name="tweet" />
	<xsl:variable name="user" select="$tweet/entities/user_mentions/user_mention[screen_name = substring-after(current(), '@')]" />

	<xsl:text>@</xsl:text>
	<a href="https://twitter.com/{$user/screen_name}" title="{$user/name}">
		<xsl:value-of select="$user/screen_name" />
	</a>
	<xsl:text> </xsl:text>
</xsl:template>

<!-- Hashtag -->
<xsl:template match="token[starts-with(., '#')]" mode="tweet" priority="1">
	<xsl:param name="tweet" />
	<xsl:variable name="tag" select="substring-after(., '#')" />

	<xsl:text>#</xsl:text>
	<a href="https://twitter.com/search?q=%23{$tag}">
		<xsl:value-of select="$tag" />
	</a>
	<xsl:text> </xsl:text>
</xsl:template>

<!-- Link -->
<xsl:template match="token[starts-with(., 'http')]" mode="tweet" priority="1">
	<xsl:param name="tweet" />
	<xsl:variable name="url" select="$tweet/entities/urls/url[url = current()]" />

	<a href="{$url/expanded_url}">
		<xsl:value-of select="$url/display_url"/>
	</a>
	<xsl:text> </xsl:text>
</xsl:template>

<!-- Reference -->
<xsl:template name="twitter-reference">
	<xsl:param name="text" />
	<xsl:param name="user" />
	<xsl:param name="date" />
	<xsl:param name="format" />
	<xsl:param name="link" />
	
	<xsl:variable name="replace-date">
		<xsl:copy-of select="substring-before($text, '{$date}')" />
		<xsl:call-template name="datetime-twitter">
			<xsl:with-param name="date" select="$date" />
			<xsl:with-param name="format" select="$format" />
			<xsl:with-param name="lang" select="substring($ds-sprache, 1, 2)" />
		</xsl:call-template>
		<xsl:copy-of select="substring-after($text, '{$date}')" />
	</xsl:variable>

	<footer>
		<a href="{$link}">
			<xsl:value-of select="$replace-date" />
		</a>
	</footer>
</xsl:template>

</xsl:stylesheet>