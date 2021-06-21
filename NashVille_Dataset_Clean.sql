-- In this mysql file, I'm going to run some queries in order to clean a public dataset named Nashville_Housing.
-- I aim to show my skills in SQL and more specifically when it comes to data cleaning.

-- LOAD CSV FILE 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Nashville Housing Data for Data Cleaning.csv' 
INTO TABLE nashville_housing.nashville
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(@UniqueID,
@ParcelID, 
@LandUse, 
@PropertyAddress, 
@SaleDate, 
@SalePrice, 
@LegalReference, 
@SoldAsVacant,
@OwnerName,
@OwnerAddress,
@Acreage,
@TaxDistrict,
@LandValue,
@BuildingValue,
@TotalValue,
@YearBuilt,
@Bedrooms,
@FullBath,
@HalfBath )

-- SINCE I HAVE MANY EMPTY CELLS I'LL REPLACE THEM WITH NULLS
SET 
UniqueID = NULLIF(@UniqueID,''),                                      
ParcelID = NULLIF(@ParcelID,''),
LandUse = NULLIF(@LandUse,''),
PropertyAddress = NULLIF(@PropertyAddress,''),
SaleDate = NULLIF(@SaleDate,''),
SalePrice = NULLIF(@SalePrice,''),
LegalReference = NULLIF(@LegalReference,''),
SoldAsVacant = NULLIF(@SoldAsVacant,''),
OwnerName = NULLIF(@OwnerName,''),
OwnerAddress = NULLIF(@OwnerAddress,''),
Acreage = NULLIF(@Acreage,''),
TaxDistrict = NULLIF(@TaxDistrict,''),
LandValue = NULLIF(@LandValue,''),
BuildingValue = NULLIF(@BuildingValue,''),
TotalValue = NULLIF(@TotalValue,''),
YearBuilt = NULLIF(@YearBuilt,''),
Bedrooms = NULLIF(@Bedrooms,''),
FullBath = NULLIF(@FullBath,''),
HalfBath = NULLIF(@HalfBath,'');

# Change DataTypes
# SaleDate
UPDATE nashville_housing.nashville
SET 
    SaleDate = STR_TO_DATE(SaleDate, '%c/%e/%Y')
            
WHERE
    UniqueID IS NOT NULL;


ALTER TABLE nashville_housing.nashville
      CHANGE SaleDate SaleDate DATE;
      
# HalfBath
UPDATE nashville_housing.nashville
SET 
    HalfBath = STR_TO_DATE(SaleDate, '%c/%e/%Y')
            
WHERE
    UniqueID IS NOT NULL;
      
-- QUERIES --
-- IN THIS MYSQL FILE, WE'LL CLEAN THIS DATASET
-- We can see that both PropertyAddress and OwnerAddress have null values, we'll replace them by corresponding values (For example when PropAdd is null we can replace it with OwnerDD and Vice Versa)
ALTER TABLE nashville_housing.nashville
	ADD Property_Address TEXT
		AFTER PropertyAddress,
    	ADD Owner_Address TEXT
		AFTER OwnerAddress;
        
UPDATE nashville_housing.nashville
	SET 
		Property_Address = coalesce(PropertyAddress, OwnerAddress, NULL),
        	Owner_Address = coalesce(OwnerAddress,PropertyAddress , NULL);

ALTER TABLE nashville_housing.nashville
	DROP COLUMN PropertyAddress, 
    	DROP COLUMN OwnerAddress;

# We still have some missing values so we'll replace them by using addresses with same parcelID
# To do that we need to first create a temp table then Update the records in our original table
CREATE TEMPORARY TABLE B
SELECT 
	a.ParcelID AS ID, 
	coalesce(a.Property_Address,
	b.Property_Address, NULL) AS ADDRESS
FROM 
	nashville_housing.nashville a 
JOIN nashville_housing.nashville b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.Property_Address IS NULL;

UPDATE nashville_housing.nashville , B
SET nashville_housing.nashville.Property_Address = B.ADDRESS
WHERE nashville_housing.nashville.ParcelID = B.ID;

-- Check modifications were succesfull for one record
SELECT 
	ParcelID, 
	Property_Address
FROM 
	nashville_housing.nashville 
WHERE 
	UniqueID IN (SELECT ID FROM B) ;

-- Breaking Address into individual cols (Address, City, State) 
SELECT 
    Owner_Address,
    SUBSTRING_INDEX(Owner_Address, ",", 1) AS ADDRESS,
    SUBSTRING_INDEX(SUBSTRING_INDEX(Owner_Address, ",", 2), ",", -1 ) AS City,
    SUBSTRING_INDEX(SUBSTRING_INDEX(Owner_Address, ",", -2), ",", -1 ) AS State
FROM 
	nashville_housing.nashville;

# Add these values into new cols
ALTER TABLE nashville_housing.nashville
	ADD Property_Address_Split TEXT,
    	ADD Property_City_Split TEXT,
    	ADD Property_State_Split TEXT
		AFTER Property_Address;    

UPDATE nashville_housing.nashville
	SET 
	Property_Address_Split = SUBSTRING_INDEX(Owner_Address, ",", 1),
        Property_City_Split = SUBSTRING_INDEX(SUBSTRING_INDEX(Owner_Address, ",", 2), ",", -1 ),
        Property_State_Split = SUBSTRING_INDEX(SUBSTRING_INDEX(Owner_Address, ",", -2), ",", -1 );

# Inspect data
SELECT 
	*
FROM
	nashville_housing.nashville;

# Change SoldAsVacant values to Y and N
SELECT 
	DISTINCT SoldAsVacant
FROM 
	nashville_housing.nashville;   

UPDATE nashville_housing.nashville
SET 
	SoldAsVacant = 'Y' WHERE TRIM(SoldAsVacant) = 'Yes';   

UPDATE nashville_housing.nashville
SET 
	SoldAsVacant = 'N' WHERE TRIM(SoldAsVacant) = 'No';   

# Verify query
SELECT 
	DISTINCT SoldAsVacant,
    	COUNT(SoldAsVacant) AS num
FROM 
	nashville_housing.nashville
GROUP BY SoldAsVacant
ORDER BY num DESC;

-- Remove duplicates
-- We're going to assume that if we find duplicates in ParcelID, Proprety_Address, SalePrice and SaleDate then this row will be considered as a duplicate
SELECT
	UniqueID,
	ParcelID, COUNT(ParcelID),
    	Property_Address, COUNT(Property_Address),
    	SalePrice, COUNT(SalePrice), 
    	SaleDate, COUNT(SaleDate)
FROM 
	nashville_housing.nashville
GROUP BY 
	ParcelID,
    Property_Address,
    SalePrice,
    SaleDate
HAVING 
	COUNT(ParcelID) > 1
	AND COUNT(Property_Address) > 1
    AND COUNT(SalePrice) > 1
    AND COUNT(SaleDate) > 1
    ;
    
# Verify Query for this parcelID, we can indeed see that this row is a duplicate     
SELECT 
	*
FROM
	nashville_housing.nashville 
WHERE 
	ParcelID = '034 05 0 041.00';

# Now we're going to use the UniqueIDs found in the query above for removing duplicates
# To make things easier, we're going to put the query into a temp table then filter out the UniqueIDs that contain duplicates

CREATE TEMPORARY TABLE duplicates
SELECT
	UniqueID,
	ParcelID, COUNT(ParcelID),
    	Property_Address, COUNT(Property_Address),
    	SalePrice, COUNT(SalePrice), 
    	SaleDate, COUNT(SaleDate)
FROM 
	nashville_housing.nashville
GROUP BY 
	ParcelID,
    	Property_Address,
    	SalePrice,
    	SaleDate
HAVING 
	COUNT(ParcelID) > 1
	AND COUNT(Property_Address) > 1
    	AND COUNT(SalePrice) > 1
    	AND COUNT(SaleDate) > 1
    ;

# Delete the duplicates
DELETE 
	FROM 
		nashville_housing.nashville 
			WHERE 
				UniqueID IN (SELECT UniqueID FROM duplicates);
