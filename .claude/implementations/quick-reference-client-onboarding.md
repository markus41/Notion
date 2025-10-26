# Quick Reference: Client Onboarding Automation

**⏱️ Implementation Time**: 2-3 hours | **💰 ROI**: 2,051% | **⚡ Setup Difficulty**: Moderate

---

## 🎯 What It Does

When you add a new client with Status = "🟢 Active":
1. ✅ Creates onboarding project ($5K budget, 30-day timeline)
2. ✅ Generates 6 standard tasks (requirements, kickoff, documentation, etc.)
3. ✅ Schedules kickoff meeting (7 days from now, 2pm)
4. ✅ Links standard software stack (Power BI, Azure tools)
5. ✅ Sends Teams notification to Lead Consultant
6. ✅ Creates SharePoint client folder (optional)

**Result**: 45 minutes → 5 minutes (89% time savings)

---

## 📋 Prerequisites Checklist

- [ ] Power Automate Premium license ($15/month)
- [ ] Notion integration created with write access
- [ ] Microsoft Teams channel for notifications
- [ ] 5 database IDs verified (see below)

---

## 🔑 Database IDs (Copy These)

```
Clients DB:          dadb7b39-1adf-424d-9766-3d229a23af78
BI Projects DB:      d1ad6014-e7da-4a8d-aed2-5501f9721ddf
Client Tasks DB:     0857ef60-5326-47b1-b621-97fdf0385fe7
Meeting Notes DB:    3f265127-e78b-49b4-a063-655823f3fbf9
Software Tracker DB: 13b5e9de-2dd1-45ec-839a-4f3d50cd8d06
```

---

## ⚡ Quick Setup Steps

### 1. Create Power Automate Flow (30 mins)

**Trigger**: When an item is created in Clients DB (Status = "🟢 Active")

**Actions** (in order):
1. **Create Project**: Use BI Projects DB, set Budget = 5000, link Client
2. **Create 6 Tasks**: Loop through standard checklist, link to Project
3. **Create Meeting**: Schedule kickoff 7 days out, link to Project
4. **Link Software**: Add Power BI Pro, Azure Storage, Power Automate, Azure SQL
5. **Send Teams Card**: Notify Lead Consultant with client details
6. *Optional*: Create SharePoint folder structure

### 2. Test with Sample Client (15 mins)

Create test client:
- Name: "Test Client - ABC Corp"
- Status: "🟢 Active"
- Industry: Technology
- Contract Value: $50,000
- Priority: 🟡 Medium

**Verify**: 1 project + 6 tasks + 1 meeting + Teams notification

### 3. Enable & Monitor (ongoing)

- Turn on flow for production
- Monitor first 3 onboarding sessions
- Measure time savings vs. 45-minute baseline

---

## 🚨 Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| Flow triggers but no project created | Verify BI Projects DB ID is correct |
| Tasks not linked to project | Confirm "Project" relation property exists |
| Teams notification not sent | Re-authenticate Teams connector |
| SharePoint fails | Verify site URL and permissions |

---

## 📊 Standard Task Checklist (Customize These)

1. **Schedule client kickoff meeting** (🔴 High, 1 hour)
2. **Document current state assessment** (🔴 High, 3 hours)
3. **Define project scope and objectives** (🔴 High, 2 hours)
4. **Identify data sources and access requirements** (🟡 Medium, 2 hours)
5. **Establish communication cadence** (🟡 Medium, 1 hour)
6. **Review and sign SOW** (🔴 High, 1 hour)

**Total Estimated Hours**: 10 hours

---

## 📈 Success Metrics

**Track These Weekly**:
- Onboarding time: Target <5 minutes (from 45 min baseline)
- Flow success rate: Target 100%
- First task completion: Target same day (from 2-3 days)
- Team satisfaction: Survey consultants monthly

**Expected Annual Savings**: $15,167
**Implementation Cost**: $705 (setup + licensing)
**Payback Period**: 3 weeks

---

## 🔗 Full Documentation

**Detailed Guide**: [.claude/implementations/phase-5-client-onboarding-automation.md](.claude/implementations/phase-5-client-onboarding-automation.md)

Includes:
- Complete Power Automate JSON configurations
- Error handling & retry logic
- 3 detailed test scenarios
- Troubleshooting guide
- ROI calculations

---

## 💡 Next Automations (Phase 5.2)

1. **Health Score Monitoring** (2 hours) - Daily automated alerts for at-risk clients
2. **Budget Tracking** (2 hours) - 75%, 90%, 100% threshold notifications
3. **Task Auto-Assignment** (3 hours) - Assign tasks based on team capacity
4. **Meeting Notes AI** (4 hours) - Extract action items from transcripts

**Total Phase 5 Value**: $1,400-$1,750 weekly time savings

---

**Questions?** Consultations@BrooksideBI.com | +1 209 487 2047
