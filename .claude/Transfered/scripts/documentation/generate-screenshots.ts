/**
 * Playwright Screenshot Automation
 *
 * Generates comprehensive screenshots for documentation with:
 * - Light and dark mode variants
 * - Multiple viewport sizes (desktop, tablet, mobile)
 * - Realistic data and UI states
 * - Optimized WebP output
 */

import { chromium, Browser, Page } from 'playwright';
import { mkdir, writeFile } from 'fs/promises';
import { join } from 'path';
import sharp from 'sharp';

interface ScreenshotConfig {
  name: string;
  url: string;
  viewport: { width: number; height: number };
  theme: 'light' | 'dark';
  selector?: string;
  annotations?: Array<{
    x: number;
    y: number;
    text: string;
    color: string;
  }>;
  waitFor?: string; // Selector to wait for before screenshot
  delay?: number; // Additional delay in ms
}

const BASE_URL = process.env.VITE_APP_URL || 'http://localhost:5173';
const OUTPUT_DIR = join(__dirname, '../../docs/assets/screenshots');

// Viewport configurations
const VIEWPORTS = {
  desktop: { width: 1920, height: 1080 },
  tablet: { width: 768, height: 1024 },
  mobile: { width: 375, height: 667 },
};

// Screenshot configurations
const SCREENSHOTS: ScreenshotConfig[] = [
  // Dashboard views
  {
    name: 'dashboard-overview',
    url: '/',
    viewport: VIEWPORTS.desktop,
    theme: 'light',
    waitFor: '[data-testid="dashboard-loaded"]',
  },
  {
    name: 'dashboard-overview-dark',
    url: '/',
    viewport: VIEWPORTS.desktop,
    theme: 'dark',
    waitFor: '[data-testid="dashboard-loaded"]',
  },

  // Agent management
  {
    name: 'agents-list',
    url: '/agents',
    viewport: VIEWPORTS.desktop,
    theme: 'light',
    waitFor: '[data-testid="agents-list"]',
  },
  {
    name: 'agent-create',
    url: '/agents/create',
    viewport: VIEWPORTS.desktop,
    theme: 'light',
    waitFor: '[data-testid="agent-form"]',
  },
  {
    name: 'agent-details',
    url: '/agents/:id',
    viewport: VIEWPORTS.desktop,
    theme: 'light',
    waitFor: '[data-testid="agent-details"]',
  },

  // Workflow management
  {
    name: 'workflows-list',
    url: '/workflows',
    viewport: VIEWPORTS.desktop,
    theme: 'light',
    waitFor: '[data-testid="workflows-list"]',
  },
  {
    name: 'workflow-builder',
    url: '/workflows/builder',
    viewport: VIEWPORTS.desktop,
    theme: 'light',
    waitFor: '[data-testid="workflow-canvas"]',
  },
  {
    name: 'workflow-execution',
    url: '/workflows/:id/executions/:executionId',
    viewport: VIEWPORTS.desktop,
    theme: 'light',
    waitFor: '[data-testid="execution-timeline"]',
  },

  // Monitoring & observability
  {
    name: 'monitoring-dashboard',
    url: '/monitoring',
    viewport: VIEWPORTS.desktop,
    theme: 'dark',
    waitFor: '[data-testid="metrics-loaded"]',
  },
  {
    name: 'distributed-tracing',
    url: '/monitoring/traces',
    viewport: VIEWPORTS.desktop,
    theme: 'dark',
    waitFor: '[data-testid="trace-viewer"]',
  },

  // Settings
  {
    name: 'settings-general',
    url: '/settings',
    viewport: VIEWPORTS.desktop,
    theme: 'light',
    waitFor: '[data-testid="settings-form"]',
  },
  {
    name: 'settings-integrations',
    url: '/settings/integrations',
    viewport: VIEWPORTS.desktop,
    theme: 'light',
    waitFor: '[data-testid="integrations-list"]',
  },

  // Mobile views
  {
    name: 'dashboard-mobile',
    url: '/',
    viewport: VIEWPORTS.mobile,
    theme: 'light',
    waitFor: '[data-testid="dashboard-loaded"]',
  },
  {
    name: 'agents-mobile',
    url: '/agents',
    viewport: VIEWPORTS.mobile,
    theme: 'light',
    waitFor: '[data-testid="agents-list"]',
  },
];

async function setTheme(page: Page, theme: 'light' | 'dark'): Promise<void> {
  // Inject theme preference
  await page.addInitScript((theme) => {
    localStorage.setItem('theme', theme);
    document.documentElement.setAttribute('data-theme', theme);
  }, theme);
}

async function captureScreenshot(
  browser: Browser,
  config: ScreenshotConfig
): Promise<void> {
  const context = await browser.newContext({
    viewport: config.viewport,
    deviceScaleFactor: 2, // Retina display
  });

  const page = await context.newPage();

  try {
    // Set theme
    await setTheme(page, config.theme);

    // Navigate to page
    const url = config.url.replace(':id', 'demo-agent-id').replace(':executionId', 'demo-execution-id');
    await page.goto(`${BASE_URL}${url}`, { waitUntil: 'networkidle' });

    // Wait for specific element if specified
    if (config.waitFor) {
      await page.waitForSelector(config.waitFor, { timeout: 10000 });
    }

    // Additional delay if needed
    if (config.delay) {
      await page.waitForTimeout(config.delay);
    }

    // Capture screenshot
    const screenshotBuffer = config.selector
      ? await page.locator(config.selector).screenshot({ type: 'png' })
      : await page.screenshot({ type: 'png', fullPage: false });

    // Optimize with sharp (convert to WebP, add annotations if needed)
    let image = sharp(screenshotBuffer);

    // Add annotations if specified
    if (config.annotations && config.annotations.length > 0) {
      const svgAnnotations = config.annotations.map((ann) => `
        <circle cx="${ann.x}" cy="${ann.y}" r="20" fill="${ann.color}" opacity="0.8" />
        <text x="${ann.x}" y="${ann.y + 40}" font-size="14" fill="${ann.color}" text-anchor="middle">${ann.text}</text>
      `).join('');

      const svg = `
        <svg width="${config.viewport.width}" height="${config.viewport.height}">
          ${svgAnnotations}
        </svg>
      `;

      image = image.composite([{ input: Buffer.from(svg), top: 0, left: 0 }]);
    }

    // Save as WebP
    const filename = `${config.name}-${config.theme}-${config.viewport.width}x${config.viewport.height}.webp`;
    const outputPath = join(OUTPUT_DIR, filename);

    await image
      .webp({ quality: 85 })
      .toFile(outputPath);

    console.log(`✓ Generated: ${filename}`);
  } catch (error) {
    console.error(`✗ Failed to capture ${config.name}:`, error);
  } finally {
    await context.close();
  }
}

async function generateAllScreenshots(): Promise<void> {
  console.log('🚀 Starting screenshot generation...\n');

  // Ensure output directory exists
  await mkdir(OUTPUT_DIR, { recursive: true });

  const browser = await chromium.launch({ headless: true });

  try {
    for (const config of SCREENSHOTS) {
      await captureScreenshot(browser, config);
    }

    console.log('\n✅ All screenshots generated successfully!');
  } finally {
    await browser.close();
  }
}

// Generate metadata file for screenshots
async function generateMetadata(): Promise<void> {
  const metadata = SCREENSHOTS.map((config) => ({
    name: config.name,
    url: config.url,
    viewports: ['desktop', 'tablet', 'mobile'].filter((vp) =>
      SCREENSHOTS.some((s) => s.name === config.name && s.viewport === VIEWPORTS[vp as keyof typeof VIEWPORTS])
    ),
    themes: ['light', 'dark'].filter((theme) =>
      SCREENSHOTS.some((s) => s.name === config.name && s.theme === theme)
    ),
  }));

  const metadataPath = join(OUTPUT_DIR, 'metadata.json');
  await writeFile(metadataPath, JSON.stringify(metadata, null, 2));

  console.log('📄 Screenshot metadata generated');
}

// CLI execution
if (require.main === module) {
  generateAllScreenshots()
    .then(() => generateMetadata())
    .catch((error) => {
      console.error('❌ Screenshot generation failed:', error);
      process.exit(1);
    });
}

export { generateAllScreenshots, captureScreenshot, SCREENSHOTS };
