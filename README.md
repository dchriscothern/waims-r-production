\# WAIMS-R Production



Production monitoring system for professional basketball.



\## 🎯 Features



✅ Multi-source integration  

✅ wehoop - 2025 WNBA data  

✅ Research-validated thresholds  

✅ Automated workflows



\## 🚀 Quick Start

```r

install.packages(c("tidyverse","duckdb","wehoop","glue","fs"))



setwd("C:/projects/waims-r-production")

source("scripts/generate\_sample\_data.R")

```



\## 🔬 Research



\- Gabbett (2016): ACWR \[2000+ citations]

\- Bishop et al. (2018): Asymmetry \[400+ citations]



\## License

MIT

```



Save and close.



---



\### \*\*Step 5: Update .gitignore\*\*



Open `.gitignore`, scroll to bottom, add:

```



\# Data files

raw/\*.csv

warehouse/\*.duckdb

gold\_export/\*.csv

logs/\*.log

```



Save and close.



---



\### \*\*Step 6: Push to GitHub\*\*



\*\*Go to GitHub Desktop:\*\*

\- All changes shown on left

\- Bottom left: `Add R system structure and scripts`

\- Click \*\*"Commit to main"\*\*

\- Click \*\*"Push origin"\*\*



✅ \*\*R repo done!\*\* Check online: `github.com/YOUR\_USERNAME/waims-r-production`



---



\## ✅ DONE! Both Repos Live



\*\*Verify online:\*\*

1\. `github.com/YOUR\_USERNAME/waims-python` - Should see database file

2\. `github.com/YOUR\_USERNAME/waims-r-production` - Should see folder structure



\*\*Add to resume:\*\*

```

GitHub: github.com/YOUR\_USERNAME

\- waims-python - Database with 1,600+ data points

\- waims-r-production - Production system with automation

