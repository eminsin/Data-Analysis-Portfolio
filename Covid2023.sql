

/*******************************************************************************************************************

Covid-19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

********************************************************************************************************************/



-- Data import check

SELECT COUNT(*)
FROM PortfolioProject..CovidDeaths

SELECT COUNT(*)
FROM PortfolioProject..CovidVaccinations

SELECT TOP 1000 *
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3, 4

SELECT TOP 1000 *
FROM PortfolioProject..CovidVaccinations
WHERE continent is NOT NULL
ORDER BY 3, 4



-- Data Selection to Start with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1, 2



ALTER TABLE PortfolioProject..CovidDeaths 
ALTER COLUMN total_cases numeric
ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN new_cases numeric 
ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_deaths numeric
ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN population numeric
ALTER TABLE PortfolioProject..CovidVaccinations
ALTER COLUMN new_vaccinations numeric



-- Data Tracking Analysis by Country: 
		-- First data was tracked on 22 January 2020, 1128 days old as of 22 February 2023, in China, Macao, Taiwan, S.Korea, and Japan.
		-- It was also recorded at the same date in the USA.
		-- Tuvalu recorded the least data with 276 days.
		-- North Korea stands out as the country that recorded the least data (285 days) in relation to its population (26 million).

SELECT location, population, COUNT(date) AS DataTrackingDays
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
      AND total_cases is NOT NULL
GROUP BY location, population
ORDER BY 3 DESC, 2 ASC
--ORDER BY 2 DESC, 3 ASC



-- Comparison of the Likelihood of Dying if Contracted the Disease
		-- In countries such as China and Germany, where the measures are strictly enforced, the rate struggled to exceed 5 percent, 
		-- while in Sweden, which decided to apply the measures in a more liberal manner, the rate sometimes exceeded 10 percent. 
		-- Currently, this rate is in a continuous downward trend and below 1 percent in Germany (~0.4%) and Sweden (~0.8%).
		-- However, a high rate of increase (from ~0.26% to ~4.0%) has been observed in China for the last 1 month.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathsPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
      AND location IN ('Germany', 'Sweden', 'China')
--      OR location LIKE '%States%'
ORDER BY 1, 2



-- Prevalence of the Disease in the Populations by Time

SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectedPopulationPercent
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
--    AND location = 'Germany'
ORDER BY 1, 2



-- Countries with Highest Infection Rate as of 22 Feb 2023 :
		-- Cyprus has the highest rate, with more than 72 percent of its population infected.
		-- Yemen has the lowest with 0.035 percent.

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS InfectedPopulationPercent
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
      AND total_cases is NOT NULL
	  AND population is NOT NULL
--	  AND location = 'Germany'
GROUP BY location, population
ORDER BY InfectedPopulationPercent DESC



-- Countries with Highest Death Count :
		-- While America tops the list with 1.118.719 deaths, 
		-- Nauru,a tiny island country in Micronesia, northeast of Australia, has the fewest Covid deaths with only 1 death.  

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
--    AND location is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



-- Total Deaths by Continent : 
		-- A total of 6.865.972 people have died from Covid worldwide, with more than 2 million deaths occurring in Europe. 
		-- The least number of deaths occurred in Oceania continent with nearly 25.000 deaths.
		-- More than 1.2M of the more than 2M deaths (~60%) in Europe occurred within the European Union.

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
      AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC



-- Mortality Rate by Continent :
		-- Besides the fact that the highest number of deaths occurred in Europe, the continent with the highest mortality rate was South America with 0.31%. 
		-- Although the disease first appeared in China, an Asian country, and about 60% of the world's population lives in Asia, the mortality rate in Asia relative to the population is 0.034%, 1 in 10 of South America.

SELECT location, population, (MAX(total_deaths)/population)*100 AS TotalDeathPercent
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
      AND location NOT LIKE '%income%'
GROUP BY location, population
ORDER BY TotalDeathPercent DESC



-- Global Numbers :
		-- Approximately 674.5M people in the world have contracted Covid.  1 percent of these resulted in death.

SELECT location, population, MAX(total_cases) AS TotalCases,
                             MAX(total_deaths) AS TotalDeaths, (MAX(total_deaths)/MAX(total_cases))*100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
      AND location = 'World'
GROUP BY location, population



-- Numbers by Income Level
		-- The mortality rate in low-income countries (~2.1%) is 3 times higher than the mortality rate in high-income countries (~0.67%). 
		-- However, this does NOT mean that mortality rate is inversely proportional to income level, because 
		-- it has been observed that the mortality rate of the upper-middle class (~1.8%) is higher than that of the lower-middle (~1.4%).

SELECT location, population, MAX(total_cases) AS TotalCases,
                             MAX(total_deaths) AS TotalDeaths, (MAX(total_deaths)/MAX(total_cases))*100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
      AND location LIKE '%income%'
GROUP BY location, population
ORDER BY DeathPercent DESC



-- Number of People that has received at least one Covid Vaccine by Country

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
       SUM(new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths death
JOIN PortfolioProject..CovidVaccinations vac
ON death.location = vac.location 
AND death.date = vac.date
WHERE death.continent is NOT NULL
--    AND death.location = 'Germany'
ORDER BY 2,3



-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
       SUM(new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths death
JOIN PortfolioProject..CovidVaccinations vac
ON death.location = vac.location 
AND death.date = vac.date
WHERE death.continent is NOT NULL
--    AND death.location = 'Germany'
)

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentPopulationVaccinated
FROM PopvsVac



-- Using #Temp_Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #Temp_Table
CREATE TABLE #Temp_Table
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #Temp_Table
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
       SUM(new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths death
JOIN PortfolioProject..CovidVaccinations vac
ON death.location = vac.location 
AND death.date = vac.date
WHERE death.continent is NOT NULL
--    AND death.location = 'Germany'

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM #Temp_Table



-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated
AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
       SUM(new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths death
JOIN PortfolioProject..CovidVaccinations vac
ON death.location = vac.location 
AND death.date = vac.date
WHERE death.continent is NOT NULL
--    AND death.location = 'Germany'


