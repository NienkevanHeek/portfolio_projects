--Check if files were inserted correctly

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

--Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

--Looking at total_cases vs total_deaths
--Death percentages lower later in pandemic, probably because more total_cases detected due to increased testing?

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%States%'
ORDER BY 1, 2

--Looking at total_cases vs total_population
--Shows percentage of population that got COVID-19
SELECT location, date, population, total_cases, (total_cases/population)*100 AS cases_vs_population
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%States%'
ORDER BY 1, 2

--Countries with highest infection rate compared to population
SELECT location, MAX((total_cases/population)*100) AS max_infection_rate_per_country
FROM PortfolioProject..CovidDeaths
GROUP BY location
ORDER BY max_infection_rate_per_country DESC

--Countries with highest infection rate compared to population Alex the analyst
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS percent_population_infected
FROM PortfolioProject..CovidDeaths
GROUP BY population, location
ORDER BY percent_population_infected DESC

--Showing countries with highest death count per population
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

--LET'S BREAK THINGS DOWN BY CONTINENT
--Not perfect!
SELECT continent, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

--Global numbers
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_new_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Check COVID vaccinations table
SELECT *
FROM PortfolioProject..CovidVaccinations

-- JOIN tables, looking at total_population versus vaccination
-- It is not possible to use the just created rolling_vaccinated_people in an new calculation. This is why we need to create a temporary table. 
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(CAST(CV.new_vaccinations AS int)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_vaccinated_people, 
(rolling_vaccinated_people/population)*100
FROM PortfolioProject..CovidDeaths AS CD
JOIN PortfolioProject..CovidVaccinations AS CV
	ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL 
ORDER BY 1, 2, 3

-- USE CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinated_people)
AS
(
	SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(CAST(CV.new_vaccinations AS int)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_vaccinated_people
	FROM PortfolioProject..CovidDeaths AS CD
	JOIN PortfolioProject..CovidVaccinations AS CV
		ON CD.location = CV.location AND CD.date = CV.date
	WHERE CD.continent IS NOT NULL 
	--ORDER BY 1, 2, 3
)

SELECT *, (rolling_vaccinated_people/population)*100 AS percentage_vaccinated_pop
FROM PopvsVac

--TEMP TABLE
--No brackets after INSERT INTO tablename

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinated_people numeric

)

INSERT INTO #PercentPopulationVaccinated	
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(CAST(CV.new_vaccinations AS int)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_vaccinated_people
	FROM PortfolioProject..CovidDeaths AS CD
	JOIN PortfolioProject..CovidVaccinations AS CV
		ON CD.location = CV.location AND CD.date = CV.date
	WHERE CD.continent IS NOT NULL 
	--ORDER BY 1, 2, 3

SELECT *, (rolling_vaccinated_people/population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, SUM(CAST(CV.new_vaccinations AS int)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_vaccinated_people
	FROM PortfolioProject..CovidDeaths AS CD
	JOIN PortfolioProject..CovidVaccinations AS CV
		ON CD.location = CV.location AND CD.date = CV.date
	WHERE CD.continent IS NOT NULL 
	--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated