/*
	Significant Earthquakes Database
  National Centers for Environmental Information
	Source: NOAA's National Centers for Environmental Information 
	Website: https://www.ncei.noaa.gov/
	
	File Name: overview_cleaning_data.bgsql
	
*/

-- Data Overview;
-- Count the total number of entries & columns in the table:
SELECT
  total_entries,
  no_of_columns
FROM
  (SELECT COUNT(*) AS total_entries
   FROM `youtube-factcheck.earthquake_analysis.earthquakes_copy`) AS entries,
  (SELECT COUNT(DISTINCT column_name) AS no_of_columns
   FROM `youtube-factcheck`.earthquake_analysis.INFORMATION_SCHEMA.COLUMNS
   WHERE table_name = "earthquakes_copy") AS columns;

-- The table contains the following columns:
SELECT column_name
FROM
  `youtube-factcheck`.earthquake_analysis.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = "earthquakes_copy";


--  Interested in the geographical entries;
-- Show the first five records:
SELECT id, year, country, state, location_name, latitude,longitude, region_code
FROM
  `youtube-factcheck.earthquake_analysis.earthquakes_copy`
LIMIT 5;


-- Check the time range when earthquakes have been recorded:
SELECT
  MIN(year) AS first_year,
  MAX(year) AS last_year
FROM 
  `youtube-factcheck.earthquake_analysis.earthquakes_copy`;

-- # Feature Engineering and Data Cleaning:
-- ## Cleaning
-- ### Completeness of data
--  Completeness of data is assessed by checking whether the data has has any missing value. The data is defined as complete if it all records(rows) have all the values filled

--  Count the number of missing values in each column in the data:
with ColumnNames as (
  select column_name,
        count(*) as non_missing_entries
  from (
      select cast(id as string) as id,
             flag_tsunami,
             cast(year as string) as year,
             cast(month as string) as month,
             cast(day as string) as day,
             cast(focal_depth as string) as focal_depth,
             cast(eq_primary as string) as eq_primary,
             cast(eq_mag_mw as string) as eq_mag_mw,
             cast(eq_mag_ms as string) as eq_mag_ms,
             cast(eq_mag_mb as string) as eq_mag_mb,
             cast(eq_mag_ml as string) as eq_mag_ml,
             cast(eq_mag_mfa as string) as eq_mag_mfa,
             cast(eq_mag_unk as string) as eq_mag_unk,
             cast(intensity as string) as intensity,
             cast(country as string) as country,
             cast(location_name as string) as location_name,
             cast(latitude as string) as latitude,
             cast(longitude as string) as longitude,
             cast(region_code as string) as region_code
      from `youtube-factcheck.earthquake_analysis.earthquakes_copy`)
      unpivot ( value for column_name in (id, flag_tsunami,year,month,day,focal_depth,eq_primary,eq_mag_mw, eq_mag_ms, eq_mag_mb, eq_mag_ml, eq_mag_mfa,eq_mag_unk, intensity,country, location_name, latitude, longitude, region_code))
      group by column_name
),
id_only as (
  select column_name,non_missing_entries
  from ColumnNames
  where column_name = 'id'
)
select ColumnNames.column_name,
      ColumnNames.non_missing_entries,
      (id_only.non_missing_entries - ColumnNames.non_missing_entries) * 100.0 / id_only.non_missing_entries as percentage_missing
from ColumnNames
cross join id_only;

-- The earthquake table has missing values. Let's see how to deal with the missing values by column:
-- 1. flag_tsunami
-- This column shows whether a tsunami was recorded or not.
-- For all the missing values fill them with "None" to mean No Tsunami was recorded.
UPDATE 
  `youtube-factcheck.earthquake_analysis.earthquakes_copy`
SET flag_tsunami = 'No Tsu'
WHERE flag_tsunami IS NULL;

-- ## Datetime columns:
-- To fill missing values in the 'month' and 'day' columns based on the available 'year' information, consider a reasonable default value or strategy.
-- One common approach is to fill missing 'month' and 'day' values with some default values, such as 01 for month and 01 for day.
-- With  414 month and 568 day missing value, it would be tedious to seek entries for each of this records.

UPDATE `youtube-factcheck.earthquake_analysis.earthquakes_copy`
SET 
  month = IFNULL(month, 1),
  day = IFNULL(day, 1)
WHERE year IS NOT NULL;


-- Fill the earthquake magnitude column with the yearly monthly location specific mean or median magnitude for each specific magnitude type to fill in missing values. This helps maintain the overall distribution of magnitudes for each type.
-- The below SQL query fills the missing values in the earthquake magnitude columns using the mean magnitude for each specific type:


UPDATE `youtube-factcheck.earthquake_analysis.earthquakes_copy`
SET
  eq_primary = IFNULL(eq_primary,
  (
    SELECT
      MAX(eq_primary)
    FROM
      youtube-factcheck.earthquake_analysis.earthquakes_copy
    WHERE
      eq_primary IS NOT NULL AND
      year = earthquakes_copy.year AND
      month = earthquakes_copy.month AND
      location_name = earthquakes_copy.location_name
  )
),
  eq_mag_mw = IFNULL(eq_mag_mw,
  (
    SELECT
      AVG(eq_mag_mw)
    FROM
      youtube-factcheck.earthquake_analysis.earthquakes_copy
    WHERE
      eq_mag_mw IS NOT NULL AND
      year = earthquakes_copy.year AND
      month = earthquakes_copy.month AND
      location_name = earthquakes_copy.location_name
  )
),
  eq_mag_ms = IFNULL(eq_mag_ms,
  (
    SELECT
      AVG(eq_mag_ms)
    FROM
      youtube-factcheck.earthquake_analysis.earthquakes_copy
    WHERE
      eq_mag_ms IS NOT NULL AND
      year = earthquakes_copy.year AND
      month = earthquakes_copy.month AND
      location_name = earthquakes_copy.location_name
  )
),
  eq_mag_mb = IFNULL(eq_mag_mb,
  (
    SELECT
      AVG(eq_mag_mb)
    FROM
      youtube-factcheck.earthquake_analysis.earthquakes_copy
    WHERE
      eq_mag_mb IS NOT NULL AND
      year = earthquakes_copy.year AND
      month = earthquakes_copy.month AND
      location_name = earthquakes_copy.location_name
  )
),
  eq_mag_ml = IFNULL(eq_mag_ml,
  (
    SELECT
      AVG(eq_mag_ml)
    FROM
      youtube-factcheck.earthquake_analysis.earthquakes_copy
    WHERE
      eq_mag_ml IS NOT NULL AND
      year = earthquakes_copy.year AND
      month = earthquakes_copy.month AND
      location_name = earthquakes_copy.location_name
  )
),
  eq_mag_mfa = IFNULL(eq_mag_mfa,
  (
    SELECT
      AVG(eq_mag_mfa)
    FROM
      youtube-factcheck.earthquake_analysis.earthquakes_copy
    WHERE
      eq_mag_mfa IS NOT NULL AND
      year = earthquakes_copy.year AND
      month = earthquakes_copy.month AND
      location_name = earthquakes_copy.location_name
  )
),
  eq_mag_unk = IFNULL(eq_mag_unk,
  (
    SELECT
      AVG(eq_mag_unk)
    FROM
      youtube-factcheck.earthquake_analysis.earthquakes_copy
    WHERE
      eq_mag_unk IS NOT NULL AND
      year = earthquakes_copy.year AND
      month = earthquakes_copy.month AND
      location_name = earthquakes_copy.location_name
  )
)
WHERE
  eq_primary IS NULL OR
  eq_mag_mw IS NULL OR
  eq_mag_ms IS NULL OR
  eq_mag_mb IS NULL OR
  eq_mag_ml IS NULL OR
  eq_mag_mfa IS NULL OR
  eq_mag_unk IS NULL;


-- Location_name
--  There is only one cell missing its location name located New Zealand but has coordinates; latitide: -40.2, longitude: 73. Let's search for the  cordinates in Google Maps and fill missing location name. 
--  The coordinates, on Google map, point a location in the sea within the Cook Strait sea region: 

UPDATE
  `youtube-factcheck.earthquake_analysis.earthquakes_copy`
SET 
  location_name = "Cook Strait"
WHERE longitude = 173 AND latitude = -40.2;


-- For the missing coordinates, we will perform geocoding using the Google Maps API. The following code will fill in the missing longitudes and latitudes:




-- Region code is assigned based on country.
--  Check the country with missing region_code:
SELECT
  country
FROM
  `youtube-factcheck.earthquake_analysis.earthquakes_copy`
WHERE
  region_code is NULL;

-- Netherlands is the country
--  Check region code of Netherlands
SELECT
  region_code
FROM
  `youtube-factcheck.earthquake_analysis.earthquakes_copy`
WHERE
  country = "NETHERLANDS";

-- Netehelands has the code 120.
--  Update the region_code with the same value:
UPDATE
  `youtube-factcheck.earthquake_analysis.earthquakes_copy`
SET
  region_code = 120
WHERE
  country = 'NETHERLANDS' AND region_code IS NULL;



-- The criteria chosen for filling missing values in the "intensity" and "focal_depth" columns are based on common patterns or assumptions associated with earthquake events. Here's an explanation for each criterion:

-- Tsunami Occurrence (flag_tsunami):

-- If a tsunami occurred (flag_tsunami is 'Tsu'), it is common for the intensity to be higher, as tsunamis often result from powerful earthquakes. Therefore, we set the intensity to 5 and the focal depth to 50.
-- Earthquake Magnitude (eq_mag_mw):

-- For earthquakes with a high magnitude (greater than 7.0), there is an expectation of higher intensity and possibly a deeper focal depth. Hence, we set the intensity to 4 and the focal depth to 30 for such cases.
-- Default Values (Else Condition):

-- If the earthquake doesn't meet the above criteria, we use default values. For cases where a tsunami did not occur, and the earthquake magnitude is not particularly high, we set the intensity to 3 and the focal depth to 20.
-- These criteria are general assumptions and may not cover all possible scenarios. Depending on the characteristics of your earthquake dataset and the nature of seismic events you are dealing with, you might need to tailor the criteria accordingly. It's important to analyze and understand the characteristics of your specific dataset to make informed decisions about how to impute missing values.


UPDATE `youtube-factcheck.earthquake_analysis.earthquakes_copy`
SET 
  intensity = CASE
    WHEN flag_tsunami = 'Tsu' THEN 5  -- Set intensity to 5 if Tsunami occurred
    WHEN eq_mag_mw > 7.0 THEN 4       -- Set intensity to 4 for high magnitude earthquakes
    ELSE 3                             -- Set intensity to 3 for other cases
  END,
  
  focal_depth = CASE
    WHEN flag_tsunami = 'Tsu' THEN 50  -- Set focal_depth to 50 if Tsunami occurred
    WHEN eq_mag_mw > 7.0 THEN 30       -- Set focal_depth to 30 for high magnitude earthquakes
    ELSE 20                            -- Set focal_depth to 20 for other cases
  END
WHERE 
  intensity IS NULL OR focal_depth IS NULL;  -- Update only rows with missing values


-- Check Data duplicates:
-- id are the unique identity of each reacord. Count the ids.
SELECT
  id, COUNT(*)
FROM
  `youtube-factcheck.earthquake_analysis.earthquakes_copy`
GROUP BY id
HAVING COUNT(*) > 1;

-- The data has no duplicates.


--  Check Data timeliness:
--  The last recorded event is dated year 2021.
--  From the data documentation, events are only considered relevant if they fall within the period 2000 B.C to present, (i.e -2000 to present or latest date/year recorded).
-- Drop entries with dated before 2000 B.C (-2000)

DELETE FROM `youtube-factcheck.earthquake_analysis.earthquakes_copy`
WHERE year < -2000;

-- Output:
-- This statement removed 1 row from earthquakes_copy.