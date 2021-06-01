# SQL CODE FOR CREATING A TABLEAU DASHBOARD SHOWCASING COVID STATS
# PLEASE CHECK DASHBOARD ON THIS LINK : https://public.tableau.com/app/profile/salah7781/viz/COVID19Dashboard_16213702560800/Dashboard1

##CODE##

-- Convert to date
UPDATE covid.coviddeaths 
SET 
    date = STR_TO_DATE(date, '%m-%d-%Y');
-- Change datatype of column date to date	
ALTER TABLE covid.coviddeaths
	CHANGE date date DATE;

-- Display first rows
SELECT 
    *
FROM
    covid.coviddeaths
ORDER BY date
LIMIT 20;

-- Select Data that we are going to be starting with
SELECT 
    location, date, total_cases, total_deaths, population
FROM
    covid.coviddeaths
WHERE
    continent IS NOT NULL
ORDER BY 1 , 2;

-- Add a column for death rate 
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    population,
    total_deaths / total_cases AS death_rate
FROM
    covid.coviddeaths
WHERE
    continent IS NOT NULL
ORDER BY 1 , 2;

-- Add a column for pct infected
SELECT 
    date,
    location,
    population,
    MAX(total_cases) AS highest_total_cases,
    MAX((total_cases / population) * 100) AS pct_infected
FROM
    covid.coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY date , location , population
ORDER BY pct_infected DESC;

-- Show Countries with deaths rates per million
SELECT 
    location,
    MAX((total_deaths / population) * 1000000) AS highest_total_deaths_per_million
FROM
    covid.coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY location
ORDER BY highest_total_deaths_per_million DESC;

-- Show countries with highest infection rate per million
SELECT 
    location,
    MAX((total_cases / population) * 1000000) AS total_cases_per_million
FROM
    covid.coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY location
ORDER BY total_cases_per_million DESC;

-- Show locations with highest total_deaths
SELECT 
    location, MAX(total_deaths) AS highest_total_deaths
FROM
    covid.coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY location
ORDER BY highest_total_deaths DESC;

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest total_deaths
SELECT 
    location, MAX(total_deaths) AS Total_deaths
FROM
    covid.coviddeaths
WHERE
    continent IS NULL
        AND location NOT IN ('European Union' , 'World', 'International')
GROUP BY location
ORDER BY Total_deaths DESC;


-- Showing contintents/regions with the highest total_deaths_per_million
SELECT 
    continent,
    MAX((total_deaths / population) * 1000000) AS highest_total_deaths_per_million
FROM
    covid.coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY continent
ORDER BY highest_total_deaths_per_million DESC;

-- SHOWING GLOBAL NUMBERS
SELECT 
    date,
    SUM(new_cases) AS daily_cases,
    SUM(new_deaths) AS daily_deaths,
    (SUM(new_deaths) / SUM(new_cases) * 100) AS daily_death_rate
FROM
    covid.coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Worldwide
SELECT 
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    (SUM(new_deaths) / SUM(new_cases) * 100) AS death_rate
FROM
    covid.coviddeaths
WHERE
    continent IS NOT NULL
ORDER BY date;

-- JOIN TO VACCINATION TABLE
-- Show 5 first rows
SELECT 
    *
FROM
    covid.coviddeaths c
        JOIN
    covid.vaccinations v ON c.location = v.location
        AND c.date = v.date
LIMIT 5;

-- Total Population vs Vaccinations
-- Show Percentage of Population that has recieved at least one Covid Vaccine

WITH rolling_vacc AS (
SELECT 
    c.continent AS Continent,
    c.location AS Location, 
    c.date AS Date,
    c.population AS Pop,
    v.new_vaccinations AS new_vacc,
    SUM(v.new_vaccinations) OVER(PARTITION BY c.location ORDER BY c.location, c.date) AS total_running_new_vacc
    
FROM
    covid.coviddeaths c
JOIN covid.vaccinations v
ON c.location = v.location and c.date = v.date
WHERE c.continent IS NOT NULL
)
SELECT *,
		total_running_new_vacc/Pop
FROM rolling_vacc
ORDER BY Location
;

-- Create some views for visualization 
-- Death_rate_per_million_view
CREATE VIEW death_rate_per_million AS
    (SELECT 
        location,
        MAX((total_deaths / population) * 1000000) AS highest_total_deaths_per_million
    FROM
        covid.coviddeaths
    WHERE
        continent IS NOT NULL
    GROUP BY location
    ORDER BY highest_total_deaths_per_million DESC);

-- Highest_infection_rate_per_million
CREATE VIEW Highest_infection_rate_per_million AS
    (SELECT 
        location,
        MAX((total_cases / population) * 1000000) AS total_cases_per_million
    FROM
        covid.coviddeaths
    WHERE
        continent IS NOT NULL
    GROUP BY location
    ORDER BY total_cases_per_million DESC);

-- Worldwide stats
CREATE VIEW Worldwide_stats AS
    (SELECT 
        SUM(new_cases) AS total_cases,
        SUM(new_deaths) AS total_deaths,
        (SUM(new_deaths) / SUM(new_cases) * 100) AS death_rate
    FROM
        covid.coviddeaths
    WHERE
        continent IS NOT NULL
    ORDER BY date);
