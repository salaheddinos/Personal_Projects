# In this project we're going to analyze a database of summer and winter olympics
# We'll practice querying data using SQL server syntax
--Query the sport and distinct numbers of athletes
SELECT 
    sport,
    COUNT(DISTINCT athlete_id) AS num_of_athletes
FROM my-first-project-314408.olympics.summer_games
GROUP BY sport
ORDER BY num_of_athletes DESC;

--Pull report that shows each sport, the num of unique events and the num of unique athletes 
SELECT 
    sport, 
    COUNT(DISTINCT event) AS num_of_events, 
    COUNT(DISTINCT athlete_id) AS num_of_athletes
FROM my-first-project-314408.olympics.summer_games
GROUP BY sport
ORDER BY num_of_events DESC, num_of_athletes DESC;

--Pull a report that shows the age of the oldest athlete by region

SELECT  
    region, 
    MAX(age) AS oldest
FROM my-first-project-314408.olympics.athletes a
JOIN my-first-project-314408.olympics.summer_games s --Join athletes table to summer_games
ON a.id = s.athlete_id
JOIN my-first-project-314408.olympics.countries c --Join to countries 
ON s.country_id = c.id
GROUP BY region
ORDER BY oldest DESC;

--Check nulls of medals in summer_games
SELECT DISTINCT medal, COUNT(*)
FROM my-first-project-314408.olympics.summer_games
GROUP BY medal;

--Show bronze_medals for summer_games by country
SELECT 
    country,
    COUNT(*) AS num
FROM my-first-project-314408.olympics.summer_games s 
JOIN my-first-project-314408.olympics.countries c --join to countries
ON s.country_id = c.id
WHERE medal = "Bronze"
GROUP BY country
ORDER BY num DESC;

--Validating query
SELECT 
    SUM(num)
FROM (
SELECT 
    country,
    COUNT(*) AS num
FROM my-first-project-314408.olympics.summer_games s 
JOIN my-first-project-314408.olympics.countries c --join to countries
ON s.country_id = c.id
WHERE medal = "Bronze"
GROUP BY country
ORDER BY num DESC
) bronze ;

--Pull athlete_name and gold_medals for summer games
SELECT 
    name,
    COUNT(*) AS num
FROM my-first-project-314408.olympics.athletes a
JOIN my-first-project-314408.olympics.summer_games s --Join to summer_games to get medals
ON a.id = s.athlete_id
WHERE medal = "Gold"
GROUP BY name 
HAVING num >= 3 --Filter for only athletes with 3 or more gold medals
ORDER BY num DESC;

--Setup a query that shows unique events by country and season for summer games
SELECT 
    "summer" AS season,
    country,
    COUNT(DISTINCT event) AS num_of_events
FROM my-first-project-314408.olympics.summer_games s
JOIN my-first-project-314408.olympics.countries c --Join to countries to get country name
ON s.country_id = c.id 
GROUP BY season, country

--Combine the above query with same query but this time for winter_games
UNION ALL  
SELECT 
    "winter" AS season,
    country,
    COUNT(DISTINCT event) AS num_of_events
FROM my-first-project-314408.olympics.winter_games w
JOIN my-first-project-314408.olympics.countries c --Join to countries to get country name
ON w.country_id = c.id 
GROUP BY season, country
ORDER BY num_of_events DESC;

--Achieve the same result as above by using Union then Join
SELECT season, country, COUNT(DISTINCT event) AS num_of_unique_events

FROM 
    (SELECT 
    "summer" AS season,
    country_id,
    event
FROM my-first-project-314408.olympics.summer_games 
--Combine the above query with same query but this time for winter_games
UNION ALL  
SELECT 
    "winter" AS season,
    country_id,
    event
FROM my-first-project-314408.olympics.winter_games w
) subquery
JOIN my-first-project-314408.olympics.countries c
ON subquery.country_id = c.id
GROUP BY season, country
ORDER BY num_of_unique_events DESC; 

--Using CASE statement : Output "Tall Females" & "Tall Males" & "Other"
SELECT
    name,
    CASE
        WHEN gender = 'F' AND height >= 175 THEN "Tall Female"
        WHEN gender = 'M' AND height >= 190 THEN "Tall Male"
        ELSE "Other" END AS segment 
FROM my-first-project-314408.olympics.athletes;

--Outputs BMI by each sport for summer games and count unique num of athletes 
SELECT 
    sport,
    CASE 
        WHEN (100*weight) / POWER(height, 2) < 0.25 THEN "<.25"
        WHEN (100*weight) / POWER(height, 2) BETWEEN 0.25 AND 0.30 THEN ".25 - .30"
        WHEN (100*weight) / POWER(height, 2) > 0.30 THEN "<.30"
        END AS BMI,
    COUNT(DISTINCT athlete_id) AS num_of_athletes
FROM my-first-project-314408.olympics.summer_games s
JOIN my-first-project-314408.olympics.athletes a
ON s.athlete_id = a.id
GROUP BY sport, BMI
ORDER BY sport, num_of_athletes DESC;

--Checking for nulls of above query
SELECT 
    height,
    weight,
    CASE 
        WHEN (100*weight) / POWER(height, 2) < 0.25 THEN "<.25"
        WHEN (100*weight) / POWER(height, 2) BETWEEN 0.25 AND 0.30 THEN ".25 - .30"
        WHEN (100*weight) / POWER(height, 2) > 0.30 THEN "<.30"
        END AS BMI
FROM my-first-project-314408.olympics.summer_games s
JOIN my-first-project-314408.olympics.athletes a
ON s.athlete_id = a.id
WHERE weight IS NULL
OR height IS NULL;

--The reason for nulls in BMI is that we have missing values in either height or weight
--We'll fix this issue by setting an ELSE statement 
SELECT 
    sport,
    CASE 
        WHEN (100*weight) / POWER(height, 2) < 0.25 THEN "<.25"
        WHEN (100*weight) / POWER(height, 2) BETWEEN 0.25 AND 0.30 THEN ".25 - .30"
        WHEN (100*weight) / POWER(height, 2) > 0.30 THEN "<.30"
        ELSE "no weight recorded"
        END AS BMI,
    COUNT(DISTINCT athlete_id) AS num_of_athletes
FROM my-first-project-314408.olympics.summer_games s
JOIN my-first-project-314408.olympics.athletes a
ON s.athlete_id = a.id
GROUP BY sport, BMI
ORDER BY sport, num_of_athletes DESC;

--Query total medals earned for summer games and filter for only age 16 or under
-- First join athletes table to summer_games to get the total number of athletes that participated in summer_games with their ages
SELECT
    medal,
    COUNT(medal) AS num_of_medals_earned
FROM my-first-project-314408.olympics.athletes a
JOIN my-first-project-314408.olympics.summer_games s
ON s.athlete_id = a.id
WHERE age <= 16
AND medal IS NOT NULL
GROUP BY medal; 

--Get same result but by using subquery
SELECT
    medal,
    COUNT(medal) AS num_of_medals_earned_by_16_and_under
FROM 
    (SELECT 
        age,
        medal
    FROM my-first-project-314408.olympics.athletes a
    JOIN my-first-project-314408.olympics.summer_games s
    ON s.athlete_id = a.id 
    WHERE age <= 16
    AND medal IS NOT NULL) subquery
GROUP BY medal;

-- Top athletes in nobel-prized countries
--Include both athletes from summer and winter games
SELECT 
    event,
    gender,
    COUNT(DISTINCT athlete_id) AS num_of_athletes
FROM (
SELECT 
    event,
    gender,
    athlete_id
FROM my-first-project-314408.olympics.athletes a
JOIN my-first-project-314408.olympics.summer_games s 
ON a.id = s.athlete_id 
JOIN my-first-project-314408.olympics.country_stats cs
ON s.country_id = cs.country_id
WHERE nobel_prize_winners IS NOT NULL
UNION ALL 
SELECT
    event,
    gender,
    athlete_id
FROM my-first-project-314408.olympics.athletes a 
JOIN my-first-project-314408.olympics.winter_games w
ON a.id = w.athlete_id
JOIN my-first-project-314408.olympics.country_stats cs
ON w.country_id = cs.country_id
WHERE nobel_prize_winners IS NOT NULL) subquery 
GROUP BY event, gender
ORDER BY num_of_athletes DESC
LIMIT 10;
