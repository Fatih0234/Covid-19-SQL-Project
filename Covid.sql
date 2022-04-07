Select * 
FROM CovidDeaths
order by 3,4

--SELECT * 
--FROM CovidVaccinations
--order by 3,4


-- Total Deaths and Total cases
-- shows how likely somebody that is in USA (in our example) might die
Select location, date, total_cases, total_deaths, round((total_deaths / total_cases) * 100,2) as DeathPercentage
From CovidDeaths
WHERE location = 'United States'
Order By 1,2

-- Shows how many percentage of population got covid in Germany(in our cases)
Select location, date,total_cases, population, round((total_cases / population) * 100,2) as CovidInfectionOverPopulation
From CovidDeaths
WHERE location = 'Germany'
Order By 1,2 

-- Now I am curious about the death percentage over population
-- it seems for Germany currently this percentage is 0.15. 
Select location, date,total_deaths, population, round((total_deaths / population) * 100,2) as DeathsOverPopulation
From CovidDeaths
WHERE location = 'Germany'
Order By 1,2 

-- Let's look at which countries deaths percentage is higher over its population
-- It seems Peru has lost its 0.64 percentage of population. 212k deaths over its 33 million population. 
Select location, date,total_deaths, population, round((total_deaths / population) * 100,2) as DeathsOverPopulation
From CovidDeaths
WHERE date = (SELECT max(date) FROM CovidDeaths)
Order By DeathsOverPopulation desc

-- Shows the countries who have the most percentage rate of getting covid over its population.
-- I have used Where statement in order to get the last date of each row.
-- Of course here we see countries who has low populations stand out but it is still interesting. For example,Almost half of Netherlands' population got covid (45.39)
-- Netherlands have 17 Million population and 7.7M of them got covid. This might be because of Netherland's Health Deparment strategy.
Select location, date,total_cases, population, round((total_cases / population) * 100,2) as CovidInfectionOverPopulation
From CovidDeaths 
WHERE date = (SELECT max(date) FROM CovidDeaths)
Order By CovidInfectionOverPopulation desc

-- THIS could be returned also ;
Select location, population, max(total_cases),  round(max((total_cases / population)) * 100,2) as CovidInfectionOverPopulation
From CovidDeaths 
-- WHERE date = (SELECT max(date) FROM CovidDeaths)
group by location, population
Order By CovidInfectionOverPopulation desc

-- Now, I am curious about daily percentage of increment of new cases and deaths. 
-- This is the increment rate based on previous day. For example, let's say yesterday's new case was 100 and today's is 75. This means -25% percentage of decrease.
-- With this column, actually we can look at the some time intervals which is quite bad and recursive new cases.
Select location, date, new_cases, 
				lag(new_cases) over(order by location,date) as previousDayNewCases,
				((new_cases-lag(new_cases) over(order by location,date))/ nullif(lag(new_cases) over(order by location,date),0)) * 100 as NewCasesIncrement
				-- We have used nullif because of division by zero error instead of an error, we got null value there.
				-- (new_cases-lag(new_cases) over(order by location,date)), with this one I am comparing my yesterday by today.
from CovidDeaths 
WHERE location = 'Germany'

-- Now I am curious that which days of the week have the most newcaseincrement rate (we calcualted in the previous query)
-- What I mean with this that like for example, Is it the case we got more icrement when we get into wednesdays from tuesdays? 
-- or from thursdays to fridays for every week? 
-- With this information, we might take action in those specific days to improve the rule of coronavirus. 

-- For this query, we only need name of the days on top of previous query.
-- With this query, we can detect which day of the week has the most average increment rate. 
-- For example this day for USA is Monday. Monday's average increment rate is 100 for usa. this mean every monday new cases numbers double. It is very high.
-- It quite makes sense actually on sunday people interact more because it is weekend and when it gets tomorrow, they feel sick or not well and tested and got positive result.
-- That's why, as a government actually we might want to take some action on sundays because it is going to improve USA corona virus game. 
--Of course in our data there might be outliers for this reason I will take a look at for median value as well.
with NewCasesIncrement as 
(Select location, date,DATENAME(weekday,date) NameOfDay, new_cases, 
				lag(new_cases) over(order by location,date) as previousDayNewCases, 
				((new_cases-lag(new_cases) over(order by location,date))/ nullif(lag(new_cases) over(order by location,date),0)) * 100 as NewCasesIncrement
from CovidDeaths)
Select location,NameOfDay, Avg(NewCasesIncrement) AvgNewCasesIncrementRate
From NewCasesIncrement 
where location like '%states%'
GROUP BY location,NameOfDay
order by AvgNewCasesIncrementRate desc


 
-- I will create a CTE for this by using previous query in this way. We will have a better reading of the code.
-- --Of course in our data there might be outliers for this reason I will take a look at for median value as well.
-- Unfortunetly, we don't have a aggregate function of median, so it is going to be a bit complicated.
-- Here we are looking at median value of NewCasesIncrement rate because of outliers. 
-- Still we got 30 percent of increase on Mondays for USA and this is still a high number and it is more accurate than before.
with MedianOfDays
as (SELECT  location, NameOfDay,NewCasesIncrement, 
		percentile_cont(0.5) within group(order by NewCasesIncrement) over(partition by  location,NameOfDay) as Median
		-- this query gives me median of newCasesIncrement of the days of each week for each location. 
		-- That was a mouthful explanation but let me give an exampel and it will be more clear.
		-- Now with this, we dont really affected by possible outliers in out dataset. 
FROM (Select location, date,DATENAME(weekday,date) NameOfDay, new_cases, 
				lag(new_cases) over(order by location,date) as previousDayNewCases, 
				((new_cases-lag(new_cases) over(order by location,date))/ nullif(lag(new_cases) over(order by location,date),0)) * 100 as NewCasesIncrement
from CovidDeaths 
)IncrementOfNewCases
)

Select location,NameOfDay,AVG(Median) as Median
From  MedianOfDays
where location ='United States'
group by location,NameOfDay
order by location,Median desc



-- We discovered something here in our dataset, those two are giving the same result but in a bit different thanks to our dataset structure.
-- 1.)
SELECT continent, sum(cast(total_deaths as bigint)) as TotalDeaths
FROM CovidDeaths
where date = (SELECT max(date) FROM CovidDeaths) and continent is not null
group by continent
order by TotalDeaths desc
-- 2.)
SELECT location, max(cast(total_deaths as bigint)) TotalDeaths
FROM CovidDeaths
where continent is null and location NOT LIKE '%income%'
group by location
order by TotalDeaths desc

-- Global Numbers ==> Questions like; How many deaths did we get yesterday or today. 
-- we are adding this 'where continent is not null' where clause because in our dataset we have continent in continent column and 
--  also location column. When it appears on location column, the continent column is null. So in order not to calculate same continent
-- we just add where clause and filter it to just countries in that continent.





Select continent, total_deaths
from CovidDeaths
where location = 'World' 
order by date desc

-- How many new cases and new deaths occur daily basis.
select date, sum(cast(new_deaths as bigint)) as daily_deaths, sum(new_cases) as daily_cases
from CovidDeaths
where continent is not null 
group by date
order by date

-- Let's analyze death percentage ( new_cases / new_deaths)
-- From beginning to june and july of 2020, the percentage rate is quite bad between 5-20 but with the vaccination and strict rule implemented 
-- all around the world, the percentage rate started decreasing. 
select date, sum(cast(new_deaths as bigint)) as daily_deaths, sum(new_cases) as daily_cases,
			sum(cast(new_deaths as bigint))/sum(new_cases) *100 as death_percentage
from CovidDeaths
where continent is not null 
group by date
order by date



-- So far, how many percentage of world population got covid and how many percentage of worl population died? 
-- Througout the days going, we can see improvement on total_deaths / total_cases ratio. It has decreased. 
-- So far 25th june of 2022, we got 1.27 percent of death over total cases. It means 480M total cases and 611K total deaths so far. 
-- It seems until 25 march, 6 percent of world population got covid and 0.07 percent of world population died because of covid.
select date, sum(cast(total_deaths as bigint)) as total_deaths,sum(total_cases) as total_cases,
			sum(cast(total_deaths as bigint)) /sum(total_cases) * 100 as death_percentage,
			sum(cast(total_deaths as bigint))/sum(population) * 100 as Percentage_of_deaths_over_population,
			sum(total_cases) /sum(population) * 100 as percentage_of_cases_over_population
from CovidDeaths
where continent is not null 
group by date
order by date desc


-- Let's now address the question, Which countries hospital care system was more prepared for such a pandemic and 
-- afterwards, let's look at the one wasn't in the begining but adapted the situation very quickly. Let's go !!

-- Let's look at the columns we might be interested in potentially in order to deliver the question described above.
Select location,continent, date, population,icu_patients,hosp_patients,weekly_icu_admissions,weekly_hosp_admissions
from CovidDeaths
order by location,date

-- Let's first look at the icu_patients. icu_patients is all about number covid-19 patients in intensive care units 
-- As we all know, Germany's economy is Social Market Economy meaning that it is not neither socialist nor capitalist market 
-- it kind of stands in the middle of those 2-ideology and a free market with a set of rules by government in order to shape the market. 
-- Anyway, Hospitals are free here in Germany and It seems it deliveres the needs of its own people. Let's see, How many patient have Germany 
-- Hospitals been getting throuout time and let's see How did they manage to get these patients.

--Select location, date,new_cases,total_cases,icu_patients,hosp_patients
--from CovidDeaths
--where location = 'Germany'-- where icu_patients is not null and location = 'Germany'
--order by location,date





-- * percentage of vaccinated over population for every country and find the country whose people more vaccinated than other in terms of percentage.
-- It seems United Arab Emirates is the country where people are 96% vaccinated. 
-- Then south korea comes, it is 86% (they have 50M population and 44 M of them got vaccinated.)
SELECT dea.location,population, people_fully_vaccinated, (people_fully_vaccinated / population) * 100 as PeopleVaccinated
FROM CovidVaccinations vac
Join CovidDeaths dea 
on vac.location = dea.location and vac.date = dea.date
Where dea.continent is not null and dea.date = (select max(date) from CovidDeaths) and 
people_fully_vaccinated is not null 
order by PeopleVaccinated desc

select * from CovidVaccinations

-- Let's now answer the question of In Europe which country mostly vaccinated and which one is least vaccinated compared to its population. 
-- For this, I do want to see these 2 values as separete columns which just indicates the least vaccinated and mostly vaccianted country in Europe.

-- Before doing this, because I am going to use the previous query but will add 2 columns to this, For readibility purposes, I will create Temp Tables.

Drop Table If Exists #PeopleVaccinatedOverPopulation
Create Table #PeopleVaccinatedOverPopulation
(continent nvarchar(250),
location nvarchar(250),
population bigint,
people_full_vaccinated bigint,
PeopleVaccinated float
)

Insert Into #PeopleVaccinatedOverPopulation
SELECT dea.continent , dea.location,population, people_fully_vaccinated, (people_fully_vaccinated / population) * 100 as PeopleVaccinated
FROM CovidVaccinations vac
Join CovidDeaths dea 
on vac.location = dea.location and vac.date = dea.date
Where dea.date = (select max(date) from CovidDeaths) and dea.continent is not null
order by continent

-- Right now, I am a bit more tidy in terms of looking, and this makes sense because we are going to use this temp table a few times as well.
-- Here we get the percentage of that countrie's vaccination rate and also the mostly and least vaccinated country in the specific continent.

Select *,
FIRST_VALUE(location) over(partition by continent order by PeopleVaccinated desc) as MostlyVaccinatedCountry,
LAST_VALUE(location) over(partition by continent order by PeopleVaccinated desc
							range between unbounded preceding and unbounded following) as LeastVaccinatedCountry
from #PeopleVaccinatedOverPopulation
-- where location =  'Turkey'

-- Because in the further development of my queries I am going to use the joint table of vaccinations and deaths,
-- I will create a view for the possible columns I might be using in the future.
Drop View if exists JointDeaVac
Create View JointDeaVac (continent, location, date, population, total_cases,new_cases, total_deaths,new_deaths,reproduction_rate,
total_tests,new_tests,positive_rate,tests_units,total_vaccinations,people_vaccinated,people_fully_vaccinated,total_boosters,new_vaccinations,
stringency_index)
as 
select dea.continent, dea.location, dea.date, population, total_cases,new_cases, total_deaths,new_deaths,reproduction_rate,
total_tests,new_tests,positive_rate,tests_units,total_vaccinations,people_vaccinated,people_fully_vaccinated,total_boosters,new_vaccinations,
stringency_index
from CovidDeaths dea
join CovidVaccinations vac
on vac.location = dea.location and vac.date = dea.date 

-- The question in my mind is that we got stringency_index in our dataset which indicates the strictness of the government in terms of rules.
-- 100 is the government is very strict like most probably it is announced carantine in the country and everything is closed and 0 means 
-- it is normal life. 
-- So the question is like in different type period the goverment of the countries set the rules in order to stop the virus from spreading.
-- Let's look at the average new_cases in those time interval with the stringency_index- basically we want to answer the question
-- does those stringency of government work or not? 
-- In one of the columns, it is going to indicate the time interval from which date to which date that stringency_index lasted. 
-- Of course we want to see what was the current situation in terms of the stringency_index.
-- AVG new_cases in this time interval. 
-- Count of days

-- Here we can see, For Germany, Actually when the average of new_cases increases for that specific stringency_index (we did this with windows function)
-- German government increases the rules and it decreases the numbers but we don't really see super-duper progress over time.
-- Certain numbers of new_cases sticks with Germany. 
-- If we think about for German population, it got fully vaccinated almost 80 percent. So, like this means that vaccination doesn't really 
-- stop the new cases. Another assumption might be People really got bored from rules and don't really stick with them even though existence
-- That's why we see the new cases etc.

select location,date, stringency_index,
Avg(new_cases) over (partition by stringency_index) as avgNewCases,
Avg(cast(new_deaths as int)) over (partition by stringency_index) as avgNewDeaths
from JointDeaVac
where location = 'Germany'

-- My last query is going to be about rolling monthly vaccination done by countries. Let's see which countries are constantly increased or increasing
-- their number of new vaccinations.

--- In order to do this, again I will use Window Function in order to calculate the sum of new cases for each day. 
-- If you don't know about what the heck rolling is. It is just calculation of consecutive days' vaccination in our example. 
-- It can be sales also 
-- For example, we want to calculate rolling weekly sales, first january we made 100 dollar and second day 100 rolling is 200. 
-- 3.day  , 4., 5., 6., 7., we made the same sales 100 dolar which means out weekly rolling number is 700 in the 7th day of january. But 
-- in 8th day we made 200 tl and our rolling weekly sales calcualtion gone up 800 because it doesnt count the first day which we made 100 dolar.
-- Now it calcualtes from 2. day to 8. day because that makes 7 day and we are calcualtion rolling weekly sales. 
-- Its purpose is looking for trend during the time interval. 

-- Now finally Let's calculate our monthly-rolling new_vaccinations 
-- For this we need the location, date, new_vaccinations and the column we are going to create.
Select location,date,new_vaccinations,
sum(cast(new_vaccinations as int)) over(partition by location order by date rows between 29 preceding and current row) as rollingVaccinations
from JointDeaVac
where continent is not null and location ='Turkey'
order by location,date

