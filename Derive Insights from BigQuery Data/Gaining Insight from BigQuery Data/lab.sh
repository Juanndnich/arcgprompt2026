#!/bin/bash

# ============================================================
#               Fasttrack Key By Juanndnich
# ============================================================

# Color Definitions (tput)
BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
RESET=$(tput sgr0)

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
CYAN_TEXT=$'\033[0;96m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
RESET_FORMAT=$'\033[0m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}        FASTTRACK KEY - BY JUANNDNICH (GOOGLE CLOUD LAB)          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Fungsi validasi agar tidak bisa kosong jika tidak sengaja ter-enter
prompt_input() {
    local prompt_msg="$1"
    local var_name="$2"
    local input_val=""
    
    while [[ -z "$input_val" ]]; do
        echo -n "${BOLD}${GREEN}${prompt_msg}: ${RESET}"
        read input_val
        if [[ -z "$input_val" ]]; then
            echo "${RED}[!] Input tidak boleh kosong atau tidak sengaja ter-enter. Silakan masukkan ulang!${RESET}"
        fi
    done
    eval "$var_name=\"\$input_val\""
}

# Input Project ID di awal
prompt_input "Please enter your Google Cloud Project ID" PROJECT_ID
echo "${BLUE}[*] Using Project ID: ${PROJECT_ID}${RESET}"
echo ""

# ------------------------------------------------------------
# Task 1 - Total confirmed cases
# ------------------------------------------------------------
echo "${BOLD}${RED}Task 1. Total confirmed cases${RESET}"
prompt_input "Please enter the month (format: MM, e.g., 06)" input_month
prompt_input "Please enter the date (format: DD, e.g., 20)" input_day

year="2020"
input_date="${year}-${input_month}-${input_day}"

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"SELECT sum(cumulative_confirmed) as total_cases_worldwide
 FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
 WHERE date='${input_date}'"

# ------------------------------------------------------------
# Task 2 - Worst affected areas
# ------------------------------------------------------------
echo ""
echo "${BOLD}${RED}Task 2. Worst affected areas${RESET}"
prompt_input "Please enter the death count threshold (e.g., 100)" death_threshold

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"WITH deaths_by_states AS (
    SELECT subregion1_name as state, sum(cumulative_deceased) as death_count
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name='United States of America' 
      AND date='${input_date}' 
      AND subregion1_name IS NOT NULL
    GROUP BY subregion1_name
)
SELECT count(*) as count_of_states
FROM deaths_by_states
WHERE death_count > ${death_threshold}"

# ------------------------------------------------------------
# Task 3 - Identify hotspots
# ------------------------------------------------------------
echo ""
echo "${BOLD}${RED}Task 3. Identify hotspots${RESET}"
prompt_input "Please enter the confirmed case threshold (e.g., 3000)" case_threshold

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"SELECT * FROM (
    SELECT subregion1_name as state, sum(cumulative_confirmed) as total_confirmed_cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_code='US' AND date='${input_date}' AND subregion1_name IS NOT NULL
    GROUP BY subregion1_name
    ORDER BY total_confirmed_cases DESC
)
WHERE total_confirmed_cases > ${case_threshold}"

# ------------------------------------------------------------
# Task 4 - Fatality ratio
# ------------------------------------------------------------
echo ""
echo "${BOLD}${RED}Task 4. Fatality ratio${RESET}"
prompt_input "Please enter the start date (format: YYYY-MM-DD)" start_date
prompt_input "Please enter the end date (format: YYYY-MM-DD)" end_date

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"SELECT sum(cumulative_confirmed) as total_confirmed_cases,
       sum(cumulative_deceased) as total_deaths,
       (sum(cumulative_deceased)/sum(cumulative_confirmed))*100 as case_fatality_ratio
FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
WHERE country_name='Italy' AND date BETWEEN '${start_date}' AND '${end_date}'"

# ------------------------------------------------------------
# Task 5 - Identifying specific day (Updated with exact robust query)
# ------------------------------------------------------------
echo ""
echo "${BOLD}${RED}Task 5. Identifying specific day${RESET}"
prompt_input "Please enter the death threshold (e.g., 10000)" death_threshold_task5

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"SELECT
  DATE(date) AS date
FROM (
  SELECT
    date,
    SUM(cumulative_deceased) AS total_deaths
  FROM
    \`bigquery-public-data.covid19_open_data.covid19_open_data\`
  WHERE
    country_name = 'Italy'
    AND date >= '2020-01-01'
  GROUP BY
    date
)
WHERE
  total_deaths > ${death_threshold_task5}
ORDER BY
  date ASC
LIMIT 1"

# ------------------------------------------------------------
# Task 6 - Finding days with zero net new cases
# ------------------------------------------------------------
echo ""
echo "${BOLD}${RED}Task 6. Finding days with zero net new cases${RESET}"
prompt_input "Please enter the start date (format: YYYY-MM-DD)" start_date_t6
prompt_input "Please enter the end date (format: YYYY-MM-DD)" end_date_t6

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"WITH india_cases_by_date AS (
    SELECT date, SUM(cumulative_confirmed) AS cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name ='India' AND date BETWEEN '${start_date_t6}' AND '${end_date_t6}'
    GROUP BY date
    ORDER BY date ASC
), india_previous_day_comparison AS (
    SELECT date, cases, LAG(cases) OVER(ORDER BY date) AS previous_day, cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases
    FROM india_cases_by_date
)
SELECT count(*)
FROM india_previous_day_comparison
WHERE net_new_cases = 0"

# ------------------------------------------------------------
# Task 7 - Doubling rate
# ------------------------------------------------------------
echo ""
echo "${BOLD}${RED}Task 7. Doubling rate${RESET}"
prompt_input "Please enter the percentage increase threshold (e.g., 10)" percentage_threshold

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"WITH us_cases_by_date AS (
    SELECT date, SUM(cumulative_confirmed) AS cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name='United States of America' AND date BETWEEN '2020-03-22' AND '2020-04-20'
    GROUP BY date
    ORDER BY date ASC
), us_previous_day_comparison AS (
    SELECT date, cases, LAG(cases) OVER(ORDER BY date) AS previous_day,
           cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases,
           (cases - LAG(cases) OVER(ORDER BY date))*100/LAG(cases) OVER(ORDER BY date) AS percentage_increase
    FROM us_cases_by_date
)
SELECT Date, cases AS Confirmed_Cases_On_Day, previous_day AS Confirmed_Cases_Previous_Day, percentage_increase AS Percentage_Increase_In_Cases
FROM us_previous_day_comparison
WHERE percentage_increase > ${percentage_threshold}"

# ------------------------------------------------------------
# Task 8 - Recovery rate
# ------------------------------------------------------------
echo ""
echo "${BOLD}${RED}Task 8. Recovery rate${RESET}"
prompt_input "Please enter the limit (e.g., 10)" limit

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"WITH cases_by_country AS (
  SELECT
    country_name AS country,
    sum(cumulative_confirmed) AS cases,
    sum(cumulative_recovered) AS recovered_cases
  FROM
    bigquery-public-data.covid19_open_data.covid19_open_data
  WHERE
    date = '2020-05-10'
  GROUP BY
    country_name
), recovered_rate AS
(SELECT
  country, cases, recovered_cases,
  (recovered_cases * 100)/cases AS recovery_rate
FROM cases_by_country
)
SELECT country, cases AS confirmed_cases, recovered_cases, recovery_rate
FROM recovered_rate
WHERE cases > 50000
ORDER BY recovery_rate DESC
LIMIT ${limit}"

# ------------------------------------------------------------
# Task 9 - CDGR - Cumulative daily growth rate
# ------------------------------------------------------------
echo ""
echo "${BOLD}${RED}Task 9. CDGR - Cumulative daily growth rate${RESET}"
prompt_input "Please enter the second date (format: YYYY-MM-DD)" second_date

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"WITH france_cases AS (
    SELECT date, SUM(cumulative_confirmed) AS total_cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name='France' AND date IN ('2020-01-24', '${second_date}')
    GROUP BY date
    ORDER BY date
), summary AS (
    SELECT total_cases AS first_day_cases, LEAD(total_cases) OVER(ORDER BY date) AS last_day_cases,
           DATE_DIFF(LEAD(date) OVER(ORDER BY date), date, day) AS days_diff
    FROM france_cases
    LIMIT 1
)
SELECT first_day_cases, last_day_cases, days_diff,
       POWER((last_day_cases/first_day_cases),(1/days_diff))-1 AS cdgr
FROM summary"

# ------------------------------------------------------------
# Task 10 - Create a Looker Studio report
# ------------------------------------------------------------
echo ""
echo "${BOLD}${RED}Task 10. Create a Looker Studio report${RESET}"
prompt_input "Please enter the start date for Looker Studio (format: YYYY-MM-DD)" ls_start_date
prompt_input "Please enter the end date for Looker Studio (format: YYYY-MM-DD)" ls_end_date

bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false \
"SELECT date, SUM(cumulative_confirmed) AS country_cases,
       SUM(cumulative_deceased) AS country_deaths
FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
WHERE date BETWEEN '${ls_start_date}' AND '${ls_end_date}'
  AND country_name='United States of America'
GROUP BY date
ORDER BY date"

# Final message (Branded for Juanndnich)
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}         LAB COMPLETED SUCCESSFULLY BY JUANNDNICH      ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://github.com/juanndnich${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Automation script executed successfully with robust SQL logic!${RESET_FORMAT}"
echo