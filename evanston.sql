# SQL CODE FOR QUERYING PRACTICE
# DATABASE NAME : EVANSTON

##CODE##

SELECT 
    *
FROM
    evanston.ev
LIMIT 10;


UPDATE evanston.ev 
SET 
    date_created = REPLACE(REPLACE(date_created, 'T', ' '),
        'Z',
        ' ')
WHERE
    id <> 0;

UPDATE evanston.ev 
SET 
    date_completed = REPLACE(REPLACE(date_completed, 'T', ' '),
        'Z',
        ' ')
WHERE
    id <> 0;


UPDATE evanston.ev 
SET 
    date_created = DATE_FORMAT(STR_TO_DATE(date_created, '%Y-%m-%d %H:%i:%s'),
            '%Y-%m-%d %H:%i:%s')
WHERE
    id <> 0;
ALTER TABLE evanston.ev 
      CHANGE date_created date_created TIMESTAMP;
      
UPDATE evanston.ev 
SET 
    date_completed = DATE_FORMAT(STR_TO_DATE(date_completed, '%Y-%m-%d %H:%i:%s'),
            '%Y-%m-%d %H:%i:%s')
WHERE
    id <> 0;
ALTER TABLE evanston.ev 
      CHANGE date_completed date_completed TIMESTAMP;

SELECT 
    *
FROM
    evanston.ev
LIMIT 10;

-- Find values of zip that appear in at least 100 rows and get count for each value
SELECT DISTINCT
    zip, COUNT(*) AS num
FROM
    evanston.ev
GROUP BY zip
ORDER BY num DESC;

-- Find the 5 most common values of street and count of each
SELECT 
    street, COUNT(*) AS num
FROM
    evanston.ev
GROUP BY street
ORDER BY num DESC;

-- Use ILIKE to count rows where desc contains 'garbage'
SELECT 
    COUNT(*) AS num_with_garbage
FROM
    evanston.ev
WHERE
    LOWER(description) LIKE '%garbage%'
        AND LOWER(description) LIKE '%trash%';

-- Count rows where description includes trash and grabage but categ does not
-- I used a CTE but could have also used less complex code such as where and 
WITH 
cte1 AS (
SELECT id, description
	FROM evanston.ev table1
	WHERE LOWER(description) LIKE '%garbage%'
	OR LOWER(description) LIKE '%trash%'),
cte2 AS (
	SELECT id, category
	FROM evanston.ev table2
	WHERE LOWER(category) NOT LIKE '%garbage%'
	AND LOWER(category) NOT LIKE '%trash%')
-- Count rows with each category
SELECT category, COUNT(*) AS num
	FROM cte1
JOIN cte2
	ON cte1.id = cte2.id
GROUP BY category
ORDER BY num DESC;

-- Concatenate house_num, a space ' ' and street into a single value
SELECT 
    LTRIM(CONCAT(house_num, ' ', street)) AS address
FROM
    evanston.ev;
    
-- Select first word in street and count each value
SELECT 
    SUBSTRING_INDEX(street, ' ', 1) AS city, COUNT(*) AS num
FROM
    evanston.ev
GROUP BY city
ORDER BY num DESC;

-- Select first 50 char of description with ... concatenated on the end and where length of desc is > 50 otherwise select description 
SELECT 
    id,
    CASE
        WHEN LENGTH(description) > 50 THEN CONCAT(LEFT(description, 50), '...')
        ELSE description
    END AS shortened
FROM
    evanston.ev
WHERE
    description LIKE 'I%'
ORDER BY description;

-- select zips that have less than 3 charc and name them other
SELECT 
    CASE
        WHEN LENGTH(zip) <= 3 THEN 'Other'
        WHEN zip = 'NA' THEN 'Unknown'
        ELSE zip
    END AS zip_code,
    COUNT(*) AS num
FROM
    evanston.ev
GROUP BY zip_code
ORDER BY num DESC;

-- Encode zip code that appear not very often in dataset (less than 100) as other and count by zip code
SELECT 
    CASE
        WHEN t.freq < 100 THEN 'Other'
        ELSE zip
    END AS zip_code,
    SUM(t.freq) AS zip_freq
FROM
    (SELECT 
        zip, COUNT(zip) AS freq
    FROM
        evanston.ev
    GROUP BY zip
    ORDER BY freq DESC) t
GROUP BY zip_code
ORDER BY zip_freq DESC;

-- Create a temp table whith two cols : categ and standardized categ 
CREATE TEMPORARY TABLE sd_cat
SELECT category, SUBSTRING_INDEX(category, '-', 1) AS standardized
FROM evanston.ev;

-- Update the temp table for standardized specific terms
-- For example, let's say we want to rename all stand categ that contain Trash Cart
UPDATE sd_cat 
SET 
    standardized = 'Trash Cart'
WHERE
    standardized LIKE 'Trash%Cart';

-- Update to group snow removal

UPDATE sd_cat 
SET 
    standardized = 'Snow Removal'
WHERE
    standardized LIKE 'Snow%Removal%';

-- Examine effect of updates
SELECT DISTINCT
    standardized
FROM
    sd_cat
WHERE
    standardized LIKE 'Trash%Cart'
        OR standardized LIKE 'Snow%Removal%';

-- Update temp table where we trim leading and trailing spaces for standardized field
UPDATE sd_cat 
SET 
    standardized = TRIM(standardized);

-- Update table and set all descriptions containing do not use ... To UNUSED

UPDATE sd_cat 
SET 
    standardized = 'UNUSED'
WHERE
    standardized IN ('THIS REQUEST IS INACTIVE...Trash Cart' , '(DO NOT USE) Water Bill',
        'DO NOT USE Trash',
        'NO LONGER IN USE');
-- Check our new modfied table
SELECT DISTINCT
    *
FROM
    sd_cat
ORDER BY standardized;

-- Join evanston and temp table to count the number of requests for each stand values and list most common ones
SELECT 
    standardized, COUNT(*) AS num
FROM
    evanston.ev e
        JOIN
    sd_cat s ON e.category = s.category
GROUP BY standardized
ORDER BY num DESC
LIMIT 1;

-- Determine if medium and high priority requests are more likely to contain phone or emails
-- To achieve this, we need to first create a temp table where we store all dataset's phones and emails and id
-- Then, we need to join the temp table to our original table and see count how many medium and high priority have phone numbers compared to low priority
-- -- SQL pattern matching enables you to use _ to match any single character and % to match an arbitrary number of characters (including zero characters).

CREATE TEMPORARY TABLE contacts
SELECT id, 
		CAST(description LIKE '%@%' AS UNSIGNED) AS email,   
        CAST(description LIKE '%___-___-_____%' AS UNSIGNED) AS phone  -- If it finds matching pattern then CAST function will convert it to 1   
FROM evanston.ev;
-- Check table
SELECT 
    *
FROM
    contacts
LIMIT 5;

-- Now, we can join our temp table to our original table to see how many Medium and High priority requests do have phone and emails
SELECT 
    priority,
    SUM(email) / COUNT(*) AS email_prop,
    SUM(phone) / COUNT(*) AS phone_prop
FROM
    evanston.ev AS e
        LEFT JOIN
    contacts AS c ON e.id = c.id
GROUP BY priority;

-- Count numbers of requests on a specific date
SELECT 
    COUNT(*)
FROM
    evanston.ev
WHERE
    CAST(date_created AS DATE) = '2017-01-31';

-- Number of requests between two dates
SELECT 
    MONTH(date_created) AS month, COUNT(*) AS num
FROM
    evanston.ev
WHERE
    date_created BETWEEN '2016-01-01' AND '2018-01-01'
GROUP BY month
ORDER BY month;

-- What's the most common hour for requests to be created
SELECT 
    HOUR(date_created) AS hour_created, COUNT(*) AS num
FROM
    evanston.ev
GROUP BY hour_created
ORDER BY num DESC
LIMIT 1;

-- During what hours are requests usually completed?Count num of requests completed by hour.
SELECT 
    HOUR(date_completed) AS hour_completed, COUNT(*) AS num
FROM
    evanston.ev
GROUP BY hour_completed
ORDER BY num DESC
LIMIT 1;

-- Select the name of the day of the week the request was created
-- Select the mean time between the request completion and request creation 

-- Find average number of requests created per day for each month of the data
-- Ignore days with no requests when taking avg

# Find longest time gap between requests
SELECT date_created, previous, MAX(TIMEDIFF(date_created, previous)) AS diff
FROM (
SELECT date_created, LAG(date_created, 1,0) OVER(ORDER BY date_created) AS previous
FROM evanston.ev
) t
GROUP BY date_created
ORDER BY diff DESC
LIMIT 1;

-- Find avg completion time by categ
WITH comp_time AS(
	SELECT category, DATEDIFF(date_completed, date_created) AS gap
	FROM evanston.ev
)
SELECT category, AVG(gap) AS avg_gap
	FROM comp_time
	GROUP BY category
ORDER BY avg_gap DESC;

-- Why does Rodents-Rats have a high avg_comp time? 
-- To answer this question, we need to compute the avg comp_time while removing outliers 


WITH percentile AS (
	SELECT category,
	   DATEDIFF(date_completed, date_created) AS gap,
       percent_rank() OVER (ORDER BY DATEDIFF(date_completed, date_created)) AS pct
	FROM evanston.ev
	ORDER BY gap
)
SELECT category, 
	   AVG(gap) AS avg_gap
	FROM percentile
	WHERE pct < 0.95
	GROUP BY category
	ORDER BY avg_gap DESC;

SELECT category,
	   AVG(DATEDIFF(date_completed, date_created)) AS gap
FROM evanston.ev
WHERE (
	percent_rank() OVER (ORDER BY DATEDIFF(date_completed, date_created)) < 0.95	
)  ;


-- Compute monthly counts of requests completed
-- We truncate the date to display only the first day of the month
WITH created AS (
	SELECT DATE_FORMAT(date_created, "%Y-%m-01") AS month_created, 
	   COUNT(*) AS num
	FROM evanston.ev
	WHERE category = 'Rodents- Rats'
	GROUP BY month_created),
completed AS (
	SELECT DATE_FORMAT(date_completed, "%Y-%m-01") AS month_completed, COUNT(*) AS num
	FROM evanston.ev
	WHERE category = 'Rodents- Rats'
	GROUP BY month_completed
)
SELECT month_created AS month_of_request, created.num AS created_count, completed.num AS completed_count
	FROM created
	JOIN completed
ON created.month_created = completed.month_completed;

SELECT 
    *
FROM
    evanston.ev
LIMIT 5;
