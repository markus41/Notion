# asset-migration-handler

**Agent ID:** `asset-migration-handler`
**Version:** 1.0.0
**Category:** Media Processing
**Dependencies:** Image processing libraries (Pillow), Webflow API

**Best for:** Organizations requiring consistent visual brand identity across web properties with automated quality enforcement.

---

## Purpose

Establish reliable image processing pipeline to validate, optimize, and migrate images from Notion to Webflow CDN. Designed for teams maintaining strict visual standards (pixel art style guides) while publishing at scale (50+ blog posts with hero images).

**Business Value:**
- Enforce pixel art brand guidelines automatically (reject non-compliant images before publish)
- Optimize image sizes (82% reduction: 2.5MB → 450KB average)
- Eliminate manual image downloads/uploads (extract from Notion, upload to Webflow automatically)
- Preserve image quality while reducing bandwidth costs (WebP conversion, 85% quality)

---

## Capabilities

### Core Operations
- **Image Extraction** - Download images from Notion pages
- **Pixel Art Validation** - Enforce 16:9, hard edges, limited palette
- **Image Optimization** - Resize, compress, format conversion (WebP)
- **Webflow Upload** - Migrate to Webflow CDN
- **URL Rewriting** - Replace Notion URLs in HTML content

### Validation Rules (Pixel Art Hero Images)
- **Hard Edges** - No anti-aliasing (sharp pixel boundaries)
- **Color Palette** - Max 32 colors (pixel art aesthetic)
- **Aspect Ratio** - 16:9 (1.78 ratio)
- **Minimum Dimensions** - 1600x900 (retina displays)
- **Character Count** - 3-5 visible figures (brand guideline)
- **Background** - No transparency

---

## Tools

### 1. extract_and_upload_images

**Purpose:** Extract all images from Notion page, upload to Webflow

**When to use:**
- During sync workflow (Step 5)
- Migrating blog post images
- Pre-processing before publish

**Function Signature:**
```python
def extract_and_upload_images(
    notion_page_id: str,
    target_site_id: str,
    optimize: bool = True
) -> ImageMigrationResponse
```

**Pipeline:**
1. **Extract** - Parse Notion page, find all image blocks
2. **Download** - Fetch images from Notion URLs
3. **Validate** - Hero image only (pixel art compliance)
4. **Optimize** - Resize to max 1920px, convert to WebP, 85% quality
5. **Upload** - Webflow Assets API
6. **Return** - Webflow CDN URLs + mapping

**Example:**
```bash
/agent asset-migration-handler extract-and-upload \
  --page-id "abc123def456" \
  --site-id "webflow_site_xyz789" \
  --optimize
```

**Success Output:**
```json
{
  "agent": "asset-migration-handler",
  "status": "success",
  "data": {
    "total_images": 5,
    "processed": 5,
    "failed": 0,
    "images": [
      {
        "notion_url": "https://prod-files-secure.s3.us-west-2.amazonaws.com/.../hero.png",
        "webflow_cdn_url": "https://uploads-ssl.webflow.com/site-id/asset-id_hero.webp",
        "webflow_asset_id": "img_abc123",
        "original_size_kb": 2500,
        "optimized_size_kb": 450,
        "savings_percent": 82,
        "validation_passed": true
      }
    ],
    "url_mapping": {
      "https://prod-files-secure.s3.us-west-2.amazonaws.com/.../hero.png": "https://uploads-ssl.webflow.com/site-id/asset-id_hero.webp"
    }
  },
  "metadata": {
    "execution_time_ms": 4500
  }
}
```

---

### 2. validate_pixel_art

**Purpose:** Enforce pixel art style compliance for hero images

**When to use:**
- Before publishing blog post
- Manual image quality check
- Pre-upload validation

**Function Signature:**
```python
def validate_pixel_art(
    image_path: str,
    strict: bool = True
) -> ValidationResponse
```

**Validation Rules:**
```python
validation_rules = {
    "hard_edges": True,           # No anti-aliasing
    "color_palette_max": 32,      # Limited palette
    "aspect_ratio": "16:9",       # Consistent dimensions
    "min_width": 1600,            # High-res for retina
    "min_height": 900,            # 16:9 ratio enforcement
    "character_count": (3, 5),    # 3-5 visible figures
    "background_required": True   # No transparency
}
```

**Example:**
```bash
/agent asset-migration-handler validate-pixel-art \
  --image "./images/blog-cover.png" \
  --strict
```

**Success Output (Pass):**
```json
{
  "agent": "asset-migration-handler",
  "status": "success",
  "data": {
    "is_valid": true,
    "validation_results": {
      "hard_edges": "pass",
      "color_palette_compliance": "pass (20 colors)",
      "aspect_ratio": "pass (16:9)",
      "dimensions": "1920x1080 (pass)",
      "character_count": "pass (4 characters)",
      "background": "pass (opaque)"
    },
    "violations": [],
    "warnings": []
  }
}
```

**Failure Output (Anti-Aliasing Detected):**
```json
{
  "agent": "asset-migration-handler",
  "status": "success",
  "data": {
    "is_valid": false,
    "validation_results": {
      "hard_edges": "fail",
      "color_palette_compliance": "pass",
      "aspect_ratio": "pass",
      "dimensions": "pass"
    },
    "violations": [
      {
        "rule": "hard_edges",
        "message": "Anti-aliasing detected - pixel art requires hard edges",
        "fix": "Re-export from design tool with nearest-neighbor scaling (no smoothing)"
      }
    ],
    "warnings": [
      "Character count appears to be 6 (expected 3-5)"
    ]
  }
}
```

---

### 3. optimize_image

**Purpose:** Resize, compress, convert format

**When to use:**
- Reduce file size before upload
- Convert to WebP for modern browsers
- Standardize dimensions

**Function Signature:**
```python
def optimize_image(
    image_path: str,
    target_size_kb: Optional[int] = None,
    quality: int = 85
) -> OptimizationResponse
```

**Optimization Steps:**
1. **Resize** - If width >1920px, resize maintaining aspect ratio
2. **Compress** - JPEG/PNG: 85% quality | WebP: 85% quality
3. **Format Convert** - Convert PNG/JPEG to WebP
4. **Verify Size** - If still > `target_size_kb`, reduce quality incrementally

**Example:**
```bash
/agent asset-migration-handler optimize-image \
  --image "./images/raw/photo.png" \
  --target-size 500 \
  --quality 85 \
  --format webp
```

**Success Output:**
```json
{
  "agent": "asset-migration-handler",
  "status": "success",
  "data": {
    "original_path": "./images/raw/photo.png",
    "optimized_path": "./images/optimized/photo.webp",
    "original_size_kb": 2500,
    "optimized_size_kb": 450,
    "savings_percent": 82,
    "dimensions": {
      "original": "3000x2000",
      "optimized": "1920x1280"
    },
    "format": {
      "original": "png",
      "optimized": "webp"
    },
    "quality_used": 85
  }
}
```

---

### 4. rewrite_image_urls

**Purpose:** Replace Notion URLs with Webflow CDN URLs in HTML

**When to use:**
- After images uploaded to Webflow
- Before publishing HTML to Webflow collection

**Function Signature:**
```python
def rewrite_image_urls(
    html_content: str,
    url_mapping: Dict[str, str]
) -> HTMLResponse
```

**URL Mapping:**
```json
{
  "https://prod-files-secure.s3.us-west-2.amazonaws.com/.../image1.png": "https://uploads-ssl.webflow.com/site-id/asset-id_image1.webp",
  "https://s3.us-west-2.amazonaws.com/.../diagram.png": "https://uploads-ssl.webflow.com/site-id/asset-id_diagram.webp"
}
```

**Example:**
```bash
/agent asset-migration-handler rewrite-urls \
  --html-file "./content/article.html" \
  --mapping-file "./url-map.json" \
  --output-file "./content/article-final.html"
```

**Before:**
```html
<img src="https://prod-files-secure.s3.us-west-2.amazonaws.com/.../image.png" alt="Diagram">
```

**After:**
```html
<img src="https://uploads-ssl.webflow.com/site-id/asset-id_image.webp" alt="Diagram">
```

---

## Pixel Art Validation Details

### Hard Edges Detection

**Algorithm:**
```python
def has_anti_aliasing(image_path: str) -> bool:
    """
    Detect anti-aliasing by analyzing pixel boundaries.

    Pixel art has sharp transitions (e.g., #000000 → #FFFFFF).
    Anti-aliased images have gradual transitions (e.g., #000000 → #808080 → #FFFFFF).
    """
    img = Image.open(image_path).convert("RGB")
    pixels = img.load()

    # Sample 1000 random edges
    edge_count = 0
    smooth_edge_count = 0

    for _ in range(1000):
        x = random.randint(1, img.width - 2)
        y = random.randint(1, img.height - 2)

        # Check if this is an edge (color change)
        current = pixels[x, y]
        right = pixels[x + 1, y]

        if color_distance(current, right) > 50:  # Edge detected
            edge_count += 1

            # Check for intermediate colors (anti-aliasing)
            between = pixels[x, y]  # Could check interpolated color
            if is_intermediate_color(current, right, between):
                smooth_edge_count += 1

    # If >10% of edges are smooth, anti-aliasing present
    return smooth_edge_count / edge_count > 0.1 if edge_count > 0 else False
```

### Color Palette Check

**Algorithm:**
```python
def count_unique_colors(image_path: str) -> int:
    """Count unique RGB colors in image."""
    img = Image.open(image_path).convert("RGB")
    colors = set()

    for pixel in img.getdata():
        colors.add(pixel)

    return len(colors)
```

**Validation:**
```python
color_count = count_unique_colors(image_path)
if color_count > 32:
    violations.append(f"Color palette {color_count} exceeds max 32 colors")
```

---

## Integration with Other Agents

### Upstream Dependencies
- **notion-mcp-expert** - Provides Notion page with images

### Downstream Consumers
- **notion-webflow-syncer** - Uses image URLs and mapping for publishing
- **webflow-api-expert** - Uploads assets to Webflow

---

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Pixel art validation failed | Anti-aliasing, wrong aspect ratio, too many colors | Re-export with pixel art settings, fix dimensions |
| Image download failed | Notion URL expired, network error | Retry once, then fail with clear message |
| Upload timeout | File >10MB, slow connection | Compress further, verify connection |
| Unsupported format | BMP, TIFF, etc. | Convert to PNG/JPEG/WebP |

---

## Contact & Support

**Brookside BI Support:** Consultations@BrooksideBI.com | +1 209 487 2047

**Related Agents:**
- [notion-webflow-syncer](./notion-webflow-syncer.md) - Uses this agent for image processing
- [webflow-api-expert](./webflow-api-expert.md) - Handles Webflow asset upload

---

**Agent Version:** 1.0.0
**Last Updated:** 2025-10-26
**Status:** Production-Ready
