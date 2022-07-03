select *
from .coviddeaths$

-- select useful column
select location,date,total_cases,new_cases,total_deaths,new_deaths,population
from portfolioproject..coviddeaths$
where location like '%united states%'
order by 1,2

--global numbers
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
from .coviddeaths$
where continent is not null
order by 1,2

--see how death rate varies each day in the whole world
select date,sum(new_cases) as world_cases,sum(cast(new_deaths as int)) as world_deaths,sum(cast(new_deaths as int))/sum(new_cases)*100
as world_deathrate
from portfolioproject..coviddeaths$
group by date
having sum(new_cases) > 0
order by date

-- see how death rate varies among different countries
select location,sum(total_cases) as total_cases,sum(cast(total_deaths as int)) as total_deaths,sum(cast(total_deaths as int))/sum(total_cases)*100
as deathrate
from portfolioproject..coviddeaths$
where continent is not null
group by location
having sum(total_cases) > 0
order by deathrate desc

-- see how death rate varies among different continents
select location,sum(total_cases) as total_cases,sum(cast(total_deaths as int)) as total_deaths,sum(cast(total_deaths as int))/sum(total_cases)*100
as deathrate
from portfolioproject..coviddeaths$
where continent is null
group by location
having max(total_cases) > 0
order by deathrate desc

--Population VS Vaccination each day in the world
select *,sum(convert(bigint,sub.new_vac)) over(order by sub.date) as total_vac,
sum(convert(bigint,sub.new_vac)) over(order by sub.date)/sub.total_pop as vac_rate
from
(select death.date, sum(death.population) as total_pop,sum(cast(vaccine.new_vaccinations as int)) as new_vac
from portfolioproject..coviddeaths$ death
join portfolioproject..covidvaccinations$ vaccine
on death.location = vaccine.location
and death.date = vaccine.date
group by death.date)as sub
--order by sub.date

--total population VS Vaccination 
select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over(partition by dea.location order by dea.location,dea.date) as rollingpeoplevaccinated
from .coviddeaths$ dea
join .covidvaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Population VS Vaccination in each country each day
With PopvsVac (continent,location,date,population,new_vaccinations,rollingpeoplevaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location,
dea.date)as rollingpeoplevaccinated
from portfolioproject..coviddeaths$ dea
join portfolioproject..covidvaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)
select * , (rollingpeoplevaccinated/population)*100 as vaccine_rate
from PopvsVac
order by 2,3

-- temp table
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location,
dea.date)as rollingpeoplevaccinated
from portfolioproject..coviddeaths$ dea
join portfolioproject..covidvaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

select *,(rollingpeoplevaccinated/population)*100
from #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location,
dea.date)as rollingpeoplevaccinated
from portfolioproject..coviddeaths$ dea
join portfolioproject..covidvaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

select *
from PercentPopulationVaccinated
