# WAIMS System Architecture Comparison

**Understanding the Dual-System Design**

---

## 🎯 Quick Comparison

| Aspect | Python System | R System |
|--------|---------------|----------|
| **Primary Purpose** | Interactive analysis & ML | Automated data pipeline |
| **User** | Data scientists, analysts | Operations staff, coaches |
| **Interaction** | Real-time dashboard | Scheduled reports |
| **Data** | Synthetic (demo-safe) | Real WNBA (wehoop API) |
| **Update Frequency** | On-demand | Daily automated |
| **Deployment** | Streamlit Cloud (web) | Server (cron/scheduled) |
| **Output** | Interactive visualizations | HTML reports + CSV |
| **ML Focus** | Model development & testing | Model deployment & scoring |
| **Cost** | $0 (Streamlit free tier) | $0 (self-hosted) |

---

## 💡 Design Philosophy

### Not Redundancy - Complementarity

```
┌─────────────────────────────────────────────────────────┐
│              RESEARCH & DEVELOPMENT                     │
│                                                          │
│  Python System                                          │
│  • Explore data                                         │
│  • Test ML models                                       │
│  • Create visualizations                                │
│  • Answer "what if?" questions                          │
│  • Demo to stakeholders                                 │
│                                                          │
│  Tools: Jupyter, Streamlit, scikit-learn               │
│  Mindset: Experimentation                               │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
                    Insights
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│               PRODUCTION & OPERATIONS                    │
│                                                          │
│  R System                                               │
│  • Ingest daily data                                    │
│  • Process & validate                                   │
│  • Generate reports                                     │
│  • Send alerts                                          │
│  • Archive for compliance                               │
│                                                          │
│  Tools: R, DuckDB, RMarkdown, cron                     │
│  Mindset: Reliability                                   │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Workflow Differences

### Python System: Interactive Exploration

**Typical User Journey:**
1. Open dashboard (Streamlit app)
2. Select date range and players
3. Explore trends tab
4. Click "Smart Query" → "High Risk"
5. See instant results
6. Download CSV for further analysis
7. Adjust ML model parameters
8. Re-train and compare results

**Characteristics:**
- ✅ Immediate feedback
- ✅ User-controlled
- ✅ Flexible exploration
- ✅ Visual discovery

**Best For:**
- "Let me see what patterns exist"
- "How does the model perform if I add this feature?"
- "Show stakeholders the concept"

---

### R System: Automated Production

**Typical Workflow:**
1. 🕐 8:00 AM - Scheduler triggers `run_daily.R`
2. 📥 Script fetches latest WNBA data (wehoop)
3. ⚙️ Data processed through DuckDB warehouse
4. 🔍 Quality checks performed
5. 📊 HTML report generated with Quick Insights
6. 📧 Email sent to coaching staff
7. 💾 Data archived to warehouse
8. ✅ Log entry created

**Characteristics:**
- ✅ Fully automated
- ✅ Consistent schedule
- ✅ Auditable (logs)
- ✅ No human intervention

**Best For:**
- "Every morning at 8am, send me the report"
- "I need reliable data every day"
- "Compliance requires audit trails"

---

## 🎓 Educational Value

### What This Architecture Teaches

**For Students:**
- ✅ Different problems require different tools
- ✅ Interactive vs automated workflows
- ✅ Research code vs production code
- ✅ When to use Python vs R

**For Employers:**
- ✅ Understands production requirements
- ✅ Knows when to automate vs interact
- ✅ Can design end-to-end systems
- ✅ Thinks about operational concerns

---

## 🏢 Real-World Parallels

### This Mirrors Actual Sports Science Departments

**Example: NBA Team Structure**

```
Research Staff (Python)              Operations Staff (R)
├── Test new injury models          ├── Daily athlete monitoring
├── Analyze game film               ├── Generate coach reports
├── Experiment with metrics         ├── Email risk alerts
└── Present findings                └── Maintain data warehouse

        Both essential, different roles
```

**Example: WNBA Team Tech Stack**

```
Data Scientists                      Performance Staff
├── Jupyter notebooks               ├── R scripts on server
├── Model development               ├── Automated reporting
├── Visualization prototypes        ├── Database management
└── Research papers                 └── Daily operations

        Same data, different workflows
```

---

## 🔬 Technical Deep Dive

### Why Not Just Use Python for Everything?

**R Advantages for Production:**
1. **Data Pipeline Maturity**
   - `dplyr` optimized for data transformation
   - Native pipe operator (`%>%`)
   - Better at data wrangling

2. **Statistical Reporting**
   - RMarkdown → professional HTML/PDF
   - `ggplot2` for publication-quality charts
   - Built for statistical analysis

3. **wehoop Package**
   - Only available in R
   - Maintained by sports analytics community
   - Direct WNBA data access

4. **Scheduling Integration**
   - R scripts run easily via cron
   - `Rscript` command-line interface
   - Proven in production environments

**Python Advantages for Interactive:**
1. **Dashboard Frameworks**
   - Streamlit → instant web apps
   - Plotly → interactive charts
   - Easy deployment

2. **Machine Learning**
   - scikit-learn ecosystem
   - Larger ML community
   - Better documentation for beginners

3. **General Purpose**
   - More developers know Python
   - Easier to find help
   - Better for portfolios

---

## 📊 Data Flow

### How Data Moves Through the Systems

**R System (Production):**
```
WNBA API (ESPN)
    │
    ▼
wehoop R package
    │
    ▼
DuckDB Warehouse
    │
    ├─► RMarkdown Report (HTML)
    ├─► CSV Exports
    └─► Alert Emails
```

**Python System (Demo):**
```
Research Patterns (Gabbett, Milewski)
    │
    ▼
Synthetic Data Generator
    │
    ▼
SQLite Database
    │
    ├─► ML Model Training
    ├─► Streamlit Dashboard
    └─► Interactive Queries
```

**Key Point:** Separate data sources = separate purposes
- R: Real operational data
- Python: Demo-safe synthetic data

---

## 🎯 Use Case Matrix

| Scenario | Use Which System | Why |
|----------|------------------|-----|
| Coach wants daily report | **R System** | Automated, reliable, scheduled |
| Analyst exploring patterns | **Python System** | Interactive, flexible, visual |
| Stakeholder presentation | **Python System** | Live demo, beautiful UI |
| Compliance audit | **R System** | Logs, archives, data lineage |
| Model experimentation | **Python System** | Rapid iteration, Jupyter |
| Production scoring | **R System** | Scheduled, no human intervention |
| Portfolio showcase | **Python System** | Web-deployed, impressive |
| Historical analysis | **R System** | Real data, DuckDB warehouse |

---

## 💼 Interview Scenarios

### Question: "Why build two systems?"

**Good Answer:**
> "Different use cases require different architectures. The Python system is optimized for interactive analysis - it's perfect for exploring data, testing ML models, and demonstrating concepts to stakeholders. I deployed it to Streamlit Cloud so anyone can access it.
>
> The R system is optimized for production reliability - it runs daily without human intervention, fetches real WNBA data, processes it through a proper data warehouse, and generates automated reports. This mirrors real sports science departments where you need both flexible analysis tools AND reliable operational pipelines.
>
> It would be redundant to build two interactive dashboards, but building one dashboard and one automated pipeline shows I understand different operational contexts."

**Bad Answer:**
> "I wanted to show I can code in both Python and R."
> *(This sounds like duplication for the sake of it)*

---

### Question: "Couldn't you just use Python for everything?"

**Good Answer:**
> "Yes technically, but R has specific advantages for this production pipeline. The wehoop package for WNBA data only exists in R, and R's data transformation tools like dplyr are specifically optimized for these workflows. RMarkdown makes professional statistical reports easy. And R integrates seamlessly with cron for scheduling.
>
> Python is better for the interactive dashboard - Streamlit makes beautiful UIs fast, scikit-learn is better documented for ML, and more developers know Python for collaboration. Using each language for its strengths made more sense than forcing one tool to do both jobs."

---

## 🚀 Deployment Strategy

### Python System
```
Local Development
    │
    ▼
GitHub Repository
    │
    ▼
Streamlit Cloud (Free)
    │
    ▼
Public URL: waims-dashboard.streamlit.app
```

**Result:** Anyone can access and demo

---

### R System
```
Local Development
    │
    ▼
GitHub Repository
    │
    ▼
Server (Digital Ocean / AWS)
    │
    ▼
Cron Job (Daily 8am)
    │
    ▼
Reports Generated → Email → Archive
```

**Result:** Automated production pipeline

---

## ✅ Success Criteria

### How to Know the Architecture is Working

**Python System:**
- [ ] Dashboard accessible via web URL
- [ ] All 6 tabs load and display data
- [ ] Smart Query buttons return instant results
- [ ] ML model predictions visible
- [ ] Can download CSV exports

**R System:**
- [ ] Runs daily without errors
- [ ] Fetches latest WNBA data successfully
- [ ] Generates HTML report with Quick Insights
- [ ] Data properly archived in warehouse
- [ ] Logs show successful execution

**Overall Architecture:**
- [ ] Systems serve different purposes clearly
- [ ] No redundant functionality
- [ ] Each system plays to language strengths
- [ ] Can explain design decisions confidently

---

## 🎯 Key Takeaway

> **This is not two dashboards - it's two different solutions to two different problems.**

**Python System** = "Let me explore and experiment"  
**R System** = "Process today's data and send the report"

**Together they show:** Understanding that software architecture depends on context, not just technology preference.

---

*This dual-system approach demonstrates production-ready thinking, not just coding ability.*
