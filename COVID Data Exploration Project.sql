CREATE DATABASE project1;

USE project1;

CREATE TABLE covid_deaths
(
iso_code varchar(255),
continent varchar(255),
location varchar(255),
dte date,
population bigint,
total_cases int,
new_cases int,
new_cases_smoothed int,
total_deaths int,
new_deaths int,
new_deaths_smoothed float,
total_cases_per_million float,
new_cases_per_million float,
new_cases_smoothed_per_million float,
total_deaths_per_million float,
new_deaths_per_million float,
new_deaths_smoothed_per_million float,
reproduction_rate float,
icu_patients int,
icu_patients_per_million float,
hosp_patients int,
hosp_patients_per_million float,
weekly_icu_admissions int,
weekly_icu_admissions_per_million float,
weekly_hosp_admissions int,
weekly_hosp_admissions_per_million float
);

CREATE TABLE covid_vaccinations 
(
 iso_code varchar(255),
 continent varchar(255),
 location varchar(255),
 dte date,
 total_tests int,
 total_tests_per_thousand float,
 new_tests_per_thousand float,
 new_tests_smoothed int,
 new_tests_smoothed_per_thousand float,
 positive_rate float,
 tests_per_case float,
 test_units varchar(255),
 total_vaccinations int,
 people_vaccinated int,
 people_fully_vaccinated int,
 total_boosters int,
 new_vaccinations int,
 new_vaccinations_smoothed int,
 total_vaccinations_per_hundred float,
 people_vaccinated_per_hundred float,
 people_fully_vaccinated_per_hundred float,
 total_boosters_per_hundred float,
 new_vaccinations_smoothed_per_million int,
 new_people_vaccinated_smoothed int,
 new_people_vaccinated_smoothed_per_hundred float,
 stringency_index float,
 population_density float,
 median_age float,
 aged_65_older float,
 aged_70_older float,
 gdp_per_capita float,
 extreme_poverty float,
 cardiovasc_death_rate float,
 diabetes_prevalence float,
 female_smokers float,
 male_smokers float,
 handwashing_facilities float,
 hospital_beds_per_thousand float,
 life_expectancy float,
 human_development_index float,
 excess_mortality_cumulative_absolute float,
 excess_mortality_cumulative float,
 excess_mortality float,
 exess_mortality_cumulative_per_million float
 );

LOAD DATA LOCAL INFILE '/Users/nicholas/Desktop/MySQL/covid_deaths.csv' INTO TABLE project1.covid_deaths FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE '/Users/nicholas/Desktop/MySQL/covid_vaccinations.csv' INTO TABLE project1.covid_vaccinations FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

SELECT * FROM project1.covid_deaths WHERE location LIKE '%income%' AND continent != '';

SELECT location, dte, total_cases, new_cases, total_deaths, population
FROM project1.covid_deaths
ORDER BY 1,2;

 -- Looking at Total Cases vs Total deaths in Singapore
SELECT location, dte, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM project1.covid_deaths
WHERE location='Singapore'
ORDER  BY 1,2;

 -- Looking at Total Cases vs Population in US
  -- Shows what percentage of population got Covid
SELECT location, dte, population, total_cases, (total_cases/population)*100 as covid_rate
FROM project1.covid_deaths
WHERE location like '%states%'
ORDER  BY 1,2;

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) AS PercentPopulationInfected
FROM project1.covid_deaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

 -- Showing countries with highest death count per population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM project1.covid_deaths
WHERE continent != ''
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM project1.covid_deaths
WHERE continent != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;



-- GLOBAL NUMBERS

SELECT dte, SUM(new_cases) as TotalNewCases, SUM(new_deaths) as TotalNewDeaths, (sum(new_deaths)/sum(new_cases))*100 as DeathPercentage
FROM project1.covid_deaths
WHERE continent != ''
AND dte > '2020-01-04'
GROUP BY dte
ORDER BY 1,2;



 -- Have a rolling count of people vaccinated alongside new vaccinations per day
 WITH PopVsVac (continent, location, dte, population, new_vaccinations, RollingPeopleVaccinated)
 AS
 (
SELECT de.continent, de.location, de.dte, de.population, va.new_vaccinations, SUM(va.new_vaccinations) OVER (PARTITION BY de.location ORDER BY de.location, de.dte) as RollingPeopleVaccinated
FROM project1.covid_deaths de
JOIN project1.covid_vaccinations va
	ON de.location = va.location
    AND de.dte = va.dte
WHERE de.continent != ''
AND de.location = 'Singapore'
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVsVac;



-- Creating view to store data for later visualisations
CREATE VIEW PercentPopulationVaccinated AS
SELECT de.continent, de.location, de.dte, de.population, va.new_vaccinations, SUM(va.new_vaccinations) OVER (PARTITION BY de.location ORDER BY de.location, de.dte) as RollingPeopleVaccinated
FROM project1.covid_deaths de
JOIN project1.covid_vaccinations va
	ON de.location = va.location
    AND de.dte = va.dte
WHERE de.continent != '';


SELECT * FROM PercentPopulationVaccinated
