
SELECT *
FROM portfolioproject.dbo.coviddeath
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM portfolioproject.dbo.covidvaccination
--ORDER BY 3,4


--Select data taht we are going to be using


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolioproject.dbo.coviddeath
WHERE continent is not null
ORDER BY 1,2

--looking at total cases vs total deaths
--likelihood of dying in States before 23-05-20
SELECT location, date, total_cases, total_deaths, 
		(total_deaths / total_cases)*100 as DeathPercentage 
FROM Portfolioproject.dbo.coviddeath
WHERE location like '%states'
and continent is not null
and date between '2020-01-01' and '2023-05-20'
ORDER BY 2


--looking at total cases vs population
--show what percentage of population got covid in Japan

SELECT location, date, total_cases,  population,
		(total_cases / population)*100 as CasesPercentage 
FROM Portfolioproject.dbo.coviddeath
WHERE location like '%japan%'
and continent is not null
and date between '2020-01-01' and '2023-05-20'
ORDER BY 1, 2

--looking at countries with highest infection rate compared to population

SELECT location, total_cases,  population,
		(total_cases / population)*100 as CasesPercentage 
FROM Portfolioproject.dbo.coviddeath
WHERE date = '2023-05-20'
ORDER BY 4 DESC

--second way

SELECT location, MAX(total_cases) AS infectioncount
,  max(population),
		max((total_cases / population))*100 as infectionrate 
FROM Portfolioproject.dbo.coviddeath
GROUP BY location
ORDER BY 4 DESC

--third way
SELECT location, MAX(total_cases) AS infectioncount
,  population,
		max((total_cases / population))*100 as infectionrate 
FROM Portfolioproject.dbo.coviddeath
GROUP BY location, population
ORDER BY 4 DESC




--showing countries with highest death count per population

SELECT location, MAX(total_deaths) AS deathscount
FROM Portfolioproject.dbo.coviddeath
where continent is not null

GROUP BY location
ORDER BY 2 DESC



--let's break things down by continent
--but seems like not null continent exclude a lot of useful data
SELECT continent, MAX(total_deaths) AS deathscount
FROM Portfolioproject.dbo.coviddeath
where continent is not null
GROUP BY continent
ORDER BY 2 DESC


---alternative way to fix it
--比较正确的版本
SELECT location, MAX(total_deaths) AS deathscount
FROM Portfolioproject.dbo.coviddeath
where location not in ('high income','upper middle income',
	'lower middle income', 'low income')
AND continent is null
GROUP BY location
ORDER BY 2 DESC

--showing continents with the highest death count

SELECT continent, MAX(total_deaths) AS deathscount
FROM Portfolioproject.dbo.coviddeath
--where location not in ('high income','upper middle income',
--	'lower middle income', 'low income')
WHERE continent is not null
GROUP BY continent
ORDER BY 2 DESC


-- GLOBAL NUMBERS
--total cases and death per day
SELECT date, SUM(new_cases) as totalcases
, SUM(new_deaths) as totaldeath,
	SUM(new_deaths)/SUM(new_cases)*100 as deathpercentage
FROM portfolioproject.dbo.Coviddeath
WHERE continent is not null
AND new_cases <> 0
GROUP BY date
ORDER BY 1,2

--till now death rate
--pretty accurate compared to WHO covid DATA
SELECT SUM(new_cases) as totalcases
, SUM(new_deaths) as totaldeath,
	SUM(new_deaths)/SUM(new_cases)*100 as deathpercentage
FROM portfolioproject.dbo.Coviddeath
WHERE continent is not null
AND new_cases <> 0
ORDER BY 1,2

---looking at total population vs vaccinations
--在用partition by做出叠加效果后，想把这一列除以总人口得出不同
--时间段的疫苗注射率，直接用alias除以100不行，用cte或者temp

SELECT dea.continent, dea.location, dea.date,
	dea.population, vac.new_vaccinations,
	SUM(VAC.new_vaccinations) over (partition by dea.location
		ORDER BY DEA.LOCATION, dea.date) as RollingPeopleVaccinated
		--this order by accumulate  (rolling up)
					
FROM Coviddeath DEA
JOIN covidvaccination VAC
	ON DEA.location = VAC.location
	and DEA.date = VAC.date
WHERE DEA.continent is not null
ORDER BY 2,3


--use cte
WITH PopvsVAC (continent, location, date, population,
	new_vaccinations, rollingpeoplevaccinated)
as
(
SELECT dea.continent, dea.location, dea.date,
	dea.population, vac.new_vaccinations,
	SUM(VAC.new_vaccinations) over (partition by dea.location
		ORDER BY DEA.LOCATION, dea.date) as RollingPeopleVaccinated
		--this order by accumulate  (rolling up)
		--,(rollingpeoplevaccinated/population)*100
FROM Coviddeath DEA
JOIN covidvaccination VAC
	ON DEA.location = VAC.location
	and DEA.date = VAC.date
WHERE DEA.continent is not null
--ORDER BY 2,3
)

SELECT *,(rollingpeoplevaccinated/population)*100
FROM PopvsVAC

--TRY WITH TEMP TABLE
DROP TABLE IF EXISTS #percentpopultionvaccinated
CREATE TABLE #percentpopultionvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)
insert into #percentpopultionvaccinated
SELECT dea.continent, dea.location, dea.date,
	dea.population, vac.new_vaccinations,
	SUM(VAC.new_vaccinations) over (partition by dea.location
		ORDER BY DEA.LOCATION, dea.date) as RollingPeopleVaccinated
		--this order by accumulate  (rolling up)
					
FROM Coviddeath DEA
JOIN covidvaccination VAC
	ON DEA.location = VAC.location
	and DEA.date = VAC.date
WHERE DEA.continent is not null
ORDER BY 2,3

SELECT *,(rollingpeoplevaccinated/population)*100
FROM #percentpopultionvaccinated



--- creating view to store date for later visualizations

create view percentpopultionvaccinated as
SELECT dea.continent, dea.location, dea.date,
	dea.population, vac.new_vaccinations,
	SUM(VAC.new_vaccinations) over (partition by dea.location
		ORDER BY DEA.LOCATION, dea.date) as RollingPeopleVaccinated
FROM Coviddeath DEA
JOIN covidvaccination VAC
	ON DEA.location = VAC.location
	and DEA.date = VAC.date
WHERE DEA.continent is not null
--ORDER BY 2,3


select *
from percentpopultionvaccinated