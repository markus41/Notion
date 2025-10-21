# Accessibility Checklist (WCAG 2.1 AA Compliance)

> **Establish accessibility standards to streamline inclusive content development** across Agent Studio documentation, designed to ensure all users can effectively access and navigate documentation regardless of ability.

**Best for:** Documentation authors, designers, and QA teams ensuring content meets WCAG 2.1 Level AA compliance.

**Last Updated:** 2025-10-14 | **Version:** 2.0

---

## Overview

This checklist ensures Agent Studio documentation complies with **Web Content Accessibility Guidelines (WCAG) 2.1 Level AA** standards. All documentation must pass these criteria before publication.

**Why Accessibility Matters:**
- **Legal Compliance:** Meet ADA, Section 508, and international accessibility regulations
- **Broader Reach:** 15% of global population has some form of disability
- **Better UX:** Accessible design benefits all users
- **SEO Benefits:** Improved structure and semantic HTML boost search rankings

---

## Table of Contents

- [Perceivable](#perceivable)
- [Operable](#operable)
- [Understandable](#understandable)
- [Robust](#robust)
- [Testing Tools](#testing-tools)
- [Quick Reference](#quick-reference)

---

## Perceivable

Information and user interface components must be presentable to users in ways they can perceive.

### 1.1 Text Alternatives

Provide text alternatives for non-text content.

#### Images

- [ ] **Alt text provided** for all images
  - Describes content and function, not just subject
  - Concise (under 125 characters)
  - Avoids "image of" or "picture of"
  - Empty `alt=""` for decorative images

**Good Examples:**
```markdown
![Agent orchestration workflow showing sequential execution with checkpoints](./workflow-diagram.png)
```

**Bad Examples:**
```markdown
![Diagram](./workflow-diagram.png)
![](./workflow-diagram.png)  <!-- Missing alt text -->
```

**Test:**
- Run: `grep -r "!\[.*\]" docs/ | grep "!\[\]"` to find missing alt text
- Validate: Read alt text without seeing image - does it convey full meaning?

#### Complex Images (Diagrams, Charts)

- [ ] **Long descriptions** provided for complex visuals
- [ ] **Accessible alternative** (table or text description)

**Example:**
```markdown
![C4 container diagram](./c4-container.png)

**Diagram Description:**
The container diagram shows three tiers:
- Frontend: React web application
- API: .NET API Gateway and SignalR Hub
- Data: Cosmos DB, Redis Cache, Blob Storage

The React app communicates with the API Gateway via REST and SignalR Hub via WebSocket. The API layer interacts with all data stores.
```

#### Icons and Emojis

- [ ] **Icons have text labels** or `aria-label`
- [ ] **Emojis used decoratively**, not for critical information

**Example:**
```markdown
## Prerequisites
- [ ] ✅ Azure subscription (checkmark is decorative)
- [ ] Node.js 18+ installed
```

**Bad:**
```markdown
Click the ⚙️ to configure settings  <!-- Don't rely on emoji alone -->
```

**Better:**
```markdown
Click the Settings icon (⚙️) to configure options
```

#### Video and Audio

- [ ] **Captions** provided for videos (SRT/VTT format)
- [ ] **Transcripts** available below videos
- [ ] **Audio descriptions** for visual-only information

---

### 1.2 Time-Based Media

Provide alternatives for time-based media.

#### Videos

- [ ] Captions synchronized with audio
- [ ] Transcript includes all spoken words and sound effects
- [ ] Audio descriptions for purely visual content

**Example:**
```html
<video controls>
  <source src="./workflow-tutorial.mp4" type="video/mp4">
  <track kind="captions" src="./workflow-tutorial.vtt" srclang="en" label="English">
  Your browser does not support video playback.
</video>

**Transcript:**
[00:00] In this tutorial, we'll create a sequential workflow...
[00:15] First, navigate to the workflow designer...
```

---

### 1.3 Adaptable Content

Create content that can be presented in different ways without losing information.

#### Heading Structure

- [ ] **Logical heading hierarchy** (H1 → H2 → H3, no skipping)
- [ ] **Only one H1** per page (page title)
- [ ] **Headings describe content** (not generic)

**Test:**
- Generate outline from headings - does it make sense?
- Run: `grep -E "^#{1,6} " docs/file.md` to check heading levels

**Example:**
```markdown
# Workflow Creation Guide  <!-- H1: Page title -->

## Overview  <!-- H2: Major section -->

### Prerequisites  <!-- H3: Subsection -->

#### Azure Subscription  <!-- H4: Detail -->

##### Subscription Tiers  <!-- H5: Rare, consider restructuring -->
```

#### Semantic Structure

- [ ] **Lists for related items** (not paragraphs)
- [ ] **Tables for tabular data** (not ASCII art)
- [ ] **Semantic HTML** where applicable

**Good:**
```markdown
## Supported Languages
- TypeScript
- Python
- C#
```

**Bad:**
```markdown
## Supported Languages
TypeScript, Python, C#
```

#### Reading Order

- [ ] **Logical reading order** in source
- [ ] **Content makes sense when linearized** (CSS off)

---

### 1.4 Distinguishable

Make it easier for users to see and hear content.

#### Color Contrast

**WCAG AA Requirements:**
- **Normal text:** 4.5:1 contrast ratio minimum
- **Large text (18pt+ or 14pt+ bold):** 3:1 contrast ratio minimum
- **UI components and graphics:** 3:1 contrast ratio

- [ ] **Text meets contrast requirements**
- [ ] **Links distinguishable** without color alone
- [ ] **Charts/diagrams don't rely on color alone**

**Test:**
- Use [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Test with browser DevTools contrast checker
- View in grayscale - information still clear?

**VitePress Default Colors (verify):**
```css
/* Light mode */
--vp-c-text-1: #2c3e50;  /* On white #ffffff */
/* Contrast ratio: 12.6:1 ✅ */

/* Dark mode */
--vp-c-text-1: #e5e5e5;  /* On #1e1e2e background */
/* Contrast ratio: 11.8:1 ✅ */
```

#### Color Independence

- [ ] **Information not conveyed by color alone**
- [ ] **Additional cues** (icons, labels, patterns)

**Bad:**
```markdown
In the diagram:
- Green boxes are successful
- Red boxes are failed
```

**Good:**
```markdown
In the diagram:
- Boxes with checkmarks (✓, green) are successful
- Boxes with X marks (✗, red) are failed
```

#### Text Sizing

- [ ] **Text resizable to 200%** without loss of functionality
- [ ] **No horizontal scrolling** at 200% zoom (1280px viewport)

**Test:**
- Zoom to 200% in browser
- Verify all content readable and functional

#### Non-Text Contrast

- [ ] **UI components** (buttons, inputs) meet 3:1 contrast
- [ ] **Meaningful graphics** meet 3:1 contrast against background

---

## Operable

User interface components and navigation must be operable.

### 2.1 Keyboard Accessible

Make all functionality available from a keyboard.

#### Keyboard Navigation

- [ ] **All interactive elements** accessible via keyboard
- [ ] **Tab order logical** (follows visual order)
- [ ] **No keyboard traps** (can tab out of all elements)
- [ ] **Keyboard shortcuts documented** if provided

**Test:**
- Navigate entire page using only Tab, Shift+Tab, Enter, Space, Arrow keys
- Verify focus order matches visual layout
- Ensure no focus traps (test custom components)

#### Focus Indicators

- [ ] **Visible focus indicator** on all interactive elements
- [ ] **Focus indicator contrast** meets 3:1 ratio
- [ ] **Focus indicator not hidden** by CSS

**CSS Requirement:**
```css
/* VitePress custom.css already includes: */
*:focus-visible {
  outline: 2px solid var(--vp-c-brand-1);
  outline-offset: 2px;
  border-radius: 4px;
}
```

**Test:**
- Tab through page - focus always visible?
- Focus indicator has sufficient contrast?

#### Keyboard Shortcuts

- [ ] **Custom shortcuts documented**
- [ ] **Shortcuts don't conflict** with browser/screen reader
- [ ] **Can disable/remap shortcuts** (if provided)

**Example (BusinessTechToggle component):**
```markdown
**Keyboard Shortcuts:**
- <kbd>B</kbd> - Switch to Business view
- <kbd>T</kbd> - Switch to Technical view
- <kbd>Tab</kbd> - Navigate between views
```

---

### 2.2 Enough Time

Provide users enough time to read and use content.

#### Time Limits

- [ ] **No automatic time limits** (or adjustable/dismissable)
- [ ] **Session timeouts** have warnings
- [ ] **Auto-updating content** can be paused/controlled

**Example:**
```markdown
::: warning Session Timeout
Your session will expire in 5 minutes due to inactivity.
[Extend Session] [Log Out]
:::
```

#### Moving Content

- [ ] **Animations can be paused** or disabled
- [ ] **Auto-advancing carousels** have pause button
- [ ] **Respect `prefers-reduced-motion`**

**CSS:**
```css
/* VitePress custom.css includes: */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

### 2.3 Seizures and Physical Reactions

Do not design content in a way that is known to cause seizures.

#### Flashing Content

- [ ] **No content flashes more than 3 times per second**
- [ ] **Flashing area below threshold** (<25% of screen)

**Note:** Documentation typically doesn't have flashing content, but verify:
- Animated GIFs
- Video content
- Interactive diagrams with animations

---

### 2.4 Navigable

Provide ways to help users navigate, find content, and determine where they are.

#### Skip Links

- [ ] **"Skip to main content" link** provided
- [ ] **Skip link visible on focus**

**VitePress Implementation:**
```html
<a href="#main-content" class="skip-to-content">Skip to main content</a>
```

**CSS (custom.css):**
```css
.skip-to-content {
  position: absolute;
  top: -40px;
  left: 0;
  background: var(--vp-c-brand);
  color: white;
  padding: 0.75rem 1.5rem;
  z-index: 10000;
}

.skip-to-content:focus {
  top: 0;
}
```

#### Page Titles

- [ ] **Unique, descriptive page titles**
- [ ] **Title describes topic or purpose**

**Format:** `{Page Topic} | Agent Studio Documentation`

**Good:**
```yaml
---
title: "Workflow Creation Guide | Agent Studio"
---
```

#### Link Purpose

- [ ] **Link text describes destination**
- [ ] **No "click here" or "read more" without context**

**Good:**
```markdown
[View the API reference](/api/reference) for endpoint details.
```

**Bad:**
```markdown
Click [here](/api/reference) for more information.
```

#### Multiple Ways to Navigate

- [ ] **Search functionality** available
- [ ] **Table of contents** for long documents
- [ ] **Breadcrumbs** (VitePress provides)
- [ ] **Site map** or navigation menu

#### Headings and Labels

- [ ] **Headings are descriptive**
- [ ] **Form labels clearly describe purpose**

#### Focus Visible

- [ ] **Keyboard focus indicator always visible**

#### Current Location

- [ ] **User can determine their location** (breadcrumbs, active nav)
- [ ] **Current page highlighted** in navigation

---

### 2.5 Input Modalities

Make it easier for users to operate functionality through various inputs beyond keyboard.

#### Touch Targets

- [ ] **Touch targets at least 44x44px**
- [ ] **Adequate spacing between targets** (8px minimum)

**CSS (custom.css includes):**
```css
button, a[role="button"] {
  min-width: 44px;
  min-height: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

@media (max-width: 768px) {
  button, a[role="button"] {
    min-height: 48px;
    min-width: 48px;
  }
}
```

#### Pointer Gestures

- [ ] **Multipoint/path-based gestures have single-pointer alternative**
- [ ] **Drag-and-drop has keyboard alternative**

---

## Understandable

Information and the operation of the user interface must be understandable.

### 3.1 Readable

Make text content readable and understandable.

#### Language

- [ ] **Page language declared** (`lang` attribute)
- [ ] **Language changes marked** (inline)

**HTML:**
```html
<html lang="en">
```

**Inline language change:**
```markdown
This guide uses <span lang="fr">mise en place</span> methodology.
```

#### Reading Level

- [ ] **Content written at appropriate level** (8th-10th grade for general audience)
- [ ] **Technical terms defined on first use**
- [ ] **Complex concepts explained clearly**

**Test:**
- Flesch-Kincaid Reading Ease score: 60+ (target)
- Use readability tools to verify

---

### 3.2 Predictable

Make web pages appear and operate in predictable ways.

#### Consistent Navigation

- [ ] **Navigation order consistent** across pages
- [ ] **Repeated components same location**

**VitePress provides:** Consistent sidebar, header, footer across all pages.

#### Consistent Identification

- [ ] **Icons/buttons with same function labeled consistently**
- [ ] **Similar components behave similarly**

**Example:**
```markdown
<!-- Use consistently across all pages -->
::: tip Best Practice
...
:::
```

#### On Focus/Input

- [ ] **Focusing element doesn't trigger unexpected changes**
- [ ] **Entering data doesn't auto-submit** (without warning)

---

### 3.3 Input Assistance

Help users avoid and correct mistakes.

#### Error Identification

- [ ] **Errors clearly identified**
- [ ] **Error messages descriptive**
- [ ] **Error location indicated**

**Example:**
```markdown
::: danger Validation Error
**API Key Required:** The `apiKey` field is required. Please provide a valid API key before proceeding.
:::
```

#### Labels or Instructions

- [ ] **Form fields have visible labels**
- [ ] **Instructions provided when needed**
- [ ] **Required fields indicated**

**Example:**
```markdown
**API Key** (required)
Enter your Azure OpenAI API key. You can find this in the Azure Portal under Keys and Endpoint.

<input type="text" required aria-label="API Key" />
```

#### Error Suggestion

- [ ] **Error messages include solutions**
- [ ] **Correction suggestions provided**

**Good:**
```markdown
**Error:** Invalid date format

**Solution:** Use ISO 8601 format (YYYY-MM-DD). Example: 2025-01-15
```

#### Error Prevention

- [ ] **Confirmations for destructive actions**
- [ ] **Reversible actions** or undo functionality

---

## Robust

Content must be robust enough that it can be interpreted by a wide variety of user agents, including assistive technologies.

### 4.1 Compatible

Maximize compatibility with current and future user agents, including assistive technologies.

#### Valid HTML

- [ ] **HTML validates** (no unclosed tags, duplicate IDs)
- [ ] **ARIA attributes used correctly**

**Test:**
- [W3C Markup Validator](https://validator.w3.org/)
- Browser DevTools console (check for errors)

#### Name, Role, Value

- [ ] **All UI components have accessible name**
- [ ] **Roles specified** when needed
- [ ] **States and properties communicated** (aria-expanded, aria-selected, etc.)

**Example (BusinessTechToggle):**
```vue
<button
  role="tab"
  :aria-selected="mode === 'business'"
  :aria-controls="'business-panel'"
  @click="mode = 'business'"
>
  Business View
</button>

<div
  id="business-panel"
  role="tabpanel"
  aria-labelledby="business-tab"
>
  <!-- Content -->
</div>
```

#### Status Messages

- [ ] **Status messages announced** to screen readers
- [ ] **Live regions used appropriately** (aria-live)

**Example:**
```html
<div role="status" aria-live="polite" aria-atomic="true">
  Workflow execution started successfully.
</div>
```

---

## Testing Tools

### Automated Testing

**Browser Extensions:**
- [axe DevTools](https://www.deque.com/axe/devtools/) - Comprehensive accessibility testing
- [WAVE](https://wave.webaim.org/extension/) - Visual accessibility evaluation
- [Lighthouse](https://developers.google.com/web/tools/lighthouse) - Built into Chrome DevTools

**Command Line:**
```bash
# Install axe-core CLI
npm install -g @axe-core/cli

# Test page
axe https://docs.agentstudio.io/guides/workflow-creation
```

### Manual Testing

**Keyboard Navigation:**
1. Disconnect mouse
2. Navigate using only Tab, Shift+Tab, Enter, Space, Arrow keys
3. Verify all functionality accessible

**Screen Reader Testing:**
- **Windows:** NVDA (free), JAWS (commercial)
- **macOS:** VoiceOver (built-in, Cmd+F5)
- **Linux:** Orca (free)

**Test checklist:**
- [ ] Navigate by headings (H key)
- [ ] Navigate by links (K key)
- [ ] Jump to forms (F key)
- [ ] Read tables logically
- [ ] Hear alt text for images

**Color Contrast:**
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Chrome DevTools: Inspect element > Contrast ratio

**Zoom/Text Resize:**
- Browser zoom to 200%
- Text-only zoom (Ctrl + on Firefox)

### Assistive Technology Testing

**Minimum testing matrix:**

| AT | Browser | OS |
|----|---------|---|
| NVDA | Chrome | Windows |
| JAWS | Edge | Windows |
| VoiceOver | Safari | macOS |
| TalkBack | Chrome | Android |
| VoiceOver | Safari | iOS |

---

## Quick Reference

### Pre-Publication Checklist

#### Perceivable
- [ ] All images have alt text
- [ ] Complex visuals have long descriptions
- [ ] Videos have captions and transcripts
- [ ] Logical heading hierarchy (H1→H2→H3)
- [ ] Color contrast ≥4.5:1 (normal text), ≥3:1 (large text/UI)
- [ ] Information not conveyed by color alone

#### Operable
- [ ] All functionality keyboard accessible
- [ ] Visible focus indicators on all interactive elements
- [ ] No keyboard traps
- [ ] Touch targets ≥44x44px
- [ ] Skip to main content link provided
- [ ] Descriptive page titles
- [ ] Link text describes destination

#### Understandable
- [ ] Page language declared (`lang="en"`)
- [ ] Reading level appropriate (8th-10th grade)
- [ ] Technical terms defined
- [ ] Navigation consistent across pages
- [ ] Error messages descriptive and actionable
- [ ] Required fields indicated

#### Robust
- [ ] HTML validates (W3C Validator)
- [ ] ARIA attributes used correctly
- [ ] No duplicate IDs
- [ ] Interactive components have accessible names
- [ ] Status messages announced (aria-live)

### Testing Checklist

- [ ] Automated scan with axe DevTools (0 violations)
- [ ] Keyboard navigation test (all features accessible)
- [ ] Screen reader test (content logical and announced correctly)
- [ ] Color contrast verified (WebAIM tool)
- [ ] Zoom to 200% (no horizontal scroll, content readable)
- [ ] Lighthouse accessibility score ≥90

---

## Resources

### Official Guidelines
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Section 508 Standards](https://www.section508.gov/)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)

### Testing Tools
- [axe DevTools](https://www.deque.com/axe/devtools/)
- [WAVE Browser Extension](https://wave.webaim.org/extension/)
- [W3C Markup Validator](https://validator.w3.org/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

### Training
- [WebAIM Articles](https://webaim.org/articles/)
- [A11ycasts (Google)](https://www.youtube.com/playlist?list=PLNYkxOF6rcICWx0C9LVWWVqvHlYJyqw7g)
- [Deque University](https://dequeuniversity.com/)

---

## Contact

Questions about accessibility?
- **Email:** accessibility@brooksidebi.com
- **Internal:** Slack #accessibility channel
- **Issues:** [GitHub Accessibility Label](https://github.com/Brookside-Proving-Grounds/Project-Ascension/labels/accessibility)

---

**Maintained by:** Accessibility Team | **Last Updated:** 2025-10-14 | **Version:** 2.0
