
--cleaning data in SQL Server

select * 
from .dbo.national_housing$

--Standard Date Format

alter table national_housing$
add SaledateConverted Date

update national_housing$
set SaledateConverted = convert(date,SaleDate)

select SaledateConverted,convert(date,SaleDate)
from .dbo.national_housing$

--POPULATE PROPERTY ADDRESS DATA

select *
from .dbo.national_housing$
where PropertyAddress is null

select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress,ISNULL(a.PropertyAddress,b.PropertyAddress)
from national_housing$ a
join national_housing$ b
on a.ParcelID = b.ParcelID
   and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from national_housing$ a
join national_housing$ b
on a.ParcelID = b.ParcelID
   and a.[UniqueID ] <> b.[UniqueID ]


--breaking out address into individual colums (address, city,state)
--1.break PropertyAddress

select PropertyAddress,SUBSTRING(PropertyAddress,1,charindex(',',PropertyAddress,1)-1) 'Address',
SUBSTRING(PropertyAddress,charindex(',',PropertyAddress,1)+1,len(PropertyAddress)) 'City'
from national_housing$

alter table national_housing$
add PropAddress varchar(255)

update national_housing$
set PropAddress = SUBSTRING(PropertyAddress,1,charindex(',',PropertyAddress,1)-1)

alter table national_housing$
add PropCity varchar(255)

update national_housing$
set PropCity = SUBSTRING(PropertyAddress,charindex(',',PropertyAddress,1)+1,len(PropertyAddress))

select *
from national_housing$


--2.break OwnerAddress

select OwnerAddress,parsename(replace(OwnerAddress,',','.'),3)
from national_housing$

alter table national_housing$
add OwnAddress varchar(255)

update national_housing$
set OwnAddress = parsename(replace(OwnerAddress,',','.'),3)

alter table national_housing$
add OwnCity varchar(255)

update national_housing$
set OwnCity = parsename(replace(OwnerAddress,',','.'),2)

alter table national_housing$
add OwnState varchar(255)

update national_housing$
set OwnState = parsename(replace(OwnerAddress,',','.'),1)

select *
from national_housing$


--change Y and N to Yes and No in 'Sold as Vacant' field

select SoldAsVacant,
case when SoldAsVacant='Y' then 'Yes'
	 when SoldAsVacant='N' then 'No'
	 else SoldAsVacant
	 end
from national_housing$


update national_housing$
set SoldAsVacant = 
case when SoldAsVacant='Y' then 'Yes'
	 when SoldAsVacant='N' then 'No'
	 else SoldAsVacant
	 end


select distinct SoldAsVacant,count(SoldAsVacant)
from national_housing$
group by SoldAsVacant

--remove duplicates

select *
from national_housing$

select *
from(
select *, ROW_NUMBER() over(
partition by ParcelID,
			 LandUse,
			 PropertyAddress,
			 SaleDate,
			 SalePrice
			 order by UniqueID) ranking
From national_housing$) new
where ranking <>1

with  rankingnew as(
select *, ROW_NUMBER() over(
partition by ParcelID,
			 LandUse,
			 PropertyAddress,
			 SaleDate,
			 SalePrice
			 order by UniqueID) ranking
From national_housing$)

Select *
From rankingnew
Where ranking > 1
Order by PropertyAddress

--delete unused col

alter table national_housing$
drop column PropertyAddress,OwnerAddress,TaxDistrict

select *
from national_housing$