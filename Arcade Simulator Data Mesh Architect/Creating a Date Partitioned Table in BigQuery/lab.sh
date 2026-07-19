#!/bin/bash

# ==============================================================================
# ANSI Color Codes
# ==============================================================================
BG_BLUE="\033[44m"
TEXT_WHITE="\033[97m"
TEXT_GREEN="\033[92m"
TEXT_YELLOW="\033[93m"
TEXT_CYAN="\033[96m"
TEXT_RED="\033[91m"
RESET="\033[0m"
BOLD="\033[1m"

clear

# ==============================================================================
# ArkadeKey Box Banner
# ==============================================================================
echo -e "${TEXT_CYAN}  ┌───────────────────────────────────────────────┐  ${RESET}"
echo -e "${TEXT_CYAN}  │  ${BOLD}${TEXT_WHITE}Author: Juanndnich              ${RESET}${TEXT_CYAN}│  ${RESET}"
echo -e "${TEXT_CYAN}  │  ${TEXT_WHITE}Date        : July 20, 2026           ${RESET}${TEXT_CYAN}│  ${RESET}"
echo -e "${TEXT_CYAN}  │  ${TEXT_GREEN}Status      : Active & Ready          ${RESET}${TEXT_CYAN}│  ${RESET}"
echo -e "${TEXT_CYAN}  └───────────────────────────────────────────────┘  ${RESET}"
echo -e "${TEXT_YELLOW}${BOLD}  CREDIT & LICENSE:${RESET}"
echo -e "  This script is developed by Juanndnich for personal educational"
echo -e "  purposes, GCP CLI exploration, and automation research."
echo -e "  Usage of this tool is strictly under Open Education Mode."
echo -e "${BG_BLUE}${TEXT_WHITE}=====================================================${RESET}"
echo ""

# ==============================================================================
# Interactive Project ID Validation
# ==============================================================================
echo -e "${TEXT_CYAN}[*] Detecting Project ID from active session...${RESET}"
DETECTED_PROJECT=$(gcloud config get-value project 2>/dev/null)

if [ -z "$DETECTED_PROJECT" ]; then
    echo -e "${TEXT_RED}[!] Project ID could not be detected automatically.${RESET}"
    read -p "    Please enter Project ID manually: " PROJECT_ID
else
    echo -e "${TEXT_GREEN}[✔] Project ID Detected: ${BOLD}$DETECTED_PROJECT${RESET}"
    echo -e "${TEXT_YELLOW}[?] Is the Project ID correct?${RESET}"
    echo -e "    - Press ${BOLD}[ENTER]${RESET} if correct"
    read -p "    - Or type the new Project ID if incorrect: " USER_INPUT
    
    if [ -z "$USER_INPUT" ]; then
        PROJECT_ID=$DETECTED_PROJECT
    else
        PROJECT_ID=$USER_INPUT
    fi
fi

echo ""
echo -e "${TEXT_GREEN}[✔] Using Project ID: ${BOLD}${TEXT_WHITE}$PROJECT_ID${RESET}"
echo -e "${TEXT_CYAN}=====================================================${RESET}"
echo ""

# Task 1: Create Dataset
echo -e "${TEXT_YELLOW}[1/3] Creating BigQuery dataset 'ecommerce'...${RESET}"
bq mk --location=US ecommerce
if [ $? -eq 0 ]; then
    echo -e "${TEXT_GREEN}[✔] Dataset 'ecommerce' created successfully.${RESET}"
else
    echo -e "${TEXT_RED}[X] Failed to create dataset or it already exists.${RESET}"
fi
echo ""

# Task 2: Create partition_by_day table
echo -e "${TEXT_YELLOW}[2/3] Creating partitioned table 'partition_by_day'...${RESET}"
bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`${PROJECT_ID}.ecommerce.partition_by_day\`
PARTITION BY date_formatted
OPTIONS(
  description=\"a table partitioned by date\"
) AS
SELECT DISTINCT
  PARSE_DATE(\"%Y%m%d\", date) AS date_formatted,
  fullvisitorId
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
"
if [ $? -eq 0 ]; then
    echo -e "${TEXT_GREEN}[✔] Table 'partition_by_day' configured successfully.${RESET}"
else
    echo -e "${TEXT_RED}[X] Error occurred while creating partition_by_day.${RESET}"
fi
echo ""

# Task 3: Create days_with_rain table (60-day expiration window)
echo -e "${TEXT_YELLOW}[3/3] Creating expiring partitioned table 'days_with_rain'...${RESET}"
bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`${PROJECT_ID}.ecommerce.days_with_rain\`
PARTITION BY date
OPTIONS (
  partition_expiration_days=60,
  description=\"weather stations with precipitation, partitioned by day\"
) AS
SELECT
  DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS date,
  (SELECT ANY_VALUE(name) FROM \`bigquery-public-data.noaa_gsod.stations\` AS stations
   WHERE stations.usaf = stn) AS station_name,
  prcp
FROM \`bigquery-public-data.noaa_gsod.gsod*\` AS weather
WHERE prcp < 99.9
  AND prcp > 0
  AND _TABLE_SUFFIX >= '2018'
"
if [ $? -eq 0 ]; then
    echo -e "${TEXT_GREEN}[✔] Table 'days_with_rain' configured successfully.${RESET}"
else
    echo -e "${TEXT_RED}[X] Error occurred while creating days_with_rain.${RESET}"
fi

echo ""
echo -e "${BG_BLUE}${TEXT_WHITE}=====================================================${RESET}"
echo -e "${TEXT_GREEN}${BOLD}     EXECUTION COMPLETED! PLEASE CHECK LAB PROGRESS   ${RESET}"
echo -e "${BG_BLUE}${TEXT_WHITE}=====================================================${RESET}"