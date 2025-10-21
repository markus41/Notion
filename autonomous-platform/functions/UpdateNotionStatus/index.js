/**
 * Update Notion Status Activity Function
 *
 * Updates Notion database properties to reflect automation progress.
 * Establishes real-time visibility into autonomous workflow execution.
 *
 * Best for: Maintaining synchronization between Azure workflow state and Notion UI
 */

const NotionClient = require('../Shared/notionClient');

module.exports = async function (context, input) {
  const { pageId, properties } = input;

  context.log('Updating Notion page status', {
    pageId,
    propertyCount: Object.keys(properties).length
  });

  const notion = new NotionClient();

  try {
    // Convert simple property values to Notion API format
    const notionProperties = {};

    for (const [key, value] of Object.entries(properties)) {
      if (value === null || value === undefined) {
        continue;
      }

      // Infer property type and format
      if (typeof value === 'string') {
        // Try to determine if it's a select or rich text
        if (['Status', 'Automation Status', 'Build Stage', 'Viability', 'Deployment Health'].includes(key)) {
          notionProperties[key] = { select: { name: value } };
        } else if (key.endsWith(' URL') || key === 'Live URL' || key === 'GitHub Repo') {
          notionProperties[key] = { url: value };
        } else {
          notionProperties[key] = {
            rich_text: [{ text: { content: value } }]
          };
        }
      } else if (typeof value === 'number') {
        notionProperties[key] = { number: value };
      } else if (typeof value === 'boolean') {
        notionProperties[key] = { checkbox: value };
      } else if (value instanceof Date || /^\d{4}-\d{2}-\d{2}T/.test(value)) {
        notionProperties[key] = {
          date: { start: value instanceof Date ? value.toISOString() : value }
        };
      }
    }

    const result = await notion.updatePage(pageId, notionProperties);

    context.log('Notion page updated successfully', {
      pageId: result.id,
      lastEdited: result.last_edited_time
    });

    return {
      success: true,
      pageId: result.id,
      updatedProperties: Object.keys(notionProperties)
    };
  } catch (error) {
    context.log.error('Failed to update Notion page', {
      pageId,
      error: error.message
    });

    throw new Error(`Notion update failed: ${error.message}`);
  }
};
