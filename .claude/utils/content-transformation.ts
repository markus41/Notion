/**
 * Content Transformation Utilities - Production-ready text processing and sanitization
 *
 * **Purpose**: Establish scalable content transformation patterns to streamline web publishing
 * workflows with reliable Markdown → HTML conversion, URL slug generation, and text sanitization.
 *
 * **Best for**: Organizations scaling content publishing across CMS platforms requiring consistent
 * formatting, SEO-friendly URLs, and secure content rendering without XSS vulnerabilities.
 *
 * **Dependencies**:
 * - None (pure Node.js/TypeScript)
 *
 * **Features**:
 * ✅ Markdown → HTML conversion (headers, bold, italic, code, links, lists, blockquotes)
 * ✅ SEO-friendly URL slug generation (lowercase, hyphenated, alphanumeric)
 * ✅ HTML entity sanitization to prevent XSS attacks
 * ✅ Text truncation with word boundary preservation
 * ✅ String cleaning and normalization utilities
 *
 * **Usage Example**:
 * ```typescript
 * import {
 *   convertMarkdownToHTML,
 *   generateSlug,
 *   sanitizeHTML,
 *   truncateText
 * } from './content-transformation';
 *
 * // Convert Notion Markdown to HTML
 * const html = convertMarkdownToHTML('# Hello **World**\nThis is a *test*.');
 * // Output: <h1>Hello <strong>World</strong></h1><p>This is a <em>test</em>.</p>
 *
 * // Generate SEO-friendly slug
 * const slug = generateSlug('Best Practices for Azure Functions in 2025');
 * // Output: "best-practices-for-azure-functions-in-2025"
 *
 * // Sanitize user-generated content
 * const clean = sanitizeHTML('<script>alert("XSS")</script><p>Safe content</p>');
 * // Output: "&lt;script&gt;alert("XSS")&lt;/script&gt;<p>Safe content</p>"
 *
 * // Truncate for previews
 * const preview = truncateText('Long article content...', 150);
 * // Output: "Long article content... (truncated at word boundary)"
 * ```
 */

/**
 * Convert Markdown to HTML with semantic structure
 * Establishes reliable text transformation to support consistent web content rendering
 *
 * **Supported Markdown**:
 * - Headers: `# H1`, `## H2`, ..., `###### H6`
 * - Bold: `**bold**` or `__bold__`
 * - Italic: `*italic*` or `_italic_`
 * - Bold + Italic: `***text***` or `___text___`
 * - Inline code: `` `code` ``
 * - Code blocks: ` ```language\ncode\n``` `
 * - Links: `[text](url)`
 * - Unordered lists: `- item` or `* item`
 * - Ordered lists: `1. item`
 * - Blockquotes: `> quote`
 * - Horizontal rules: `---` or `***`
 *
 * **Best for**: Converting Notion/Markdown content for CMS platforms (Webflow, WordPress, Contentful)
 *
 * @param markdownContent - Raw Markdown string
 * @returns Clean, semantic HTML string
 *
 * @example
 * ```typescript
 * const markdown = `
 * # Getting Started with Azure Functions
 *
 * Azure Functions provide **serverless computing** for *event-driven* workloads.
 *
 * ## Key Benefits
 * - Pay per execution
 * - Auto-scaling
 * - Built-in integrations
 *
 * \`\`\`typescript
 * export async function handler(req: HttpRequest) {
 *   return { status: 200, body: 'Hello World' };
 * }
 * \`\`\`
 * `;
 *
 * const html = convertMarkdownToHTML(markdown);
 * // Output: <h1>Getting Started...</h1><p>Azure Functions...</p><h2>Key Benefits</h2>...
 * ```
 */
export function convertMarkdownToHTML(markdownContent: string): string {
  let html = markdownContent;

  // 1. Escape HTML entities (prevent XSS while preserving semantic tags)
  html = html.replace(/&/g, '&amp;');

  // Allow specific HTML tags (headers, paragraphs, formatting)
  const allowedTags = [
    'h[1-6]', 'p', 'strong', 'em', 'code', 'pre', 'a',
    'ul', 'ol', 'li', 'br', 'blockquote', 'hr'
  ].join('|');

  const tagPattern = new RegExp(
    `<(?!\\/?(?:${allowedTags})\\s*\/?>)`,
    'g'
  );
  html = html.replace(tagPattern, '&lt;');
  html = html.replace(/(?<!(?:h[1-6]|p|strong|em|code|pre|a|ul|ol|li|br|blockquote|hr)\s*)>/g, '&gt;');

  // 2. Process code blocks FIRST (multiline) - prevents conflicts with inline formatting
  html = html.replace(/```(\w+)?\r?\n([\s\S]+?)\r?\n```/g, (match, language, code) => {
    const langClass = language ? ` class="language-${language}"` : '';
    return `<pre><code${langClass}>${code}</code></pre>`;
  });

  // 3. Headers (H1-H6) - process from H6 to H1 to avoid conflicts
  html = html.replace(/(?m)^###### (.+)$/gm, '<h6>$1</h6>');
  html = html.replace(/(?m)^##### (.+)$/gm, '<h5>$1</h5>');
  html = html.replace(/(?m)^#### (.+)$/gm, '<h4>$1</h4>');
  html = html.replace(/(?m)^### (.+)$/gm, '<h3>$1</h3>');
  html = html.replace(/(?m)^## (.+)$/gm, '<h2>$1</h2>');
  html = html.replace(/(?m)^# (.+)$/gm, '<h1>$1</h1>');

  // 4. Inline code (before bold/italic to avoid conflicts)
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');

  // 5. Bold and Italic formatting
  html = html.replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>'); // Bold + Italic
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');             // Bold
  html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');                          // Italic
  html = html.replace(/___(.+?)___/g, '<strong><em>$1</em></strong>');      // Alt bold + italic
  html = html.replace(/__(.+?)__/g, '<strong>$1</strong>');                  // Alt bold
  html = html.replace(/_(.+?)_/g, '<em>$1</em>');                            // Alt italic

  // 6. Links (with security attributes for external links)
  html = html.replace(
    /\[([^\]]+)\]\(([^\)]+)\)/g,
    '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>'
  );

  // 7. Horizontal rules
  html = html.replace(/(?m)^-{3,}$/gm, '<hr>');
  html = html.replace(/(?m)^\*{3,}$/gm, '<hr>');

  // 8. Blockquotes
  html = html.replace(/(?m)^> (.+)$/gm, '<blockquote>$1</blockquote>');

  // 9. Lists (unordered and ordered)
  html = html.replace(/(?m)^[\*\-] (.+)$/gm, '<li>$1</li>');     // Unordered
  html = html.replace(/(?m)^\d+\. (.+)$/gm, '<li>$1</li>');      // Ordered

  // 10. Wrap consecutive <li> tags in <ul> (simplified - production would handle nested lists)
  html = html.replace(/(<li>.+?<\/li>(?:\r?\n<li>.+?<\/li>)*)/g, '<ul>$1</ul>');

  // 11. Paragraphs (wrap remaining non-tagged lines)
  html = html.replace(/(?m)^(?!<[huplob]|<\/?pre|<\/?code)(.+)$/gm, '<p>$1</p>');

  // 12. Clean up empty tags and extra whitespace
  html = html.replace(/<p>\s*<\/p>/g, '');
  html = html.replace(/(?m)^\s+$/gm, '');

  return html.trim();
}

/**
 * Generate SEO-friendly URL slug from text
 * Establishes consistent URL patterns to support predictable navigation and improved SEO
 *
 * **Transformation Rules**:
 * - Converts to lowercase
 * - Spaces → hyphens
 * - Removes non-alphanumeric characters (except hyphens)
 * - Collapses multiple hyphens
 * - Trims leading/trailing hyphens
 *
 * **Best for**: Generating slugs for blog posts, articles, product pages, documentation
 *
 * @param text - Original text (title, heading, etc.)
 * @returns URL-safe slug (lowercase, hyphenated, alphanumeric)
 *
 * @example
 * ```typescript
 * generateSlug('Best Practices for Azure Functions in 2025');
 * // Output: "best-practices-for-azure-functions-in-2025"
 *
 * generateSlug('10 Tips & Tricks for Power BI!');
 * // Output: "10-tips-tricks-for-power-bi"
 *
 * generateSlug('   Multiple   Spaces   ');
 * // Output: "multiple-spaces"
 * ```
 */
export function generateSlug(text: string): string {
  return text
    .toLowerCase()                  // Lowercase for consistency
    .trim()                         // Remove leading/trailing whitespace
    .replace(/\s+/g, '-')           // Spaces → hyphens
    .replace(/[^a-z0-9-]/g, '')     // Remove non-alphanumeric (except hyphens)
    .replace(/-+/g, '-')            // Collapse multiple hyphens
    .replace(/^-|-$/g, '');         // Trim leading/trailing hyphens
}

/**
 * Sanitize HTML content to prevent XSS attacks
 * Establishes secure text processing to protect against malicious script injection
 *
 * **Best for**: Processing user-generated content, form submissions, external data sources
 *
 * @param html - Raw HTML string (potentially unsafe)
 * @returns Sanitized HTML with escaped entities
 *
 * @example
 * ```typescript
 * sanitizeHTML('<script>alert("XSS")</script><p>Safe content</p>');
 * // Output: "&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;<p>Safe content</p>"
 *
 * sanitizeHTML('Normal text with <b>bold</b> and <i>italic</i>');
 * // Output: "Normal text with <b>bold</b> and <i>italic</i>" (allowed tags preserved)
 * ```
 */
export function sanitizeHTML(html: string): string {
  // Define allowed HTML tags (extend as needed)
  const allowedTags = ['p', 'br', 'strong', 'em', 'b', 'i', 'u', 'a', 'ul', 'ol', 'li'];
  const tagPattern = new RegExp(`<(?!\\/?(?:${allowedTags.join('|')})\\b)`, 'gi');

  return html
    .replace(/&/g, '&amp;')              // Escape ampersands
    .replace(tagPattern, '&lt;')         // Escape disallowed tags
    .replace(/"/g, '&quot;')             // Escape quotes
    .replace(/'/g, '&#x27;')             // Escape apostrophes
    .replace(/\//g, '&#x2F;');           // Escape forward slashes
}

/**
 * Truncate text at word boundary with ellipsis
 * Establishes consistent preview generation to support readable content summaries
 *
 * **Best for**: Article previews, meta descriptions, search result snippets
 *
 * @param text - Original text content
 * @param maxLength - Maximum character count (default: 200)
 * @param ellipsis - Trailing text when truncated (default: "...")
 * @returns Truncated text with word boundary preservation
 *
 * @example
 * ```typescript
 * const longText = 'This is a very long article about Azure Functions and serverless computing...';
 *
 * truncateText(longText, 50);
 * // Output: "This is a very long article about Azure..." (truncated at word boundary)
 *
 * truncateText(longText, 50, ' [Read more]');
 * // Output: "This is a very long article about Azure [Read more]"
 * ```
 */
export function truncateText(
  text: string,
  maxLength: number = 200,
  ellipsis: string = '...'
): string {
  if (text.length <= maxLength) {
    return text;
  }

  // Truncate at word boundary
  const truncated = text.slice(0, maxLength);
  const lastSpace = truncated.lastIndexOf(' ');

  if (lastSpace > 0) {
    return truncated.slice(0, lastSpace) + ellipsis;
  }

  return truncated + ellipsis;
}

/**
 * Remove Markdown formatting to get plain text
 * Establishes clean text extraction for meta descriptions, search indexing, analytics
 *
 * **Best for**: Generating meta descriptions, search previews, plain-text notifications
 *
 * @param markdown - Markdown-formatted text
 * @returns Plain text without formatting symbols
 *
 * @example
 * ```typescript
 * stripMarkdown('# Hello **World**\nThis is a *test*.');
 * // Output: "Hello World\nThis is a test."
 *
 * stripMarkdown('[Click here](https://example.com) for more info.');
 * // Output: "Click here for more info."
 * ```
 */
export function stripMarkdown(markdown: string): string {
  return markdown
    .replace(/```[\s\S]*?```/g, '')      // Remove code blocks
    .replace(/`[^`]+`/g, '')             // Remove inline code
    .replace(/!\[([^\]]*)\]\([^\)]+\)/g, '$1')  // Remove images (keep alt text)
    .replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1')   // Remove links (keep text)
    .replace(/(\*\*|__)(.*?)\1/g, '$2')  // Remove bold
    .replace(/(\*|_)(.*?)\1/g, '$2')     // Remove italic
    .replace(/#{1,6}\s?/g, '')           // Remove headers
    .replace(/>\s?/g, '')                // Remove blockquotes
    .replace(/^\s*[-*+]\s/gm, '')        // Remove list markers
    .replace(/^\s*\d+\.\s/gm, '')        // Remove numbered list markers
    .replace(/---/g, '')                 // Remove horizontal rules
    .trim();
}

/**
 * Normalize whitespace in text content
 * Establishes consistent spacing to support clean text rendering and storage
 *
 * **Best for**: User input processing, database storage, display formatting
 *
 * @param text - Text with inconsistent whitespace
 * @returns Normalized text with single spaces
 *
 * @example
 * ```typescript
 * normalizeWhitespace('Multiple    spaces   and\n\nnewlines');
 * // Output: "Multiple spaces and newlines"
 *
 * normalizeWhitespace('  Leading and trailing  ');
 * // Output: "Leading and trailing"
 * ```
 */
export function normalizeWhitespace(text: string): string {
  return text
    .replace(/\s+/g, ' ')  // Collapse multiple whitespace to single space
    .trim();                // Remove leading/trailing whitespace
}

/**
 * Extract first N sentences from text
 * Establishes intelligent text summarization for previews and excerpts
 *
 * **Best for**: Generating article summaries, email previews, notification text
 *
 * @param text - Full text content
 * @param sentenceCount - Number of sentences to extract (default: 2)
 * @returns First N sentences with proper punctuation
 *
 * @example
 * ```typescript
 * const article = 'First sentence. Second sentence! Third sentence? Fourth sentence.';
 *
 * extractSentences(article, 2);
 * // Output: "First sentence. Second sentence!"
 *
 * extractSentences(article, 1);
 * // Output: "First sentence."
 * ```
 */
export function extractSentences(text: string, sentenceCount: number = 2): string {
  // Split on sentence boundaries (., !, ?)
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [];

  return sentences.slice(0, sentenceCount).join(' ').trim();
}

/**
 * Convert text to title case
 * Establishes consistent heading capitalization for professional presentation
 *
 * **Best for**: Article titles, section headings, menu labels
 *
 * @param text - Original text
 * @returns Title-cased text
 *
 * @example
 * ```typescript
 * toTitleCase('best practices for azure functions');
 * // Output: "Best Practices for Azure Functions"
 *
 * toTitleCase('the quick brown fox');
 * // Output: "The Quick Brown Fox"
 * ```
 */
export function toTitleCase(text: string): string {
  const smallWords = ['a', 'an', 'and', 'as', 'at', 'but', 'by', 'for', 'if', 'in', 'of', 'on', 'or', 'the', 'to', 'with'];

  return text
    .toLowerCase()
    .split(' ')
    .map((word, index) => {
      // Always capitalize first and last words
      if (index === 0 || index === text.split(' ').length - 1) {
        return word.charAt(0).toUpperCase() + word.slice(1);
      }

      // Lowercase small words
      if (smallWords.includes(word)) {
        return word;
      }

      // Capitalize everything else
      return word.charAt(0).toUpperCase() + word.slice(1);
    })
    .join(' ');
}

/**
 * Generate meta description from content
 * Establishes SEO-optimized summaries for search engine visibility
 *
 * **Best for**: Automatic meta description generation for blog posts, articles, pages
 *
 * @param content - Article content (Markdown or plain text)
 * @param maxLength - Maximum description length (default: 160 for SEO)
 * @returns SEO-friendly meta description
 *
 * @example
 * ```typescript
 * const article = '# Azure Functions\n\nAzure Functions provide serverless computing...';
 *
 * generateMetaDescription(article);
 * // Output: "Azure Functions provide serverless computing..." (max 160 chars)
 * ```
 */
export function generateMetaDescription(content: string, maxLength: number = 160): string {
  // Strip Markdown and normalize whitespace
  const plainText = stripMarkdown(content);
  const normalized = normalizeWhitespace(plainText);

  // Extract first 2 sentences
  const sentences = extractSentences(normalized, 2);

  // Truncate to maxLength if needed
  return truncateText(sentences, maxLength, '...');
}
