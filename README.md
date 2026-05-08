# SNAP and Food Security in Tennessee's Low Income Population
Code for SNAP Participation and Food Security in Tennessee, 2019-2023
## Replication Code

**Paper:** The Effect of SNAP on Food Security among Low Income households in Tennessee: 
Evidence from the CPS Food Security Supplement, 2019-2023

## Data
- Source: Current Population Survey Food Security Supplement (CPS-FSS)
- Years: 2019-2023 (December supplements)
- Access: https://www.census.gov/data/datasets/time-series/demo/cps/cps-supp_cps-repwgt/cps-food-security.html
- Files needed: dec19pub.csv, dec20pub.csv, dec21pub.csv, dec22pub.csv, dec23pub.csv

## Sample
- SNAP-eligible households at or below 130% FPL (size-adjusted)
- Non-metro and 8 Tennessee metropolitan areas:
  - 0 Non Metro
  - 16860 Chattanooga TN-GA
  - 17300 Clarksville TN-KY
  - 17420 Cleveland TN
  - 27740 Johnson City TN
  - 28700 Kingsport-Bristol TN-VA
  - 28940 Knoxville TN
  - 32820 Memphis TN-MS-AR
  - 34980 Nashville-Davidson TN
- N = 754 households with valid SNAP and food security indicators

## Key Variables
- **food_secure**: Binary (1=food secure, 0=food insecure) from hrfs12m1
- **food_sec_cat**: 4-category USDA scale (1=High, 2=Marginal, 3=Low, 4=Very Low) from hrfs12md
- **snap**: SNAP participation (1=Yes, 0=No) from hesp1
- **eligible**: Size-adjusted 130% FPL threshold from hefaminc × hrnumhou

## Software
- Stata 15 or later
- Required packages: estout (ssc install estout)

## Files
- `snap-food-security-analysis.do` — Full analysis do-file (data cleaning, variable construction, all models)
- `figure1_conceptual_framework.py` — Python code to reproduce Figure 1 
