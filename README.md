# Q10 Traffic Speed Analysis on the M1 Motorway

## Overview

This repository contains the code and data used for my Master's report on **optimising delivery schedules using traffic speed analysis** on the M1 motorway. The project explores traffic patterns by time of day, day of the week, and junction location to help improve logistical efficiency. All data was collected using the **Traffic England API** and analysed using R and Python scripts.

## Files

1. **README.md**  
   Initial commit providing an overview of the repository and its contents.

2. **automate.py**  
   A Python script used to collect traffic data from the Traffic England API and store it in a MySQL database. This script automates data collection at 30-minute intervals using a crontab.

3. **junction_data_export.csv**  
   The full RAW dataset exported from MySQL. It contains traffic speeds at selected M1 junctions from September 3 to 14, 2024.

4. **q10.R**  
   The main R script for data analysis. It includes data cleaning, descriptive statistics, ANOVA tests, and visualisations of traffic patterns.

5. **q10.Rproj**  
   The R project file for this analysis, containing the environment and workspace settings.

## Usage

- **Data Collection**: Use `automate.py` to collect data from the Traffic England API. The script will store the data in a MySQL database.
- **Data Analysis**: Open the `q10.Rproj` file in RStudio and run the `q10.R` script to perform the statistical analysis and generate visualisations.
- **Data Export**: The processed dataset is available in `junction_data_export.csv` for review.
