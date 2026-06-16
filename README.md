# Carpooling and Commuting: Evidence from the American Time Use Survey

**José Ignacio Giménez-Nadal**  
University of Zaragoza · IEDIS

---

## Repository structure

```
CarPooling/
├── dofiles/
│   ├── 00_master.do                      # Master script: runs full pipeline
│   ├── 02_atus_cleaning.do               # ATUS data cleaning
│   ├── 03_analysis_atus.do               # Main descriptive and regression analysis
│   ├── 04_comparison.do                  # Comparative analysis
│   ├── 05_intensive_margin_analysis.do   # Intensive margin analysis
│   ├── 06_happiness.do                   # Well-being analysis
│   └── atus_f.do                         # ATUS auxiliary file
├── Results/                              # Output tables (txt, xls, xlsx)
└── Data/                                 # Raw and processed data (private; not tracked)
```

## Data

The analysis uses the [American Time Use Survey (ATUS)](https://www.bls.gov/tus/), accessed via [IPUMS ATUS](https://www.atusdata.org). Data are not included in this repository. Researchers can download the extract directly from IPUMS.

## Reproducing the results

1. Download the ATUS extract and place the files in `Data/`.
2. Run `dofiles/00_master.do` in Stata to execute the full pipeline.

## Software

- **Stata** ≥ 16

## Contact

José Ignacio Giménez-Nadal — [ngimenez@unizar.es](mailto:ngimenez@unizar.es)  
Department of Economic Analysis, University of Zaragoza  
Gran Vía 2, 50005 Zaragoza, Spain
