# Carpooling in Daily Commutes: Patterns and Emotional Experiences

**Lucía Echeverría** · CONICET, Universidad de Mar del Plata  
**José Ignacio Giménez-Nadal** · Universidad de Zaragoza · IEDIS  
**Antonio Gutiérrez-Lythgoe** · Universidad de Zaragoza · IEDIS

---

## Repository structure

```
CarPooling/
├── dofiles/
│   ├── 00_master.do                       # Master script: runs full pipeline (02–06)
│   ├── atus_f.do                          # ATUS auxiliary labels and definitions
│   ├── 02_atus_cleaning.do                # Data cleaning, variable construction, sample selection
│   ├── 03_analysis_atus.do                # Descriptive stats, logit carpooling, OLS well-being,
│   │                                      #   robustness and heterogeneity analyses
│   ├── 04_comparison.do                   # Carpooling rate comparison (ATUS vs ACS)
│   ├── 05_intensive_margin_analysis.do    # Intensive margin: time-share decomposition
│   ├── 06_happiness.do                    # Well-being regressions (OLS happiness and stress)
│   └── 07_mode_choice.do                  # Multinomial logit for commute mode choice (Table A.5)
│                                          #   Note: run separately; not yet in 00_master.do
├── Results/                               # Output tables (see below)
└── Data/                                  # Raw and processed data (private; not tracked)
```

---

## Data

The analysis uses the [American Time Use Survey (ATUS)](https://www.bls.gov/tus/) Well-Being Module for waves **2010, 2012, 2013, and 2021**, accessed via [IPUMS ATUS](https://www.atusdata.org). Data files are not included in this repository. Researchers can download the extract directly from IPUMS and place the files in `Data/`.

The analytical sample covers working-age individuals (21–65) observed on working days with positive commuting time. The final sample comprises **2,390 individuals** and **2,682 commuting episodes**.

---

## Reproducing the results

1. Download the ATUS extract from IPUMS and place the data files in `Data/`.
2. Open Stata and run `dofiles/00_master.do` to execute the full pipeline (steps 02–06).
3. Run `dofiles/07_mode_choice.do` separately to produce the multinomial logit results (Table A.5).

---

## Results files

All output tables are saved in both `.txt` and `.xls` format unless noted otherwise.

### Summary statistics

| File | Paper reference | Content |
|------|----------------|---------|
| `01_SumStats.*` | Table 1, Panel A | Episode-level: transport modes and carpooling shares |
| `02_SumStats.*` | Table 1, Panel A | Episode-level statistics by survey wave (2010–2021) |
| `03_SumStats.*` | Table 1, Panel B | Individual-level: socio-demographic characteristics |
| `04_SumStats.*` | Table 1, Panel B | Individual-level carpooling rates |
| `05_SumStats.*` | Table 2 | Episode-level well-being by carpooling status (mean differences) |
| `A1_SumStats.*` | — | Episode-level auxiliary statistics |
| `A2_SumStats.*` | — | Individual-level auxiliary statistics |
| `sum_stats_publish.xlsx` | Tables 1–2 | Publication-ready summary statistics |

### Main regression results

| File | Paper reference | Content |
|------|----------------|---------|
| `who_US_commuting.*` | Table 3 (raw) | Logit estimates for carpooling probability |
| `Table3_Logit_AME.*` | Table 3 | Average marginal effects: determinants of non-household carpooling |
| `Table4_Logit_AME_interactions.*` | Table 4 | Education × MSA size gradient in carpooling probability |
| `well-being_schappy_z_US_commuting.*` | Table 5 | OLS regressions: experienced happiness (z-score) |
| `well-being_scstress_z_US_commuting.*` | Table 6 | OLS regressions: experienced stress (z-score) |
| `well-being_mnl.*` | Table 5 | OLS happiness: alternative specification |
| `well-being_mnl_stress.*` | Table 6 | OLS stress: alternative specification |

### Appendix tables

| File | Paper reference | Content |
|------|----------------|---------|
| `well-being_oprobit.*` | Table A.1 | Ordered logit: experienced happiness during commuting |
| `well-being_oprobit2.*` | Table A.2 | Ordered logit: experienced stress during commuting |
| `TableA3_Robustness.*` | Table A.3 | Sensitivity checks: pooled carpooling, excl. 2021, car-only sample, trimmed outliers |
| `TableA3_ClusteringRobustness.*` | Section 5.1 | Alternative error clustering (state, state × year) cited in text |
| `TableA4_Heterogeneity.*` | Table A.4 | Interaction effects: gender, children, white-collar occupation |
| `Table_ModeChoice_AME.*` | Table A.5 | Multinomial logit AME: mode choice (overall) |
| `Table_ModeChoice_MSA.*` | Table A.5 | Multinomial logit AME: mode choice by MSA size |

### Publication tables

| File | Content |
|------|---------|
| `publication_Style_tables.xlsx` | Final publication-formatted tables (Tables 1–6 and A.1–A.5) |

---

## Software

- **Stata** ≥ 16  
- Packages: `outreg2`, `margins`

---

## Contact

José Ignacio Giménez-Nadal — [ngimenez@unizar.es](mailto:ngimenez@unizar.es)  
Department of Economic Analysis, University of Zaragoza  
Gran Vía 2, 50005 Zaragoza, Spain
