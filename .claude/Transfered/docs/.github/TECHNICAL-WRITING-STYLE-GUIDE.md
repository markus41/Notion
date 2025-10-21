# Technical Writing Style Guide

> **Establish consistent writing standards to streamline content development** across Agent Studio documentation, designed to improve clarity and drive reader comprehension.

**Best for:** Documentation authors, technical writers, and contributors creating or reviewing technical content.

**Last Updated:** 2025-10-14 | **Version:** 2.0

---

## Table of Contents

- [Voice and Tone](#voice-and-tone)
- [Grammar and Mechanics](#grammar-and-mechanics)
- [Word Choice](#word-choice)
- [Sentence Structure](#sentence-structure)
- [Paragraph Construction](#paragraph-construction)
- [Code and Technical Elements](#code-and-technical-elements)
- [Lists and Enumeration](#lists-and-enumeration)
- [Links and Cross-References](#links-and-cross-references)
- [Numbers and Dates](#numbers-and-dates)
- [Abbreviations and Acronyms](#abbreviations-and-acronyms)
- [Formatting Conventions](#formatting-conventions)
- [Common Mistakes](#common-mistakes)

---

## Voice and Tone

### Active Voice (Preferred)

**Use active voice** for clarity and directness.

**Good:**
- "The orchestrator executes workflows in parallel."
- "Configure the API endpoint before deployment."
- "Azure AD validates the authentication token."

**Bad:**
- "Workflows are executed in parallel by the orchestrator."
- "The API endpoint should be configured before deployment."
- "The authentication token is validated by Azure AD."

**Exception:** Passive voice is acceptable when:
- The actor is unknown or unimportant: "The file was corrupted."
- You want to emphasize the recipient: "Your data is encrypted at rest."

###Present Tense

**Use present tense** to describe current state and behavior.

**Good:**
- "The API returns a JSON response."
- "Cosmos DB stores workflow state."
- "The system validates input before processing."

**Bad:**
- "The API will return a JSON response."
- "Cosmos DB will store workflow state."
- "The system would validate input before processing."

### Second Person ("You")

**Address the reader directly** using "you" and "your."

**Good:**
- "You can configure rate limits in the portal."
- "Deploy your application to Azure."
- "Your workflow executes sequentially by default."

**Bad:**
- "The user can configure rate limits."
- "One can deploy applications to Azure."
- "The developer's workflow executes sequentially."

**Exception:** Use third person in architecture documents describing system behavior:
- "The system routes requests to available instances."

### Professional but Approachable

**Balance technical precision with accessibility.**

**Good:**
- "This solution is designed to streamline deployment workflows by automating container builds."
- "Organizations scaling Azure infrastructure across departments benefit from centralized governance."

**Bad:**
- "This thing automates deployments." (too casual)
- "Pursuant to the aforementioned architectural paradigm, said system facilitates..." (too formal)

---

## Grammar and Mechanics

### Punctuation

#### Commas

**Use serial (Oxford) comma:**
- ✅ "TypeScript, Python, and C# are supported."
- ❌ "TypeScript, Python and C# are supported."

**Use commas for clarity:**
- ✅ "After the deployment completes, verify the health endpoint."
- ❌ "After the deployment completes verify the health endpoint."

#### Semicolons

**Use semicolons** to connect closely related independent clauses:
- ✅ "The API handles authentication; the orchestrator manages workflows."

**Avoid overuse:** Consider splitting into separate sentences for clarity.

#### Colons

**Use colons** to introduce lists, examples, or explanations:
- ✅ "Three patterns are supported: sequential, parallel, and iterative."
- ✅ "The error indicates a missing dependency: `azure-cosmos`."

#### Hyphens and Dashes

**Hyphens (-)** for compound modifiers:
- "cloud-native architecture"
- "multi-region deployment"
- "auto-scaling configuration"

**Em dashes (—)** for emphasis or aside:
- "The orchestrator—built on .NET 8—coordinates agent execution."

**En dashes (–)** for ranges:
- "Pages 1–10"
- "2025-01-15–2025-01-31"

### Capitalization

#### Title Case for Headings (H1, H2)

- ✅ "Establish Scalable Agent Orchestration"
- ❌ "Establish scalable agent orchestration"

**Rules:**
- Capitalize first and last words
- Capitalize nouns, verbs, adjectives, adverbs
- Lowercase articles (a, an, the), conjunctions (and, but, or), prepositions <5 letters (in, on, at, to)

#### Sentence Case for H3+

- ✅ "Configure authentication settings"
- ❌ "Configure Authentication Settings"

#### Product and Technology Names

**Use official capitalization:**
- Azure OpenAI (not "Azure Openai")
- SignalR (not "Signalr")
- TypeScript (not "Typescript")
- Cosmos DB (not "CosmosDB" or "cosmos db")
- .NET (not "dotnet" in prose, but `dotnet` in code)

#### General Rules

**Capitalize:**
- Proper nouns: Azure, GitHub, Microsoft
- Product names: Agent Studio, Power BI
- Service names: App Service, Container Apps
- Defined terms on first use: "The Orchestrator Service manages..."

**Lowercase:**
- Generic terms: orchestrator (when not referring to the specific service)
- Technology categories: microservices, containers, databases

---

## Word Choice

### Precise Terminology

**Use exact technical terms:**

✅ **Correct:**
- "Authentication" (verifying identity)
- "Authorization" (granting permissions)
- "Endpoint" (specific API route)
- "Request" and "Response" (HTTP transaction)
- "Parameter" (function input)
- "Argument" (value passed to parameter)

❌ **Avoid:**
- Using "authentication" and "authorization" interchangeably
- "API" when you mean "endpoint"
- "Response" when you mean "result"

### Avoid Jargon and Buzzwords

**Replace vague terms with specific descriptions:**

| Avoid | Use Instead |
|-------|-------------|
| "Leverage" | Use, utilize, employ |
| "Synergy" | Coordination, integration |
| "Paradigm" | Model, approach, pattern |
| "Robust" | Reliable, fault-tolerant (be specific) |
| "Cutting-edge" | Modern, current |
| "Best-of-breed" | Industry-leading, highly-rated |

**Exception:** Industry-standard terms are acceptable:
- "Cloud-native"
- "Microservices"
- "Serverless"
- "CI/CD"

### Inclusivity and Accessibility

**Use inclusive language:**

| Avoid | Use Instead |
|-------|-------------|
| "Guys" | Team, folks, everyone |
| "Blacklist/Whitelist" | Blocklist/Allowlist, Denylist/Permitlist |
| "Master/Slave" | Primary/Replica, Leader/Follower |
| "Sanity check" | Quick check, validation |
| "Dummy data" | Sample data, placeholder data |

### Directness Over Hedging

**Be confident and direct:**

✅ **Good:**
- "Configure the setting."
- "The API requires authentication."
- "This approach improves performance."

❌ **Avoid hedging:**
- "You might want to configure the setting."
- "The API may require authentication."
- "This approach should improve performance."

**Exception:** Use qualifiers when genuinely uncertain or variable:
- "Performance may vary depending on workload."
- "Results typically return within 200ms."

---

## Sentence Structure

### Length

**Aim for 15-20 words per sentence on average.**

✅ **Good:**
- "The orchestrator coordinates workflow execution across distributed agents." (9 words)

❌ **Too long:**
- "The orchestrator, which is a .NET 8 service running in Azure Container Apps, coordinates the execution of workflows across a distributed set of agents that may be running in different regions." (35 words)

**Better (split):**
- "The orchestrator coordinates workflow execution across distributed agents. This .NET 8 service runs in Azure Container Apps and supports multi-region deployments."

### Parallel Structure

**Keep list items parallel in structure:**

✅ **Good:**
- "The API supports authentication, authorization, and rate limiting."
- "Deploy to dev, test in staging, and promote to production."

❌ **Bad:**
- "The API supports authentication, can authorize requests, and rate limiting." (mixed verb forms)

### Lead with Important Information

**Put key information first:**

✅ **Good:**
- "Azure AD validates tokens before granting access."
- "Configure CORS settings to allow cross-origin requests."

❌ **Bad:**
- "Before granting access, Azure AD validates tokens."
- "To allow cross-origin requests, configure CORS settings."

---

## Paragraph Construction

### One Idea Per Paragraph

Each paragraph should convey a single main idea.

**Structure:**
1. **Topic sentence** (main idea)
2. **Supporting sentences** (details, examples)
3. **Concluding/transitional sentence** (optional)

### Length

**Target:** 3-7 sentences per paragraph
**Maximum:** 8 sentences

**Exception:** Introductory paragraphs can be 1-2 sentences.

### Transitions

**Use transitions to connect ideas:**

| Purpose | Transition Words |
|---------|------------------|
| **Addition** | Additionally, furthermore, moreover, also |
| **Contrast** | However, nevertheless, conversely, in contrast |
| **Cause/Effect** | Therefore, consequently, as a result, thus |
| **Example** | For example, for instance, specifically |
| **Sequence** | First, next, then, finally |

**Example:**
"The orchestrator manages workflow execution. **Additionally,** it provides checkpoint-based recovery. **As a result,** workflows can resume after failures without data loss."

---

## Code and Technical Elements

### Inline Code

**Use backticks** for:
- Code elements: `function`, `class`, `variable`
- File names: `package.json`, `appsettings.json`
- Commands: `npm install`, `dotnet build`
- HTTP methods: `GET`, `POST`, `PUT`
- Status codes: `200 OK`, `404 Not Found`
- Technical values: `true`, `false`, `null`

**Don't use backticks for:**
- Product names: Azure (not `Azure`)
- General concepts: authentication (not `authentication`)

### Code Blocks

**Always specify language:**

````markdown
```typescript
const client = new ApiClient({ apiKey });
```
````

**Add comments for clarity:**

```typescript
// Establish retry logic to improve resilience
const client = new ApiClient({
  apiKey: process.env.API_KEY,
  maxRetries: 3,
  backoff: 'exponential'
});
```

### Command-Line Examples

**Use `bash` for multi-platform commands:**

```bash
# Deploy to Azure
az deployment group create \
  --resource-group my-rg \
  --template-file deploy.bicep
```

**Use `powershell` for Windows-specific:**

```powershell
# Deploy to Azure (PowerShell)
New-AzResourceGroupDeployment `
  -ResourceGroupName "my-rg" `
  -TemplateFile "deploy.bicep"
```

### Placeholders

**Use clear, descriptive placeholders:**

✅ **Good:**
- `{subscription-id}`
- `{resource-group-name}`
- `{your-api-key}`

❌ **Bad:**
- `<sub>`
- `XXX`
- `YOUR_KEY_HERE`

---

## Lists and Enumeration

### Unordered Lists

**Use when order doesn't matter:**

- Supported languages: TypeScript, Python, C#
- Key features
- Prerequisites (if no specific order)

**Formatting:**
- Start each item with capital letter
- End with period if complete sentence
- No period if fragment

✅ **Complete sentences:**
- The API supports authentication.
- Rate limiting prevents abuse.
- Caching improves performance.

✅ **Fragments:**
- Authentication support
- Rate limiting
- Response caching

### Ordered Lists

**Use when sequence matters:**

1. Install prerequisites
2. Configure settings
3. Deploy application
4. Verify deployment

**Formatting:**
- Use numbers (not letters)
- Parallel structure for all items
- End with period

### Task Lists

**Use for actionable checklists:**

- [ ] Azure subscription created
- [ ] CLI tools installed
- [ ] Repository cloned

---

## Links and Cross-References

### Link Text

**Use descriptive link text:**

✅ **Good:**
- "See the [API Reference](/api/reference) for endpoint details."
- "Read the [deployment guide](/guides/operator/deployment) for step-by-step instructions."

❌ **Bad:**
- "Click [here](/api/reference) for the API reference."
- "More information is available [here](/guides/operator/deployment)."

### External Links

**Indicate external links:**

- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/) (external)

**Or use context:**

- "See the official [Azure documentation](https://learn.microsoft.com/azure) for more details."

### Cross-References

**Format:**
- "As described in [Architecture Overview](./architecture/overview.md)..."
- "For more information, see [Authentication Guide](/guides/security/authentication)."

---

## Numbers and Dates

### Numbers

**Spell out:**
- Zero through nine: "three instances," "five minutes"
- Numbers starting sentences: "Twelve agents are available."

**Use numerals:**
- 10 and above: "15 minutes," "100 requests"
- Technical measurements: "8 GB RAM," "2 CPU cores"
- Versions: "version 2.0," ".NET 8"
- Percentages: "50% improvement"

**Exceptions:**
- Ranges: "5-10 instances" (not "five-10")
- Units: "8 GB" (not "eight GB")

### Dates and Times

**Date format:** ISO 8601 preferred
- Full: `2025-01-15T10:30:00Z`
- Date only: `2025-01-15`
- Human-readable: "January 15, 2025"

**Time format:**
- 24-hour: `14:30 UTC`
- 12-hour: `2:30 PM UTC` (include time zone)

---

## Abbreviations and Acronyms

### First Use

**Spell out on first use:**

"The Application Programming Interface (API) provides programmatic access. The API supports REST and GraphQL."

**Exception:** Well-known acronyms:
- URL, HTML, CSS, JSON, XML
- HTTP, HTTPS, TCP, IP
- CPU, RAM, SSD

### Plural Forms

**Add 's' without apostrophe:**
- APIs (not API's)
- VMs (not VM's)
- CPUs (not CPU's)

### Latin Abbreviations

**Avoid in prose text:**

| Avoid | Use Instead |
|-------|-------------|
| e.g. | For example |
| i.e. | That is, in other words |
| etc. | And so on (or list all items) |

**Exception:** Acceptable in parenthetical statements:
- "Supported languages (e.g., TypeScript, Python)"

---

## Formatting Conventions

### Emphasis

**Bold** for UI elements and strong emphasis:
- Click the **Submit** button.
- **Important:** Back up your data before proceeding.

**Italics** for introducing terms:
- The *orchestrator* coordinates workflow execution.

### Callouts

**Use VitePress callout syntax:**

```markdown
::: tip Best Practice
Use environment variables for configuration.
:::

::: warning Breaking Change
Version 2.0 introduces a new API contract.
:::

::: danger Security Risk
Never commit API keys to source control.
:::
```

### Keyboard Keys

**Use `<kbd>` tags or describe:**
- Press <kbd>Ctrl</kbd> + <kbd>C</kbd>
- "Press Ctrl+C to copy"

### UI Navigation

**Use > for navigation paths:**
- Azure Portal > Resource Groups > Create
- Settings > Security > API Keys

---

## Common Mistakes

### "Its" vs. "It's"

- **Its** (possessive): "The API returns its response."
- **It's** (contraction of "it is"): "It's important to validate input."

**Rule:** Avoid contractions in technical writing; use "it is."

### "That" vs. "Which"

- **That** (restrictive, no comma): "The endpoint that handles authentication requires a token."
- **Which** (non-restrictive, comma): "The API, which was released in 2025, supports OAuth."

### "Affect" vs. "Effect"

- **Affect** (verb): "This change affects performance."
- **Effect** (noun): "The effect is a 50% improvement."

### "Ensure" vs. "Insure" vs. "Assure"

- **Ensure** (make certain): "Ensure the API key is valid."
- **Insure** (financial protection): "Insure your data against loss."
- **Assure** (convince): "We assure you the system is secure."

### "Login" vs. "Log in"

- **Login** (noun/adjective): "Enter your login credentials."
- **Log in** (verb): "Log in to the portal."

Same pattern:
- **Setup** (noun): "Complete the setup process."
- **Set up** (verb): "Set up your environment."

---

## Quick Reference Checklist

Before publishing, verify:

- [ ] Active voice used (80%+ of sentences)
- [ ] Present tense throughout
- [ ] Second person ("you") for instructions
- [ ] Sentences average 15-20 words
- [ ] Paragraphs are 3-7 sentences
- [ ] One idea per paragraph
- [ ] Serial (Oxford) commas used
- [ ] Code elements in backticks
- [ ] Descriptive link text (no "click here")
- [ ] Acronyms spelled out on first use
- [ ] Product names capitalized correctly
- [ ] Numbers 0-9 spelled out, 10+ as numerals
- [ ] No jargon without explanation
- [ ] Inclusive language used
- [ ] Transitions between paragraphs

---

## Additional Resources

- [Documentation Design System](./DOCUMENTATION-DESIGN-SYSTEM.md)
- [Accessibility Checklist](./ACCESSIBILITY-CHECKLIST.md)
- [Microsoft Writing Style Guide](https://learn.microsoft.com/style-guide/welcome/)
- [Google Developer Documentation Style Guide](https://developers.google.com/style)

---

**Maintained by:** Documentation Team | **Last Updated:** 2025-10-14 | **Version:** 2.0
