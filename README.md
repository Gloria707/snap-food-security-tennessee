# snap-food-security-tennessee
Code for SNAP Participation and Food Security in Tennessee, 2019–2023
# SNAP and Food Security in Tennessee Metro Areas
## Replication Code

**Paper:** SNAP Participation and Food Security in Tennessee Metropolitan Areas: 
Evidence from the CPS Food Security Supplement, 2019–2023

## Data
- Source: Current Population Survey Food Security Supplement (CPS-FSS)
- Years: 2019–2023 (December supplements)
- Access: https://www.census.gov/programs-surveys/cps/data.html
- Files needed: dec19pub.csv, dec20pub.csv, dec21pub.csv, dec22pub.csv, dec23pub.csv

## Sample
- Non-metro and 8 Tennessee metropolitan areas (CBSAs: 16860, 17300, 17420, 27740, 28700, 28940, 32820, 34980)
- SNAP-eligible households at or below 130% FPL (size-adjusted)
- N = 754 households with valid SNAP and food security indicators

## Key Variables
- **food_secure**: Binary (1=food secure, 0=food insecure) from hrfs12m1
- **food_sec_cat**: 4-category USDA scale (1=High, 2=Marginal, 3=Low, 4=Very Low) from hrfs12md
- **snap**: SNAP participation (1=Yes, 0=No) from hesp1
- **eligible**: Size-adjusted 130% FPL threshold from hefaminc × hrnumhou

## Software
- Stata
- Required packages: estout (ssc install estout)

## Files
- `snap-food-security-analysis.do` — Full analysis do-file (data cleaning, variable construction, all models)
