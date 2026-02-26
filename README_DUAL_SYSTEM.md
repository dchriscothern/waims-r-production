# WAIMS - Workload and Injury Management System

**Dual-System Architecture for Professional Basketball Athlete Monitoring**

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![R](https://img.shields.io/badge/R-4.3+-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 🎯 Overview

WAIMS is a comprehensive athlete monitoring system built with **complementary Python and R architectures**, each optimized for different use cases in sports science operations.

### Two Systems, Two Purposes

| System | Purpose | Technology | Use Case |
|--------|---------|------------|----------|
| **Python System** | Interactive Analysis & ML | Streamlit, scikit-learn | Exploratory analysis, injury prediction, demos |
| **R System** | Production Data Pipeline | R, DuckDB, wehoop | Automated workflows, real data integration, reports |

**Why Two Systems?**
- **Different audiences:** Data scientists (Python) vs Operations staff (R)
- **Different workflows:** Interactive exploration vs Automated pipelines
- **Different strengths:** Python for ML/interactivity, R for data pipelines/reporting
- **Real-world replication:** Mirrors actual sports science tech stacks

This architecture demonstrates understanding that **one tool rarely fits all needs** in production environments.

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      WAIMS ECOSYSTEM                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────┐        ┌──────────────────────┐      │
│  │   PYTHON SYSTEM      │        │     R SYSTEM         │      │
│  │   (Interactive)      │        │   (Automated)        │      │
│  ├──────────────────────┤        ├──────────────────────┤      │
│  │                      │        │                      │      │
│  │ • Streamlit          │        │ • wehoop API         │      │
│  │   Dashboard          │        │ • DuckDB Warehouse   │      │
│  │                      │        │ • RMarkdown Reports  │      │
│  │ • ML Injury Risk     │        │ • Automated ETL      │      │
│  │   Predictor          │        │ • Email Alerts       │      │
│  │                      │        │                      │      │
│  │ • Smart Query        │        │ • Quick Insights     │      │
│  │   Interface          │        │   (in reports)       │      │
│  │                      │        │                      │      │
│  │ • Synthetic Demo     │        │ • Real WNBA Data     │      │
│  │   Data               │        │   (2023-2025)        │      │
│  │                      │        │                      │      │
│  └──────────────────────┘        └──────────────────────┘      │
│           │                               │                      │
│           │                               │                      │
│           ▼                               ▼                      │
│  ┌──────────────────────┐        ┌──────────────────────┐      │
│  │   For Analysts       │        │   For Operations     │      │
│  │   • Explore          │        │   • Daily Reports    │      │
│  │   • Experiment       │        │   • Alerts           │      │
│  │   • Demo             │        │   • Archive          │      │
│  └──────────────────────┘        └──────────────────────┘      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🐍 Python System

### Purpose: Interactive Analysis & Machine Learning

**Repository:** [waims-python](https://github.com/dchriscothern/waims-python)

### Features

**6-Tab Interactive Dashboard:**
1. **Today's Readiness** - Current athlete status with color-coded alerts
2. **Trends** - 14-day wellness and workload visualization
3. **Force Plate** - Neuromuscular performance tracking (CMJ, RSI)
4. **Injuries** - Injury log with pre-injury wellness patterns
5. **ML Predictions** - RandomForest injury risk model
6. **Smart Query** - Natural language data exploration

**Machine Learning:**
- **Algorithm:** RandomForest (scikit-learn)
- **Target:** 7-day injury prediction
- **Features:** 15+ variables (sleep, soreness, ACWR, force plate)
- **Research-validated thresholds:**
  - ACWR >1.5 (Gabbett 2016)
  - Sleep <6.5 hrs (Milewski 2014)
  - Asymmetry >10% (Bishop 2018, adjusted for female athletes)

**Smart Query Interface:**
- Natural language pattern matching
- Quick buttons: "Poor Sleep", "High Risk", "Readiness"
- Instant CSV export
- No AI API required (cost: $0)

### Tech Stack
```
Python 3.11+
├── Streamlit (dashboard)
├── pandas (data manipulation)
├── scikit-learn (ML models)
├── plotly (interactive charts)
└── SQLite (local database)
```

### Use Cases
- ✅ Exploratory data analysis
- ✅ ML model experimentation
- ✅ Investor/stakeholder demos
- ✅ Portfolio showcase
- ✅ Educational tool

### Quick Start
```bash
cd waims-python
pip install -r requirements.txt
python generate_database_research.py  # Create demo data
python train_models.py                 # Train ML model
streamlit run dashboard.py             # Launch dashboard
```

**Live Demo:** [waims-dashboard.streamlit.app](https://waims-dashboard.streamlit.app) *(deploy yours!)*

---

## 📈 R System

### Purpose: Production Data Pipeline & Automation

**Repository:** [waims-r-production](https://github.com/dchriscothern/waims-r-production)

### Features

**Automated Data Pipeline:**
1. **Data Ingestion** - wehoop API integration for real WNBA data
2. **Data Warehouse** - DuckDB columnar storage (optimized for analytics)
3. **ETL Processing** - Cleans, transforms, validates athlete data
4. **Report Generation** - Automated HTML reports with Quick Insights
5. **Scheduling** - Daily execution via cron/Task Scheduler
6. **Email Alerts** - Automated notifications for high-risk situations

**Quick Insights (in Reports):**
- 🌙 **Sleep Alert** - Athletes with <6.5 hours
- 🚨 **High Risk** - Elevated injury risk indicators
- ✅ **Readiness Scores** - Team status with color coding
- 📊 **Position Comparison** - Metrics by guard/forward/center

**Real Data Integration:**
- **Source:** WNBA (via wehoop R package)
- **Seasons:** 2023-2025
- **Coverage:** All 12 teams, 40 games/season
- **Refresh:** Daily automated updates

### Tech Stack
```
R 4.3+
├── wehoop (WNBA data API)
├── DuckDB (analytical database)
├── dplyr/tidyverse (data manipulation)
├── RMarkdown (report generation)
├── ggplot2 (visualization)
└── DBI (database interface)
```

### Use Cases
- ✅ Production operations (daily workflows)
- ✅ Automated reporting for coaches
- ✅ Real-time data integration
- ✅ Historical data archiving
- ✅ Regulatory compliance (audit trails)

### Quick Start
```r
# Install dependencies
install.packages(c("wehoop", "duckdb", "dplyr", "rmarkdown"))

# Run data pipeline
setwd("waims-r-production/scripts")
source("fetch_game_data.R")      # Get latest WNBA data
source("run_daily.R")             # Process and report

# View report
browseURL("../reports/daily_report.html")
```

### Automation Setup
```bash
# Linux/Mac (cron)
0 8 * * * Rscript /path/to/waims-r-production/scripts/run_daily.R

# Windows (Task Scheduler)
# Action: Rscript.exe
# Arguments: C:\path\to\waims-r-production\scripts\run_daily.R
# Trigger: Daily at 8:00 AM
```

---

## 🤔 Why Two Systems?

### Design Philosophy

**Not duplication - differentiation.**

#### Python System = Interactive Workspace
*"Let me explore the data and test different ML approaches"*
- Rapid prototyping
- Model experimentation
- Stakeholder presentations
- Educational demonstrations

#### R System = Production Engine
*"Process today's data and send the report to coaches"*
- Reliability over flexibility
- Scheduled automation
- Data quality assurance
- Operational compliance

### Real-World Parallel

**Same as Netflix:**
- **Python:** Data scientists explore patterns, build ML models
- **R:** Production pipelines process user data, generate reports
- **Both:** Essential, complementary, not redundant

**Same as Sports Science Departments:**
- **Python:** Research staff test injury models in Jupyter notebooks
- **R:** Operations staff run daily athlete monitoring workflows
- **Both:** Different roles, different needs

### Interview Talking Points

> *"I built complementary systems that mirror real sports science tech stacks. The Python system is an interactive Streamlit dashboard for exploratory analysis - I can demonstrate ML predictions, adjust model parameters, and use the Smart Query interface for ad-hoc questions. It's perfect for analysis and demos.*
>
> *The R system is a production data pipeline that runs daily, fetches real WNBA data via wehoop, processes it through a DuckDB warehouse, and generates automated HTML reports with Quick Insights sections. This shows production thinking - reliability, automation, and audit trails matter more than flexibility here.*
>
> *This architecture demonstrates understanding that different use cases need different tools. Python excels at interactive ML and visualization, R excels at robust data pipelines and statistical reporting. In industry, you often need both."*

---

## 📚 Research Foundation

Both systems use evidence-based thresholds from peer-reviewed research:

### Core Studies

**WNBA-Specific:**
- **Menon et al. (2026)** - Age, usage rate, workload in WNBA athletes
  - Age >28, usage >25%, high workload = key risk factors

**Female Athlete-Specific:**
- **Hewett et al. (2006)** - ACL injuries 4-6x higher in women
  - Asymmetry threshold: >10% (vs >15% for men)
- **Martin et al. (2018)** - Menstrual cycle effects on injury risk

**General Sports Science:**
- **Gabbett (2016)** - ACWR >1.5 = 2.4x injury risk [2000+ citations]
- **Milewski et al. (2014)** - Sleep <6.5 hrs = 1.7x injury risk [500+ citations]
- **Bishop et al. (2018)** - Asymmetry >15% = 2.6x injury risk [300+ citations]

See [RESEARCH_FOUNDATION.md](docs/RESEARCH_FOUNDATION.md) for complete citations and implementation details.

---

## 🚀 Getting Started

### Prerequisites

**Python System:**
```bash
Python 3.11+
pip
```

**R System:**
```r
R 4.3+
RStudio (recommended)
```

### Installation

**1. Clone Both Repositories:**
```bash
git clone https://github.com/dchriscothern/waims-python.git
git clone https://github.com/dchriscothern/waims-r-production.git
```

**2. Python Setup:**
```bash
cd waims-python
pip install -r requirements.txt
python generate_database_research.py
python train_models.py
streamlit run dashboard.py
```

**3. R Setup:**
```r
setwd("waims-r-production")
install.packages(c("wehoop", "duckdb", "dplyr", "rmarkdown"))
source("scripts/run_daily.R")
```

**4. Verify Both Systems:**
- Python dashboard: http://localhost:8501
- R report: `waims-r-production/reports/daily_report.html`

---

## 📁 Project Structure

### Python System
```
waims-python/
├── dashboard.py              # 6-tab Streamlit dashboard
├── smart_query.py            # Standalone query interface
├── train_models.py           # ML model training
├── generate_database_research.py  # Demo data with research patterns
├── anonymize_players.py      # ATH_001 format conversion
├── requirements.txt
├── docs/
│   ├── SETUP_GUIDE.md
│   ├── RESEARCH_FOUNDATION.md
│   └── API_REFERENCE.md
└── models/
    └── injury_risk_model.pkl
```

### R System
```
waims-r-production/
├── scripts/
│   ├── run_daily.R           # Main automation workflow
│   ├── fetch_game_data.R     # wehoop data ingestion
│   ├── simple_report.R       # Report generation with Quick Insights
│   └── generate_sample_data.R
├── warehouse/
│   └── waims_warehouse.duckdb
├── reports/
│   └── daily_report.html
└── raw/
    └── wehoop_data/
```

---

## 🎓 Learning Resources

### For Students/Portfolio

**Python System:**
- Interactive dashboard design
- Machine learning workflow
- Data visualization best practices
- Natural language interfaces
- Research validation

**R System:**
- Data pipeline architecture
- Automated reporting
- Data warehouse design
- Production best practices
- API integration

### For Hiring Managers

This dual-system architecture demonstrates:
- ✅ Understanding of different use cases
- ✅ Technology selection based on context
- ✅ Production vs research mindsets
- ✅ End-to-end system design
- ✅ Real-world problem solving

---

## 🤝 Contributing

While this is a portfolio project, suggestions and feedback are welcome!

**Areas for contribution:**
- Additional ML models (XGBoost, neural networks)
- New Quick Insights queries
- Enhanced visualizations
- Documentation improvements
- Bug fixes

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details

---

## 👤 Author

**Chris Cothern**
- GitHub: [@dchriscothern](https://github.com/dchriscothern)
- LinkedIn: [Chris Cothern](https://linkedin.com/in/chris-cothern)
- Portfolio: [chriscothern.com](https://chriscothern.com)

---

## 🙏 Acknowledgments

**Data Sources:**
- wehoop R package (WNBA data via ESPN API)
- Research from Gabbett, Milewski, Hewett, and others

**Technologies:**
- Streamlit for Python dashboards
- DuckDB for analytical database
- RMarkdown for report generation

**Inspiration:**
- Real sports science departments using Python + R stacks
- NBA, WNBA, and Premier League athlete monitoring systems

---

## 📊 System Status

**Python System:**
- ✅ Production ready
- ✅ Deployed to Streamlit Cloud
- ✅ Complete documentation
- ✅ ML model trained

**R System:**
- ✅ Production ready
- ✅ Automated daily pipeline
- ✅ Real WNBA data integrated
- ✅ HTML reports generated

**Last Updated:** February 2026

---

*Built with ❤️ for sports science and data-driven athlete care*
