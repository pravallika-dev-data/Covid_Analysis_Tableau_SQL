SELECT * FROM 
[project 110]..[covid deaths]

order by 3,4

SELECT * FROM 
[project 110]..[covid vaccinations]
order by 3,4

SELECT location,date,total_cases,new_cases,total_deaths,population
from [project 110]..[covid deaths] 
order by 1,2

--total cases vs total deaths
SELECT SUM(CAST(total_cases AS BIGINT)) AS SUM_OF_TOTAL_CASES,SUM(CAST(total_deaths AS BIGINT)) AS SUM_OF_TOTAL_DEATHS FROM 
[project 110]..[covid deaths]

SELECT location,date,total_cases,total_deaths,ROUND((CAST(total_deaths AS FLOAT) / (CAST(total_cases AS FLOAT))) * 100 ,2)AS death_percentage
from [project 110]..[covid deaths] 
order by 1,2

SELECT location,date,total_cases,total_deaths,ROUND((CAST(total_deaths AS FLOAT) / (CAST(total_cases AS FLOAT))) * 100 ,2)AS death_percentage
from [project 110]..[covid deaths] 
where location like '%india%'
order by 1,2


--total percentage of people got affected by covid in india
SELECT location,date,population,total_cases,total_deaths,ROUND((CAST(total_cases AS FLOAT) / (CAST(population AS FLOAT))) * 100 ,8)AS case_percentage
from [project 110]..[covid deaths] 
order by 1,2
 
 --highest percentage with the country 
SELECT TOP 1 location AS Country, MAX(case_percentage) AS max_case_percentage
FROM (
    SELECT location, ROUND((CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100, 8) AS case_percentage
    FROM [project 110]..[covid deaths]
) AS calculated_percentages
GROUP BY location
ORDER BY max_case_percentage desc;
--same like above
SELECT top 1 location,population,max(cast(total_cases as int)) as highest,max((cast(total_cases as float)/cast(population as float))*100) as percentage_total
from [project 110]..[covid deaths]
group by location,population
order by percentage_total desc;

--for india
SELECT top 1 location,population,max(cast(total_cases as int)) as highest,max((cast(total_cases as float)/cast(population as float))*100) as percentage_total
from [project 110]..[covid deaths]
where location like '%india%'
group by location,population
order by percentage_total desc;

select  location, max(cast(total_deaths as int)) as highest_deaths from [project 110]..[covid deaths]
where continent is not null
group by location
order by highest_deaths desc

--globally number of cases, deaths and death percentage everyday 
select  sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/(nullif(sum(new_cases),0))*100 as death_percentage
from [project 110]..[covid deaths]
where continent is not null
--group by date 
order by 1,2



select * from [project 110]..[covid vaccinations] vac
join [project 110]..[covid deaths] dea
on vac.date = dea.date and vac.location=dea.location

select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
from [project 110]..[covid deaths] dea
join [project 110]..[covid vaccinations] vac
on vac.date = dea.date and vac.location=dea.location
where dea.continent is not null
order by 2,3

select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date)
from [project 110]..[covid deaths] dea
join [project 110]..[covid vaccinations] vac
on vac.date = dea.date and vac.location=dea.location
where dea.continent is not null
order by 2,3

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS cumulative_vaccinations
FROM
    [project 110]..[covid deaths] dea
JOIN
    [project 110]..[covid vaccinations] vac
ON
    vac.date = dea.date AND vac.location = dea.location
WHERE
    dea.continent IS NOT NULL
ORDER BY
    dea.location,
    dea.date;

--percentage of vacciantions 

WITH popvsvacc (continent, location, date, population, new_vaccinations, cumulative_vaccinations) AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(bigINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS cumulative_vaccinations
    FROM
        [project 110]..[covid deaths] dea
    JOIN
        [project 110]..[covid vaccinations] vac
    ON
        vac.date = dea.date AND vac.location = dea.location
    WHERE
        dea.continent IS NOT NULL
)
select *,cumulative_vaccinations/population *100 as percentage_of_vaccinations from popvsvacc

--maximum vaccinations in each country using CTE(Common Table expression)
SELECT
    distinct location,
    MAX(cumulative_vaccinations) OVER (PARTITION BY location) AS max_cumulative_vaccinations
FROM popvsvacc


--creating temp table
drop table if exists temp_table
CREATE TABLE temp_table(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulative_vaccinations numeric
)



INSERT INTO temp_table
 SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(bigINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS cumulative_vaccinations
    FROM
        [project 110]..[covid deaths] dea
    JOIN
        [project 110]..[covid vaccinations] vac
    ON
        vac.date = dea.date AND vac.location = dea.location

select *,(cumulative_vaccinations/population) *100 as percentage_of_vaccinations 
from temp_table


drop view if exists totalpercentvaccinations
GO
CREATE VIEW
totalpercentvaccinations as
 SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
        SUM(CONVERT(bigINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS cumulative_vaccinations
    FROM
        [project 110]..[covid deaths] dea
    JOIN
        [project 110]..[covid vaccinations] vac
    ON
        vac.date = dea.date AND vac.location = dea.location
    WHERE
        dea.continent IS NOT NULL

select * from totalpercentvaccinations
