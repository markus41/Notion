# DSP Operations Interview - Critical Data Needs

**Purpose**: Establish comprehensive understanding of DSP operations to inform realistic Sacramento dummy data generation and UI design for demo environment.

**Interview Date**: 2025-10-24
**Interviewer**: Markus Ahling
**Expected Duration**: 45-60 minutes

---

## 🎯 Priority 1: Cortex UI & Data Structure (CRITICAL)

### Screenshots Needed
- [ ] Cortex main dashboard (route grid view)
- [ ] Individual route detail page
- [ ] Driver progress view (real-time updates)
- [ ] Rescue assignment interface
- [ ] VTO management screen (if exists in Cortex)
- [ ] Scorecard/metrics dashboard

### Data Format Questions
1. **Route Data Structure**:
   - What is the exact format of route codes? (e.g., "DLA9-CX-1" or different pattern?)
   - How many routes typically assigned per day at a Sacramento station?
   - What data points are visible for each route?
     - Driver name
     - Total stops
     - Completed stops
     - Package count
     - Current location (latitude/longitude)
     - Status indicators
     - Estimated completion time

2. **Driver Progress Tracking**:
   - How often does Cortex refresh driver progress? (30 seconds? 1 minute?)
   - What triggers "behind schedule" calculations?
   - What metrics determine Green (0-1 behind) vs. Yellow (2-5) vs. Red (6+)?
   - Is there a "packages per hour" benchmark visible?

3. **Real-Time Location**:
   - Does Cortex show driver location on a map?
   - What mapping service does Amazon use?
   - How accurate are the location pins?

### Sample Data Request
- **Anonymized route data export** (1 day's worth if possible)
  - Route assignments
  - Driver names (can be anonymized: "Driver A", "Driver B")
  - Stop counts and package volumes
  - Actual performance metrics (stops completed, time taken)
  - Behind/ahead schedule indicators

---

## 🔄 Priority 2: VTO (Voluntary Time Off) Workflow

### Process Documentation Needed
1. **Current VTO Flow**:
   - How does a DSP owner initiate VTO offer?
   - How are drivers notified? (Text? App? Amazon Flex?)
   - What is the acceptance window? (e.g., "Accept within 30 minutes")
   - What happens after driver accepts VTO?
     - Route reassignment process
     - ADP/Paycom logging
     - Replacement driver assignment

2. **ADP Integration Points**:
   - What specific data syncs to ADP when VTO is accepted?
   - Is it automatic or manual entry?
   - What shows up on driver's timecard in ADP?
   - How are excused absences coded?

3. **VTO Scenarios**:
   - Typical VTO acceptance rate (percentage)
   - How often is VTO offered? (Daily? Weekly?)
   - Peak times for VTO (slow days, weather delays)
   - Replacement assignment logic (first available? best performer? geographic proximity?)

### Screenshots/Examples
- [ ] VTO offer message (text or app screenshot)
- [ ] ADP timecard showing VTO entry
- [ ] Current manual process documentation

---

## 🚨 Priority 3: Rescue Operations

### Decision Criteria
1. **When is a rescue needed?**
   - Specific threshold (e.g., "6 stops behind at 3pm")
   - Time of day considerations
   - Package volume remaining

2. **Who gets assigned to rescue?**
   - Geographic proximity (within X miles?)
   - Driver performance rating
   - Current driver's ahead-of-schedule status
   - Availability (already completed route?)

3. **Rescue Execution**:
   - How are packages transferred?
   - How is rescue logged in Cortex?
   - Compensation for rescue driver (flat rate? per package?)
   - Success metrics (how often do rescues succeed?)

### Real-World Examples
- Typical number of rescues per day at Sacramento station
- Common reasons for needing rescue (new driver, route complexity, vehicle issues)
- Average time to complete a rescue

---

## 📱 Priority 4: Driver Mobile Experience

### Current Tools Used
1. **Amazon Flex App**:
   - What features do drivers actually use?
   - What frustrates drivers about Flex?
   - Screenshots if possible

2. **Time Clock System**:
   - How do drivers currently clock in/out?
   - Is geofencing used? (Must be at station to clock in?)
   - Break tracking process

3. **DVIC (Digital Vehicle Inspection)**:
   - Current DVIC checklist items (provide full list)
   - Photo requirements
   - How is DVIC submitted? (App? Paper?)
   - What happens when driver reports vehicle issue?

### Pain Points
- What takes too long on mobile?
- What features are missing?
- What causes driver frustration?

---

## 📍 Priority 5: Sacramento-Specific Operations

### Station Information
- [ ] Actual station code (e.g., DSC5, DCK6, or should we invent one?)
- [ ] Station address (Elk Grove area)
- [ ] Geofence radius for clock in/out (100 meters? 200 meters?)

### Route Configurations by Area

**Elk Grove (High-Density Residential)**:
- Typical stops per route: _____ (estimate: 180?)
- Package count per route: _____ (estimate: 245?)
- Stops per hour benchmark: _____ (estimate: 20?)
- Common complexities:
  - Apartment complexes (which ones?)
  - Gated communities
  - Heavy traffic times

**Rancho Cordova (Mixed Residential/Commercial)**:
- Typical stops per route: _____ (estimate: 160?)
- Package count per route: _____ (estimate: 210?)
- Stops per hour benchmark: _____ (estimate: 18?)
- Business park deliveries
- Mix of apartments and single-family homes

**Galt (Rural Low-Density)**:
- Typical stops per route: _____ (estimate: 120?)
- Package count per route: _____ (estimate: 150?)
- Stops per hour benchmark: _____ (estimate: 12?)
- Long distances between stops
- Farm properties and large lots
- Cell coverage issues?

### Real Street Names and Addresses
- Provide 10-15 actual street names per area for realistic dummy data:
  - Elk Grove: Laguna Ridge Dr, Elk Grove Florin Rd, _____, _____, _____
  - Rancho Cordova: Sunrise Blvd, Folsom Blvd, _____, _____, _____
  - Galt: Twin Cities Rd, Simmerhorn Rd, _____, _____, _____

---

## 📊 Priority 6: Performance Benchmarks

### Real-World Metrics
1. **Driver Performance**:
   - Average packages delivered per hour: _____
   - Top performer packages/hour: _____
   - Struggling driver packages/hour: _____
   - Industry benchmark: _____

2. **Route Completion**:
   - Typical route completion time: _____ hours
   - Fastest route completion: _____ hours
   - Routes requiring rescue: _____% (e.g., 10%?)

3. **Fantastic Plus Achievement**:
   - What is Fantastic Plus? (Scorecard threshold)
   - Typical achievement rate at Sacramento station: _____%
   - Annual bonus value: $_____ (mentioned in docs: $780K+?)

4. **Driver Retention**:
   - Average tenure: _____ months
   - Turnover rate: _____%
   - Top reasons for driver departure

---

## 🎨 Priority 7: UI/UX Insights

### Color-Coding Logic
- **Green (On Track)**: Exactly when is a driver "green"?
  - 0 stops behind? 0-1 stops behind? Ahead of schedule?
- **Yellow (At Risk)**: Threshold definition
  - 2-5 stops behind at any time?
  - Time-dependent? (2 stops behind at 2pm is worse than at 10am?)
- **Red (Critical)**: Threshold definition
  - 6+ stops behind?
  - Automatic rescue trigger?

### Dashboard Priorities
- What information do dispatchers look at MOST often?
- What requires immediate action?
- What is just "nice to know"?

### Mobile App Priorities
- What do drivers need to access most frequently?
- What frustrates them about current tools?
- What would save them the most time?

---

## 🔐 Priority 8: Legal & Compliance

### Web Scraping Legality
1. **DSP Authorization**:
   - Does DSP own their Cortex credentials?
   - Can DSP authorize third-party tool to use their credentials?
   - Any Amazon ToS restrictions on automated access?

2. **Data Ownership**:
   - Who owns the route data? (Amazon? DSP? Joint?)
   - Can DSP export and store their own operational data?

3. **Liability Considerations**:
   - If web scraping fails, what's the fallback?
   - Should we plan for manual CSV import as backup?

---

## 💰 Priority 9: Cost & Pricing

### DSP Willingness to Pay
- What is the value of saving 15-20 hours/week?
- Current software spend (how many tools are they juggling?)
- Acceptable price point for unified platform:
  - $200/month?
  - $500/month?
  - $1,000/month?
  - Tiered pricing (per driver? per route?)

---

## 📋 Priority 10: Integration Requirements

### ADP Workforce Now
- [ ] Do you have ADP API documentation? (or can you request from ADP)
- [ ] What ADP tier/plan? (Essential? Enhanced? Complete?)
- [ ] API access credentials available for sandbox testing?

### Paycom
- [ ] Using Paycom or different payroll system?
- [ ] API access available?
- [ ] Integration points (time cards, payroll, excused absences)

### QuickBooks (Future)
- [ ] Accounting software currently used?
- [ ] Interest in financial analytics integration?

---

## 🎯 Deliverables from Interview

**Immediate Needs**:
1. ✅ Cortex dashboard screenshots (at least 3-5)
2. ✅ Sample route data (1 day, anonymized)
3. ✅ VTO workflow documentation or process description
4. ✅ DVIC checklist (complete list of inspection items)
5. ✅ Sacramento route configurations (stops, packages, benchmarks)

**Nice-to-Have**:
- ADP/Paycom screenshots or sample data
- Actual driver names (for realistic dummy data naming patterns)
- Real-world rescue scenarios (specific examples)
- Financial data (route profitability, driver pay rates)

---

## 📝 Post-Interview Actions

After gathering this data, we will:
1. **Generate Sacramento dummy data** with realistic patterns
2. **Design Cortex mock service** matching actual UI/data structure
3. **Build VTO workflow** matching real-world process
4. **Create DVIC checklist** with authentic inspection items
5. **Design rescue algorithm** based on actual decision criteria
6. **Update Notion DSP Command Center** with all findings
7. **Sync to GitHub documentation** for developer reference

---

**Interview Checklist**:
- [ ] Schedule 60-minute call with DSP operations expert
- [ ] Screen share for Cortex walkthrough
- [ ] Request anonymized data exports before call (if possible)
- [ ] Record session (with permission) for reference
- [ ] Take detailed notes in Notion during call
- [ ] Follow up with any additional questions within 24 hours

**Contact Information**:
- Name: _____________________
- DSP Name: _____________________
- Station: _____________________
- Email: _____________________
- Phone: _____________________
- Best time to reach: _____________________

---

*This document will be updated with actual data gathered from the interview and synced to Notion DSP Command Center.*
