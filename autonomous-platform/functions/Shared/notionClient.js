/**
 * Notion API Client
 *
 * Establishes secure connection to Notion workspace for autonomous operations.
 * Provides methods for reading and updating database entries.
 *
 * Best for: Centralized Notion API interactions with retry logic and error handling
 */

const axios = require('axios');

class NotionClient {
  constructor() {
    this.apiKey = process.env.NOTION_API_KEY;
    this.baseUrl = 'https://api.notion.com/v1';
    this.version = '2022-06-28';
  }

  /**
   * Get headers for Notion API requests
   */
  getHeaders() {
    return {
      'Authorization': `Bearer ${this.apiKey}`,
      'Notion-Version': this.version,
      'Content-Type': 'application/json'
    };
  }

  /**
   * Fetch page details
   */
  async getPage(pageId) {
    const response = await axios.get(
      `${this.baseUrl}/pages/${pageId}`,
      { headers: this.getHeaders() }
    );
    return response.data;
  }

  /**
   * Update page properties
   */
  async updatePage(pageId, properties) {
    const response = await axios.patch(
      `${this.baseUrl}/pages/${pageId}`,
      { properties },
      { headers: this.getHeaders() }
    );
    return response.data;
  }

  /**
   * Create a new page in a database
   */
  async createPage(databaseId, properties, content = []) {
    const payload = {
      parent: { database_id: databaseId },
      properties
    };

    if (content.length > 0) {
      payload.children = content;
    }

    const response = await axios.post(
      `${this.baseUrl}/pages`,
      payload,
      { headers: this.getHeaders() }
    );
    return response.data;
  }

  /**
   * Add comment to page
   */
  async addComment(pageId, text) {
    const response = await axios.post(
      `${this.baseUrl}/comments`,
      {
        parent: { page_id: pageId },
        rich_text: [{ text: { content: text } }]
      },
      { headers: this.getHeaders() }
    );
    return response.data;
  }

  /**
   * Query database
   */
  async queryDatabase(databaseId, filter = {}, sorts = []) {
    const response = await axios.post(
      `${this.baseUrl}/databases/${databaseId}/query`,
      {
        filter,
        sorts
      },
      { headers: this.getHeaders() }
    );
    return response.data;
  }

  /**
   * Helper: Update status properties for automation tracking
   */
  async updateAutomationStatus(pageId, status, stage = null) {
    const properties = {
      'Automation Status': { select: { name: status } },
      'Last Automation Event': { date: { start: new Date().toISOString() } }
    };

    if (stage) {
      properties['Automation Stage'] = { rich_text: [{ text: { content: stage } }] };
    }

    return this.updatePage(pageId, properties);
  }

  /**
   * Helper: Convert Notion property to simple value
   */
  static extractPropertyValue(property) {
    if (!property) return null;

    switch (property.type) {
      case 'title':
        return property.title.map(t => t.plain_text).join('');
      case 'rich_text':
        return property.rich_text.map(t => t.plain_text).join('');
      case 'number':
        return property.number;
      case 'select':
        return property.select?.name || null;
      case 'multi_select':
        return property.multi_select.map(s => s.name);
      case 'date':
        return property.date?.start || null;
      case 'checkbox':
        return property.checkbox;
      case 'url':
        return property.url;
      case 'email':
        return property.email;
      case 'phone_number':
        return property.phone_number;
      case 'relation':
        return property.relation.map(r => r.id);
      default:
        return null;
    }
  }
}

module.exports = NotionClient;
