SELECT *
FROM Portfolio_Covid..CovidDeaths
ORDER BY 3,4

SELECT *
FROM Portfolio_Covid..CovidVaccinations
ORDER BY 3,4

--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM Portfolio_Covid..CovidDeaths
--ORDER BY 1,2

-- Looking at total cases vs total deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM Portfolio_Covid..CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS case_percentage
FROM Portfolio_Covid..CovidDeaths
WHERE location = 'Germany'
ORDER BY 1,2

-- Looking at countries with highest infection rates compared to population
SELECT location, MAX(total_cases) AS max_cases, population, MAX((total_cases/population))*100 AS percentage_infected
FROM Portfolio_Covid..CovidDeaths
--WHERE location = 'France'
GROUP BY location, population
ORDER BY 4 DESC

-- Looking at countries with highest death rates compared to population
SELECT location, MAX(CAST(total_deaths AS int)) AS max_deaths, population, MAX((CAST(total_deaths AS int)/population))*100 AS percentage_died
FROM Portfolio_Covid..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY 4 DESC

-- Countries with most deaths
SELECT location, MAX(CAST(total_deaths AS int)) AS all_deaths
FROM Portfolio_Covid..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY all_deaths DESC

--STATS BY CONTINENT
-- Total deaths by continent
WITH country_deaths AS
(
SELECT location, continent, MAX(CAST(total_deaths AS int)) AS all_deaths
FROM Portfolio_Covid..CovidDeaths
WHERE continent is not NULL
GROUP BY location, continent
)
SELECT continent, SUM(all_deaths) AS all_deaths_by_continent
FROM country_deaths
GROUP BY continent
ORDER BY all_deaths_by_continent DESC

--Total deaths by all parent groups (continents, income,...)
SELECT location, MAX(CAST(total_deaths AS int)) AS all_deaths
FROM Portfolio_Covid..CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY all_deaths DESC

--GLOBAL STATS
--shows growth of global deaths and infections by date
SELECT date, SUM(total_cases) AS all_cases, SUM(CAST(total_deaths AS int)) AS all_deaths, SUM(CAST(total_deaths AS int))/SUM(total_cases)*100 AS percentage_deaths
FROM Portfolio_Covid..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY date

--shows global cases and deaths overall
SELECT SUM(total_cases) AS total_cases, SUM(CAST(total_deaths AS int)) AS total_deaths, SUM(CAST(total_deaths AS int))/SUM(total_cases)*100 AS percentage_deaths
FROM Portfolio_Covid..CovidDeaths
WHERE continent is not NULL

--shows number of new cases by date
SELECT date, SUM(new_cases) AS all_new_cases, SUM(CAST(new_deaths AS int)) AS all_new_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS percentage_new_deaths
FROM Portfolio_Covid..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY date

--VACCINATIONS (WITH CTE)
WITH PopVsVac AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CAST(cv.new_vaccinations AS bigint)) 
		OVER(
			PARTITION BY cd.location 
			ORDER BY cd.location, cd.date
			) AS rolling_vac_count
FROM Portfolio_Covid..CovidDeaths AS cd
JOIN Portfolio_Covid..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent is not NULL
--ORDER BY cd.location, cd.date
)
SELECT *, (rolling_vac_count/population)*100 AS rolling_percent_vac
FROM PopVsVac


--SAME QUERY WITH TEMP TABLE
DROP table if exists #PercentPopulationVaccinated
CREATE table #PercentPopulationVaccinated
(
continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
rolling_vac_count numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations AS bigint)) 
	OVER(
		Partition BY cd.location 
		ORDER BY cd.location, cd.date
	) AS rolling_vac_count
FROM Portfolio_Covid..CovidDeaths AS cd
JOIN Portfolio_Covid..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent is not NULL
--ORDER BY cd.location, cd.date
SELECT *, (rolling_vac_count/population)*100 AS rolling_percent_vac
FROM #PercentPopulationVaccinated

--Creating view to store data for later visualisations
CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations AS bigint)) 
	OVER(
		Partition BY cd.location 
		ORDER BY cd.location, cd.date
	) AS rolling_vac_count
FROM Portfolio_Covid..CovidDeaths AS cd
JOIN Portfolio_Covid..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent is not NULL
