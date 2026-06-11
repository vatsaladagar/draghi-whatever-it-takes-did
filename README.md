# Did Draghi's 'Whatever It Takes' Speech Compress Sovereign Spreads?

### Evidence from a Continuous-Treatment Event Study Difference-in-Differences

**Author:** Vatsala Dagar  
**Date:** June 2026  
**Contact:** vatsaladagar@gmail.com

**LinkedIn:** www.linkedin.com/in/vatsaladagar

\---

## Overview

This repository contains the replication code and cleaned data for an event study difference-in-differences analysis of Mario Draghi's 'Whatever It Takes' speech (26 July 2012) and its causal effect on sovereign bond spreads across eleven eurozone member states.

**Research question:** Did Draghi's speech causally compress sovereign spreads, and was the magnitude of compression systematically related to each country's fiscal vulnerability?

**Method:** Continuous-treatment event study DiD, exploiting cross-sectional variation in 2011 debt-to-GDP ratios as treatment intensity, with country and date fixed effects.

**Headline finding:** A coefficient of −0.683 basis points per 1 percentage point increase in debt-to-GDP (significant at 1% level). Italy experienced approximately 46 basis points more compression than Finland - roughly a 7% reduction in borrowing costs from a single verbal commitment, with no bonds purchased.

\---

## Repository Structure

```
├── panel\\\\\\\_stata.csv          # Cleaned estimation dataset (main replication file)
├── debt\\\\\\\_gdp\\\\\\\_final.csv       # Country-level debt-to-GDP ratios (2011 and 2012 vintages)
├── VIXCLS.csv               # VIX index - daily (FRED series VIXCLS)
├── draghi\\\\\\\_analysis.do       # Full Stata replication code (all 10 tests)
└── README.md                # This file
```

\---

## Data Sources

|Variable|Source|Series / Table|Notes|
|-|-|-|-|
|10-year sovereign bond yields|Investing.com|Daily, Apr–Sep 2012|11 eurozone countries|
|German Bund yield (benchmark)|Investing.com|Daily, Apr–Sep 2012|Spread denominator|
|Debt-to-GDP ratio (2011 vintage)|Eurostat|gov\_10dd\_edpt1|Treatment intensity variable|
|Debt-to-GDP ratio (2012 vintage)|Eurostat|gov\_10dd\_edpt1|Robustness check (Test 8)|
|VIX index|FRED|VIXCLS|Daily global risk appetite control|

**Raw bond yield files** (individual country series from Investing.com) are available on request. They are not included in this repository due to the redistribution terms.

\---

## Sample

**Countries (11):** Austria, Belgium, Finland, France, Ireland, Italy, Malta, Netherlands, Portugal, Slovenia, Spain

**Excluded countries and justification:**

* Germany - spread benchmark (spread identically zero)
* Greece - under active PSI debt restructuring; spread dynamics reflect default mechanics
* Cyprus - acute banking crisis with idiosyncratic spread drivers
* Slovakia, Estonia, Luxembourg - insufficient daily bond market data (thin secondary market liquidity)

**Estimation window:** \[−10, +30] trading days around 26 July 2012  
**Full dataset:** April–September 2012 (used for window sensitivity analysis)

\---

## Variables in panel\_stata.csv

|Variable|Description|
|-|-|
|`date`|Trading date (YYYY-MM-DD)|
|`country`|Country name|
|`country\\\\\\\_id`|Numeric country identifier|
|`yield`|10-year sovereign bond yield (%)|
|`bund\\\\\\\_yield`|German Bund yield (%)|
|`spread`|Sovereign spread vs Germany (basis points)|
|`vix`|CBOE Volatility Index (daily)|
|`debt\\\\\\\_gdp\\\\\\\_2011`|2011 general government debt-to-GDP (%) — Eurostat|
|`debt\\\\\\\_gdp\\\\\\\_2012`|2012 general government debt-to-GDP (%) — Eurostat|
|`post`|Dummy = 1 on or after 26 July 2012|
|`event\\\\\\\_time`|Trading days relative to speech date (0 = speech date)|
|`tday`|Sequential trading day counter within country|
|`speech\\\\\\\_tday`|Trading day number corresponding to speech date|
|`date\\\\\\\_id`|Numeric date identifier|

\---

## Software Requirements

**Software:** Stata 17+

**Required packages:**

```stata
ssc install reghdfe
ssc install coefplot
ssc install esttab
```

\---

## Replication Instructions

1. Clone this repository
2. Open `draghi\\\\\\\_analysis.do` in Stata
3. Set your working directory at the top of the do-file:

```stata
   cd "/path/to/your/cloned/repo"
   ```

4. Run `draghi\\\\\\\_analysis.do` — all 10 tests execute in sequence
5. Outputs (tables and figures) are saved to your working directory

\---

## Tests and Outputs

|Test|Description|Output File|
|-|-|-|
|Test 1|Pre-period parallel trends - graphical|fig\_eventstudy\_main.png|
|Test 2|Pre-period parallel trends - joint F-test|Logged in console|
|Test 3|Full event study coefficient plot|fig\_eventstudy\_main.png|
|Test 4|Parsimonious two-period DiD - headline table|table\_main\_DiD.rtf|
|Test 5|Window sensitivity \[−10,+20], \[−10,+30], \[−10,+45]|table\_window\_sensitivity.rtf|
|Test 6|VIX-controlled specification|Logged in console|
|Test 7|Programme vs non-programme heterogeneity|table\_heterogeneity.rtf|
|Test 8|Alternative debt/GDP vintage (2012)|table\_vintage.rtf|
|Test 9|Outlier exclusion (Italy and Slovenia)|table\_outlier.rtf|
|Test 10|Quadratic debt/GDP specification|table\_quadratic.rtf|

\---

## Key Results

|Specification|β (Debt × Post)|SE|Significance|
|-|-|-|-|
|Baseline|−0.683|0.104|\*\*\*|
|VIX controlled|−0.682|0.106|\*\*\*|
|Window \[−10,+20]|−0.540|—|\*\*\*|
|Window \[−10,+45]|−1.014|—|\*\*\*|
|2012 debt vintage|−0.780|—|\*\*\*|
|Excl. Italy \& Slovenia|−0.506|—|\*\*\*|

*Outcome: 10-year sovereign spread vs Germany (bps). Country and date FEs absorbed. Robust SEs.*

\---

## Citation

If you use this code or data, please cite:

> Dagar, V. (2026). \\\\\\\*Did Draghi's 'Whatever It Takes' Speech Compress Sovereign Spreads? Evidence from a Continuous-Treatment Event Study Difference-in-Differences.\\\\\\\* 

\---

## References

Altavilla, C., Giannone, D. and Lenza, M. (2014). The Financial and Macroeconomic Effects of the OMT Announcements. *ECB Working Paper No. 1707.*

De Pooter, M., Martin, R., and Pruitt, S. (2018). The Liquidity Effects of Official Bond Market Intervention. *Journal of Financial and Quantitative Analysis*, 53(1), 243–268.

Draghi, M. (2012). Speech at the Global Investment Conference, London, 26 July 2012. Frankfurt: European Central Bank.

