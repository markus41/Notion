#!/usr/bin/env node

/**
 * Frontmatter Validation Script
 *
 * This script validates frontmatter in all markdown documentation files.
 * It checks for required fields, validates field types, and ensures no duplicate titles.
 *
 * Required frontmatter fields:
 * - title: string (required for all docs except index.md with layout: home)
 * - description: string (optional but recommended)
 *
 * Exit codes:
 * - 0: All validations passed
 * - 1: Validation errors found
 */

import { readFileSync, readdirSync, statSync, writeFileSync } from 'fs';
import { join, relative } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration
const DOCS_DIR = join(__dirname, '..', 'docs');
const REPORT_FILE = join(__dirname, '..', 'docs-validation-report.json');

// Colors for console output (if not in CI)
const isCI = process.env.CI === 'true';
const colors = {
  reset: isCI ? '' : '\x1b[0m',
  red: isCI ? '' : '\x1b[31m',
  green: isCI ? '' : '\x1b[32m',
  yellow: isCI ? '' : '\x1b[33m',
  blue: isCI ? '' : '\x1b[34m',
  cyan: isCI ? '' : '\x1b[36m',
};

// Results tracking
const results = {
  totalFiles: 0,
  validFiles: 0,
  errors: [],
  warnings: [],
  duplicateTitles: {},
};

/**
 * Extract frontmatter from markdown content
 */
function extractFrontmatter(content, filePath) {
  const frontmatterRegex = /^---\s*\n([\s\S]*?)\n---/;
  const match = content.match(frontmatterRegex);

  if (!match) {
    return null;
  }

  try {
    // Simple YAML parsing (handles basic cases)
    const frontmatterText = match[1];
    const frontmatter = {};
    const lines = frontmatterText.split('\n');
    let currentKey = null;
    let currentValue = '';
    let inArray = false;

    for (let line of lines) {
      line = line.trim();

      if (!line || line.startsWith('#')) continue;

      // Handle array items
      if (line.startsWith('-')) {
        if (inArray && currentKey) {
          const item = line.substring(1).trim();
          if (!frontmatter[currentKey]) {
            frontmatter[currentKey] = [];
          }
          frontmatter[currentKey].push(item);
        }
        continue;
      }

      // Handle key-value pairs
      const colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        if (currentKey && currentValue) {
          frontmatter[currentKey] = currentValue.trim();
        }

        currentKey = line.substring(0, colonIndex).trim();
        currentValue = line.substring(colonIndex + 1).trim();

        // Check if this starts an array
        inArray = currentValue === '' && !currentValue.includes('"') && !currentValue.includes("'");

        if (!inArray && currentValue) {
          // Remove quotes if present
          currentValue = currentValue.replace(/^["']|["']$/g, '');
        }
      } else if (currentKey) {
        currentValue += ' ' + line;
      }
    }

    // Add last key-value pair
    if (currentKey && currentValue && !inArray) {
      frontmatter[currentKey] = currentValue.trim().replace(/^["']|["']$/g, '');
    }

    return frontmatter;
  } catch (error) {
    results.errors.push({
      file: filePath,
      type: 'PARSE_ERROR',
      message: `Failed to parse frontmatter: ${error.message}`,
    });
    return null;
  }
}

/**
 * Validate frontmatter for a single file
 */
function validateFrontmatter(filePath) {
  const relativePath = relative(DOCS_DIR, filePath);
  results.totalFiles++;

  try {
    const content = readFileSync(filePath, 'utf-8');
    const frontmatter = extractFrontmatter(content, relativePath);

    // Special cases that don't require standard frontmatter
    const isHomePage = relativePath === 'index.md' && content.includes('layout: home');
    const isChangeLog = relativePath === 'CHANGELOG.md';

    if (isHomePage || isChangeLog) {
      results.validFiles++;
      return;
    }

    // Check if frontmatter exists
    if (!frontmatter) {
      results.errors.push({
        file: relativePath,
        type: 'MISSING_FRONTMATTER',
        message: 'No frontmatter found. Add YAML frontmatter with at least a title.',
      });
      return;
    }

    // Validate title field (required for most docs)
    if (!frontmatter.title) {
      // Check if it's an ADR (Architecture Decision Record) - they often have different structure
      if (!relativePath.includes('adrs/')) {
        results.errors.push({
          file: relativePath,
          type: 'MISSING_TITLE',
          message: 'Missing required field: title',
        });
      }
    } else {
      // Check for duplicate titles
      const title = frontmatter.title.toLowerCase().trim();
      if (!results.duplicateTitles[title]) {
        results.duplicateTitles[title] = [];
      }
      results.duplicateTitles[title].push(relativePath);

      // Validate title is a string and not empty
      if (typeof frontmatter.title !== 'string' || frontmatter.title.trim() === '') {
        results.errors.push({
          file: relativePath,
          type: 'INVALID_TITLE',
          message: 'Title must be a non-empty string',
        });
      }

      // Check title length (recommended max: 60 chars for SEO)
      if (frontmatter.title.length > 60) {
        results.warnings.push({
          file: relativePath,
          type: 'LONG_TITLE',
          message: `Title is ${frontmatter.title.length} characters (recommended: max 60). Consider shortening for better SEO.`,
        });
      }
    }

    // Validate description field (optional but recommended)
    if (!frontmatter.description) {
      results.warnings.push({
        file: relativePath,
        type: 'MISSING_DESCRIPTION',
        message: 'Missing recommended field: description. Descriptions improve SEO and searchability.',
      });
    } else {
      // Validate description format
      if (typeof frontmatter.description !== 'string' || frontmatter.description.trim() === '') {
        results.errors.push({
          file: relativePath,
          type: 'INVALID_DESCRIPTION',
          message: 'Description must be a non-empty string',
        });
      }

      // Check description length (recommended: 120-160 chars for SEO)
      const descLength = frontmatter.description.length;
      if (descLength < 50) {
        results.warnings.push({
          file: relativePath,
          type: 'SHORT_DESCRIPTION',
          message: `Description is ${descLength} characters (recommended: 120-160). Consider expanding.`,
        });
      } else if (descLength > 160) {
        results.warnings.push({
          file: relativePath,
          type: 'LONG_DESCRIPTION',
          message: `Description is ${descLength} characters (recommended: 120-160). Consider shortening.`,
        });
      }
    }

    // Validate lastUpdated if present
    if (frontmatter.lastUpdated) {
      const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
      if (!dateRegex.test(frontmatter.lastUpdated)) {
        results.errors.push({
          file: relativePath,
          type: 'INVALID_DATE',
          message: 'lastUpdated must be in YYYY-MM-DD format',
        });
      }
    }

    // Validate contributors if present
    if (frontmatter.contributors) {
      if (!Array.isArray(frontmatter.contributors) && typeof frontmatter.contributors !== 'string') {
        results.errors.push({
          file: relativePath,
          type: 'INVALID_CONTRIBUTORS',
          message: 'contributors must be an array or string',
        });
      }
    }

    results.validFiles++;
  } catch (error) {
    results.errors.push({
      file: relativePath,
      type: 'FILE_READ_ERROR',
      message: `Failed to read file: ${error.message}`,
    });
  }
}

/**
 * Recursively find all markdown files
 */
function findMarkdownFiles(dir) {
  const files = [];

  function traverse(currentDir) {
    const items = readdirSync(currentDir);

    for (const item of items) {
      const fullPath = join(currentDir, item);
      const stat = statSync(fullPath);

      if (stat.isDirectory()) {
        // Skip node_modules, .vitepress, and hidden directories
        if (!item.startsWith('.') && item !== 'node_modules') {
          traverse(fullPath);
        }
      } else if (stat.isFile() && item.endsWith('.md')) {
        files.push(fullPath);
      }
    }
  }

  traverse(dir);
  return files;
}

/**
 * Check for duplicate titles
 */
function checkDuplicateTitles() {
  for (const [title, files] of Object.entries(results.duplicateTitles)) {
    if (files.length > 1) {
      results.errors.push({
        file: files.join(', '),
        type: 'DUPLICATE_TITLE',
        message: `Duplicate title "${title}" found in ${files.length} files`,
      });
    }
  }
}

/**
 * Print results to console
 */
function printResults() {
  console.log(`\n${colors.cyan}========================================`);
  console.log(`Frontmatter Validation Results`);
  console.log(`========================================${colors.reset}\n`);

  console.log(`${colors.blue}Total files checked: ${results.totalFiles}${colors.reset}`);
  console.log(`${colors.green}Valid files: ${results.validFiles}${colors.reset}`);

  if (results.errors.length > 0) {
    console.log(`\n${colors.red}❌ Errors (${results.errors.length}):${colors.reset}`);
    results.errors.forEach(error => {
      console.log(`\n  ${colors.red}File:${colors.reset} ${error.file}`);
      console.log(`  ${colors.red}Type:${colors.reset} ${error.type}`);
      console.log(`  ${colors.red}Message:${colors.reset} ${error.message}`);
    });
  }

  if (results.warnings.length > 0) {
    console.log(`\n${colors.yellow}⚠️  Warnings (${results.warnings.length}):${colors.reset}`);
    results.warnings.forEach(warning => {
      console.log(`\n  ${colors.yellow}File:${colors.reset} ${warning.file}`);
      console.log(`  ${colors.yellow}Type:${colors.reset} ${warning.type}`);
      console.log(`  ${colors.yellow}Message:${colors.reset} ${warning.message}`);
    });
  }

  if (results.errors.length === 0 && results.warnings.length === 0) {
    console.log(`\n${colors.green}✅ All frontmatter validations passed!${colors.reset}\n`);
  }
}

/**
 * Save results to JSON report
 */
function saveReport() {
  const report = {
    timestamp: new Date().toISOString(),
    summary: {
      totalFiles: results.totalFiles,
      validFiles: results.validFiles,
      errorCount: results.errors.length,
      warningCount: results.warnings.length,
    },
    errors: results.errors,
    warnings: results.warnings,
  };

  writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2));
  console.log(`\n${colors.blue}📄 Report saved to: ${REPORT_FILE}${colors.reset}\n`);
}

/**
 * Main execution
 */
function main() {
  console.log(`${colors.cyan}🔍 Validating frontmatter in documentation...${colors.reset}\n`);

  const markdownFiles = findMarkdownFiles(DOCS_DIR);
  console.log(`Found ${markdownFiles.length} markdown files\n`);

  markdownFiles.forEach(validateFrontmatter);
  checkDuplicateTitles();

  printResults();
  saveReport();

  // Exit with error code if there are errors
  if (results.errors.length > 0) {
    process.exit(1);
  }
}

main();
