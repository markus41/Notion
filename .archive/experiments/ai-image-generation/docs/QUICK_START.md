# Quick Start Guide - Batch Cover Generation

**Time to first images:** 30 minutes  
**Cost for 50 images:** $2-10 depending on method

---

## Step 1: Test Sample Prompts (5 minutes)

Pick one prompt to test image generation:

```bash
# View a sample prompt
cat /mnt/user-data/outputs/cover_prompts/prompt_22-agent-claude-code-standard---multi-agent-develo.txt
```

Copy the prompt and paste it into:
- **DALL-E 3** (via ChatGPT Plus or API) - Recommended for first test
- **Midjourney** (via Discord) - Best consistency for pixel art
- **Stable Diffusion** - If you have local setup

**Expected result:** 8-bit pixel art office scene with 4 exhausted engineers, one presenting flowchart, others looking confused, coffee cups visible, burnt orange characters on teal background.

---

## Step 2: Validate Quality (5 minutes)

Check generated image against quality control checklist:

✓ Hard pixel edges (no blur)?  
✓ Color palette matches (tan/orange, teal, brown)?  
✓ 3-5 characters present?  
✓ Technical prop visible (chart/diagram)?  
✓ No smiling faces?  
✓ Body language shows exhaustion?  
✓ 16:9 aspect ratio?

**If YES to all:** Proceed to batch generation  
**If NO to any:** Review prompt refinements in main documentation

---

## Step 3: Choose Generation Method (1 minute)

### Option A: Manual (Recommended for First Batch)
**Time:** 10-15 minutes per image  
**Cost:** DALL-E 3 = $0.04/image, Midjourney = $0.20/image  
**Quality:** Highest (can iterate)  
**Effort:** Medium

**Choose this if:** You want maximum control and quality for your first 10-20 covers.

### Option B: Automated
**Time:** 10-30 seconds per image  
**Cost:** DALL-E API = $0.04/image  
**Quality:** Good (no iteration)  
**Effort:** Low (after setup)

**Choose this if:** You have 50+ articles and want to batch-process everything.

### Option C: Hybrid
**Time:** 10 seconds generation + 2 minutes QA per image  
**Cost:** Same as automated  
**Quality:** High (manual QA)  
**Effort:** Medium

**Choose this if:** You want automation with quality gates.

---

## Step 4A: Manual Generation (30 minutes for 5 images)

1. **Open image generation tool** (DALL-E 3 recommended)

2. **For each article in manifest:**
   ```bash
   cat /mnt/user-data/outputs/cover_prompts/prompt_*.txt
   ```

3. **Copy prompt → Paste into generator → Generate**

4. **Download image** and save with article slug:
   ```
   22-agent-claude-code-standard.png
   azure-machine-learning-pipeline.png
   zero-downtime-database-migration.png
   ```

5. **Upload to Webflow assets or hosting**

6. **Update Notion Hero Image URL field** with uploaded URL

7. **Repeat for remaining articles**

---

## Step 4B: Automated Generation (10 minutes setup + instant execution)

1. **Install dependencies:**
   ```bash
   pip install openai requests
   ```

2. **Add API keys to script:**
   ```python
   # In notion_batch_cover_generation.py, add:
   OPENAI_API_KEY = "sk-..."
   NOTION_API_KEY = "ntn_..."
   ```

3. **Add image generation function:**
   ```python
   import openai
   
   def generate_image(prompt):
       response = openai.images.generate(
           model="dall-e-3",
           prompt=prompt,
           size="1792x1024",  # 16:9 closest option
           quality="standard",
           n=1
       )
       return response.data[0].url
   ```

4. **Add to main loop:**
   ```python
   for article in manifest["articles_processed"]:
       print(f"Generating image for: {article['title']}")
       image_url = generate_image(article["prompt"])
       
       # Download and save
       download_image(image_url, f"{article['title']}.png")
       
       # Update Notion
       update_notion_hero_image(article["notion_id"], image_url)
   ```

5. **Run script:**
   ```bash
   python3 /mnt/user-data/outputs/notion_batch_cover_generation.py
   ```

---

## Step 5: Update Notion (2 minutes per article, manual)

For each generated image:

1. **Upload to hosting** (Webflow assets, Cloudinary, S3, etc.)

2. **Get public URL** of uploaded image

3. **In Notion Blog Posts database:**
   - Open article page
   - Find "Hero Image URL" field
   - Paste image URL
   - Set "Last Synced" to current date
   - Change "Webflow Status" to "Updated" (triggers sync)

---

## Step 6: Verify in Webflow (5 minutes)

1. **Trigger Notion → Webflow sync** (if automated)

2. **Or manually sync article to Webflow**

3. **Verify hero image displays correctly:**
   - Category page card
   - Article detail page
   - Social media previews

---

## Troubleshooting

### "Images don't look pixel art enough"
**Fix:** Add to negative prompt: "no anti-aliasing, no blur, no smooth edges"

### "Characters are smiling"
**Fix:** Add: "no happy expressions, everyone looks exhausted and resigned"

### "Colors are wrong"
**Fix:** Emphasize hex codes in prompt, post-process with color correction if needed

### "Too much detail"
**Fix:** Emphasize "chunky blocky forms, 16x16 pixel blocks, maximum 4 colors per element"

### "Not isometric perspective"
**Fix:** Add "exact isometric perspective from above at 30-degree angle"

---

## Cost Calculator

**For 10 articles:**
- DALL-E 3: $0.40
- Midjourney: $2.00
- Stable Diffusion: $0.01

**For 50 articles:**
- DALL-E 3: $2.00
- Midjourney: $10.00
- Stable Diffusion: $0.05

**For 100 articles:**
- DALL-E 3: $4.00
- Midjourney: $20.00
- Stable Diffusion: $0.10

---

## Time Estimates

**Manual generation:**
- First image: 15 minutes (includes learning curve)
- Subsequent images: 10 minutes each
- 10 articles: ~2 hours
- 50 articles: ~8 hours (spread across multiple sessions)

**Automated generation:**
- Setup: 30 minutes (one-time)
- Execution: 10-30 seconds per image
- 50 articles: ~25 minutes total
- 100 articles: ~50 minutes total

---

## Recommended First Batch

Start with **5-10 articles** to validate system:

1. **Pick diverse categories:**
   - 1-2 Engineering articles
   - 1-2 AI/ML articles
   - 1-2 DevOps articles
   - 1-2 Business articles
   - 1 from each remaining category

2. **Generate manually with DALL-E 3**
   - Iterate on 2-3 prompts if needed
   - Document any refinements

3. **Review quality as batch**
   - Do they feel cohesive?
   - Is brand voice consistent?
   - Are technical props appropriate?

4. **If YES to all → Proceed to full batch**
5. **If NO → Refine prompts and regenerate**

---

## Success Metrics

**After first batch of 10 images:**
- ✓ 9+ pass quality checklist (90% success rate)
- ✓ Visual consistency across categories
- ✓ Technical props match article content
- ✓ Brand voice (deadpan absurdism) is clear
- ✓ Generation time <15 minutes per image

**If metrics met → Scale to full production**

---

## Next Steps After First Batch

1. **Document any prompt refinements** in category contexts
2. **Build visual library** of successful outputs for reference
3. **Set up automation** for new article creation
4. **Create variation system** for A/B testing different styles
5. **Track engagement metrics** to optimize cover design

---

## Quick Command Reference

```bash
# View sample prompt
cat /mnt/user-data/outputs/cover_prompts/prompt_*.txt

# View manifest
cat /mnt/user-data/outputs/cover_prompts/batch_generation_manifest.json

# View execution report
cat /mnt/user-data/outputs/cover_prompts/execution_report.txt

# Run production script (with Notion integration)
python3 /mnt/user-data/outputs/notion_batch_cover_generation.py
```

---

## Support Files

**Full documentation:** `/mnt/user-data/outputs/BATCH_COVER_GENERATION_DOCS.md`  
**Executive summary:** `/mnt/user-data/outputs/EXECUTIVE_SUMMARY.md`  
**This guide:** `/mnt/user-data/outputs/QUICK_START.md`

---

**Ready to generate. Start with Step 1.**
