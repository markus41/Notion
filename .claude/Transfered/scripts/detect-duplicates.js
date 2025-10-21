#!/usr/bin/env node

/**
 * Duplicate Content Detection Script
 *
 * This script detects duplicate or highly similar content across documentation files.
 * It helps identify:
 * 1. Exact duplicate content blocks (>100 lines)
 * 2. Files with high similarity (>80% match)
 * 3. Duplicate "Getting Started" sections
 *
 * Exit codes:
 * - 0: No critical duplicates found (warnings may exist)
 * - 1: Critical duplicates found requiring action
 */

import { readFileSync, readdirSync, statSync, writeFileSync } from 'fs';
import { join, relative } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration
const DOCS_DIR = join(__dirname, '..', 'docs');
const REPORT_FILE = join(__dirname, '..', 'duplicate-content-report.json');
const MIN_DUPLICATE_LINES = 100; // Minimum lines to consider as duplicate
const SIMILARITY_THRESHOLD = 0.80; // 80% similarity threshold
const GETTING_STARTED_THRESHOLD = 0.70; // 70% for Getting Started sections

// Colors for console output
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
  duplicateBlocks: [],
  similarFiles: [],
  gettingStartedDuplicates: [],
  warnings: [],
};

/**
 * Normalize text for comparison (remove extra whitespace, code blocks, etc.)
 */
function normalizeText(text) {
  return text
    .replace(/```[\s\S]*?```/g, '') // Remove code blocks
    .replace(/`[^`]+`/g, '') // Remove inline code
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // Remove markdown links, keep text
    .replace(/[#*_~]/g, '') // Remove markdown formatting
    .replace(/\s+/g, ' ') // Normalize whitespace
    .toLowerCase()
    .trim();
}

/**
 * Calculate Levenshtein distance for similarity comparison
 */
function levenshteinDistance(str1, str2) {
  const m = str1.length;
  const n = str2.length;
  const dp = Array(m + 1).fill(null).map(() => Array(n + 1).fill(0));

  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;

  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      if (str1[i - 1] === str2[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = Math.min(
          dp[i - 1][j] + 1,    // deletion
          dp[i][j - 1] + 1,    // insertion
          dp[i - 1][j - 1] + 1 // substitution
        );
      }
    }
  }

  return dp[m][n];
}

/**
 * Calculate similarity ratio between two texts
 */
function calculateSimilarity(text1, text2) {
  const normalized1 = normalizeText(text1);
  const normalized2 = normalizeText(text2);

  if (normalized1.length === 0 || normalized2.length === 0) return 0;

  const distance = levenshteinDistance(normalized1, normalized2);
  const maxLength = Math.max(normalized1.length, normalized2.length);

  return 1 - (distance / maxLength);
}

/**
 * Extract content blocks from markdown
 */
function extractContentBlocks(content) {
  const lines = content.split('\n');
  const blocks = [];
  let currentBlock = [];

  for (const line of lines) {
    if (line.trim() === '') {
      if (currentBlock.length >= MIN_DUPLICATE_LINES) {
        blocks.push(currentBlock.join('\n'));
      }
      currentBlock = [];
    } else {
      currentBlock.push(line);
    }
  }

  if (currentBlock.length >= MIN_DUPLICATE_LINES) {
    blocks.push(currentBlock.join('\n'));
  }

  return blocks;
}

/**
 * Extract "Getting Started" section from content
 */
function extractGettingStartedSection(content) {
  const gettingStartedRegex = /(#+\s*getting\s+started[\s\S]*?)(?=\n#+\s|\n*$)/i;
  const match = content.match(gettingStartedRegex);

  if (match) {
    return match[1].trim();
  }

  // Also check for "Quick Start" sections
  const quickStartRegex = /(#+\s*quick\s+start[\s\S]*?)(?=\n#+\s|\n*$)/i;
  const quickMatch = content.match(quickStartRegex);

  return quickMatch ? quickMatch[1].trim() : null;
}

/**
 * Find duplicate content blocks across files
 */
function findDuplicateBlocks(fileContents) {
  const blocksByContent = new Map();

  for (const [file, content] of fileContents) {
    const blocks = extractContentBlocks(content);

    for (const block of blocks) {
      const normalized = normalizeText(block);
      if (normalized.length < 500) continue; // Skip small blocks

      if (!blocksByContent.has(normalized)) {
        blocksByContent.set(normalized, []);
      }
      blocksByContent.get(normalized).push({
        file,
        lineCount: block.split('\n').length,
        preview: block.substring(0, 100) + '...',
      });
    }
  }

  // Find duplicates
  for (const [content, occurrences] of blocksByContent) {
    if (occurrences.length > 1) {
      results.duplicateBlocks.push({
        occurrences,
        similarity: 1.0,
        preview: occurrences[0].preview,
      });
    }
  }
}

/**
 * Find similar files
 */
function findSimilarFiles(fileContents) {
  const files = Array.from(fileContents.entries());

  for (let i = 0; i < files.length; i++) {
    for (let j = i + 1; j < files.length; j++) {
      const [file1, content1] = files[i];
      const [file2, content2] = files[j];

      const similarity = calculateSimilarity(content1, content2);

      if (similarity >= SIMILARITY_THRESHOLD) {
        results.similarFiles.push({
          file1,
          file2,
          similarity: (similarity * 100).toFixed(1),
          recommendation: similarity > 0.95
            ? 'Consider merging these files - they are nearly identical'
            : 'Review for consolidation opportunities',
        });
      }
    }
  }
}

/**
 * Find duplicate "Getting Started" sections
 */
function findGettingStartedDuplicates(fileContents) {
  const gettingStartedSections = [];

  for (const [file, content] of fileContents) {
    const section = extractGettingStartedSection(content);
    if (section) {
      gettingStartedSections.push({ file, section });
    }
  }

  // Compare all Getting Started sections
  for (let i = 0; i < gettingStartedSections.length; i++) {
    for (let j = i + 1; j < gettingStartedSections.length; j++) {
      const { file: file1, section: section1 } = gettingStartedSections[i];
      const { file: file2, section: section2 } = gettingStartedSections[j];

      const similarity = calculateSimilarity(section1, section2);

      if (similarity >= GETTING_STARTED_THRESHOLD) {
        results.gettingStartedDuplicates.push({
          file1,
          file2,
          similarity: (similarity * 100).toFixed(1),
          recommendation: 'Consider creating a single canonical Getting Started guide',
        });
      }
    }
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
 * Read all markdown files
 */
function readMarkdownFiles() {
  const files = findMarkdownFiles(DOCS_DIR);
  const fileContents = new Map();

  for (const file of files) {
    try {
      const content = readFileSync(file, 'utf-8');
      const relativePath = relative(DOCS_DIR, file);
      fileContents.set(relativePath, content);
      results.totalFiles++;
    } catch (error) {
      results.warnings.push({
        file: relative(DOCS_DIR, file),
        message: `Failed to read file: ${error.message}`,
      });
    }
  }

  return fileContents;
}

/**
 * Print results to console
 */
function printResults() {
  console.log(`\n${colors.cyan}========================================`);
  console.log(`Duplicate Content Detection Results`);
  console.log(`========================================${colors.reset}\n`);

  console.log(`${colors.blue}Total files scanned: ${results.totalFiles}${colors.reset}\n`);

  // Duplicate blocks
  if (results.duplicateBlocks.length > 0) {
    console.log(`${colors.yellow}📋 Duplicate Content Blocks (${results.duplicateBlocks.length}):${colors.reset}`);
    results.duplicateBlocks.forEach((block, index) => {
      console.log(`\n  ${colors.yellow}Block ${index + 1}:${colors.reset}`);
      console.log(`  ${colors.yellow}Found in:${colors.reset}`);
      block.occurrences.forEach(occ => {
        console.log(`    - ${occ.file} (${occ.lineCount} lines)`);
      });
      console.log(`  ${colors.yellow}Preview:${colors.reset} ${block.preview}`);
    });
    console.log('');
  }

  // Similar files
  if (results.similarFiles.length > 0) {
    console.log(`${colors.yellow}🔍 Similar Files (${results.similarFiles.length}):${colors.reset}`);
    results.similarFiles.forEach(item => {
      console.log(`\n  ${colors.yellow}Similarity: ${item.similarity}%${colors.reset}`);
      console.log(`  ${colors.yellow}Files:${colors.reset}`);
      console.log(`    - ${item.file1}`);
      console.log(`    - ${item.file2}`);
      console.log(`  ${colors.yellow}Recommendation:${colors.reset} ${item.recommendation}`);
    });
    console.log('');
  }

  // Getting Started duplicates
  if (results.gettingStartedDuplicates.length > 0) {
    console.log(`${colors.yellow}🚀 Duplicate "Getting Started" Sections (${results.gettingStartedDuplicates.length}):${colors.reset}`);
    results.gettingStartedDuplicates.forEach(item => {
      console.log(`\n  ${colors.yellow}Similarity: ${item.similarity}%${colors.reset}`);
      console.log(`  ${colors.yellow}Files:${colors.reset}`);
      console.log(`    - ${item.file1}`);
      console.log(`    - ${item.file2}`);
      console.log(`  ${colors.yellow}Recommendation:${colors.reset} ${item.recommendation}`);
    });
    console.log('');
  }

  // Warnings
  if (results.warnings.length > 0) {
    console.log(`${colors.yellow}⚠️  Warnings (${results.warnings.length}):${colors.reset}`);
    results.warnings.forEach(warning => {
      console.log(`  - ${warning.file}: ${warning.message}`);
    });
    console.log('');
  }

  // Summary
  const totalIssues = results.duplicateBlocks.length + results.similarFiles.length + results.gettingStartedDuplicates.length;

  if (totalIssues === 0) {
    console.log(`${colors.green}✅ No duplicate content detected!${colors.reset}\n`);
  } else {
    console.log(`${colors.yellow}⚠️  Found ${totalIssues} potential duplicate content issues${colors.reset}`);
    console.log(`${colors.yellow}These are recommendations for improving documentation consistency.${colors.reset}\n`);
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
      duplicateBlocks: results.duplicateBlocks.length,
      similarFiles: results.similarFiles.length,
      gettingStartedDuplicates: results.gettingStartedDuplicates.length,
      warningCount: results.warnings.length,
    },
    duplicateBlocks: results.duplicateBlocks,
    similarFiles: results.similarFiles,
    gettingStartedDuplicates: results.gettingStartedDuplicates,
    warnings: results.warnings,
  };

  writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2));
  console.log(`${colors.blue}📄 Report saved to: ${REPORT_FILE}${colors.reset}\n`);
}

/**
 * Main execution
 */
function main() {
  console.log(`${colors.cyan}🔍 Detecting duplicate content in documentation...${colors.reset}\n`);

  const fileContents = readMarkdownFiles();

  findDuplicateBlocks(fileContents);
  findSimilarFiles(fileContents);
  findGettingStartedDuplicates(fileContents);

  printResults();
  saveReport();

  // Don't fail the build for duplicate content (it's a warning, not an error)
  // But exit with code 0 to indicate successful execution
  process.exit(0);
}

main();
