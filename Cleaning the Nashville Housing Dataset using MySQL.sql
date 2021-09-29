/*
CLEANING THE NASHVILLE HOUSING DATASET:
1) Standardize the Date Format in the 'SaleDate' column
2) Populate the NULL values in 'PropertyAddress' column
3) Splitting 'PropertyAddress' column into Individual Columns (Address, City, State)
4) Splitting 'OwnerAddress' column into individual Columns (Address, City, State)
5) Change Y and N to Yes and No respectively in the 'SoldAsVacant" column
6) Remove duplicate records from the Table
7) Delete redundant or unncessary columns
*/



#The FIRST 10 rows of the nashvillehousing dataset
SELECT *
FROM projectportfolio.nashvillehousing
LIMIT 10;

# DATA CLEANING ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 1) Standardize the Date Format in the 'SaleDate' column
SELECT SaleDate, STR_TO_DATE(SaleDate, "%M %e, %Y") 
FROM projectportfolio.nashvillehousing
LIMIT 10;

UPDATE projectportfolio.nashvillehousing
SET SaleDate = str_to_date(SaleDate, '%M %e, %Y');

SELECT SaleDate
FROM projectportfolio.nashvillehousing
LIMIT 10;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


# 2) Populate the NULL values in 'PropertyAddress' column
SELECT PropertyAddress 
FROM projectportfolio.nashvillehousing
WHERE PropertyAddress IS NULL;

SELECT DISTINCT ParcelID, PropertyAddress 
FROM projectportfolio.nashvillehousing;

-- creating a copy of nashvillehousing to populate these null values
DROP TABLE IF EXISTS nashvillehousing2;
CREATE TABLE nashvillehousing2 AS
SELECT *
FROM projectportfolio.nashvillehousing;

/*
Now, we will use the 'propertyaddress' field of nashvillehousing2 to populate the null values in 'propertyaddress' column of nashvillehousing
with the help of 'uniqueid' and 'parcelid' fields. 
*/
START TRANSACTION;

UPDATE projectportfolio.nashvillehousing, projectportfolio.nashvillehousing2 
SET projectportfolio.nashvillehousing.propertyaddress = projectportfolio.nashvillehousing2.propertyaddress
WHERE projectportfolio.nashvillehousing.propertyaddress IS NULL AND projectportfolio.nashvillehousing.uniqueid <> projectportfolio.nashvillehousing2.UniqueID AND
projectportfolio.nashvillehousing.parcelid = projectportfolio.nashvillehousing2.parcelid;

-- COMMIT;
ROLLBACK;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 3) Splitting 'PropertyAddress' column into Individual Columns (Address, City, State)
SELECT PropertyAddress
FROM projectportfolio.nashvillehousing
LIMIT 10;
/*
From the result of above query, you can see that the property address is a combination of the address and city. Lets split it into
two columns: PropertySplitAddress and PropertySplitCity
*/
SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) AS 'Address', 
	   SUBSTRING(PropertyAddress, LOCATE(',',PropertyAddress)+1) AS 'City'
FROM projectportfolio.nashvillehousing
LIMIT 10;

-- Create a New column in nashvilliehousing called 'PropertySplitAddress'
ALTER TABLE projectportfolio.nashvillehousing
ADD COLUMN PropertySplitAddress varchar(255);

-- Update this column with the address of the property
UPDATE projectportfolio.nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1);

-- Create a New column 'PropertySplitCity' in nashvillehousing table
ALTER TABLE projectportfolio.nashvillehousing
ADD COLUMN PropertySplitCity varchar(255);

-- Update this column with the city of the property
UPDATE projectportfolio.nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, length(PropertyAddress));


SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM projectportfolio.nashvillehousing;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 4) Splitting 'OwnerAddress' column into individual Columns (Address, City, State)
SELECT OwnerAddress
FROM projectportfolio.nashvillehousing
LIMIT 10;

/*
As you can see from the output of the above query, the OwnerAddress column is a combination of the address, city and state of the owner. 
Let's split them into 3 columns.
*/

SELECT SUBSTRING_INDEX(OwnerAddress, ",", 1),
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ",", -2), ',',1),
SUBSTRING_INDEX(OwnerAddress, ",", -1)
FROM projectportfolio.nashvillehousing;

-- Creating and Updating 3 New columns: OwnerSplitAddress, OwnerSplitCity, OwnnerSplitState

ALTER TABLE nashvillehousing
ADD OwnerSplitAddress varchar(255);

UPDATE nashvillehousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ",", 1);

ALTER TABLE nashvillehousing
ADD OwnerSplitCity varchar(255);

UPDATE nashvillehousing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ",", -2), ',',1);

ALTER TABLE nashvillehousing
ADD OwnerSplitState varchar(255);

UPDATE nashvillehousing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ",", -1);

SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM projectportfolio.nashvillehousing;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 5) Change Y and N to Yes and No respectively in the 'SoldAsVacant" column

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM projectportfolio.nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

/*
From the output of the above query, we can see that the category variable 'SoldAsVacant' has four categories: Y, N, Yes and No. 
Since Y and Yes are the same thing, combine them into the label 'Yes'. Likewise for N and No.
*/

SELECT SoldAsVacant, 
	   CASE
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
            WHEN SoldAsVacant = 'N' THEN 'No'
            ELSE SoldAsVacant
            END AS SoldAsVacant1
FROM projectportfolio.nashvillehousing;


UPDATE projectportfolio.nashvillehousing
SET SoldAsVacant = CASE
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
            WHEN SoldAsVacant = 'N' THEN 'No'
            ELSE SoldAsVacant
            END;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 6) REMOVE DUPLICATE RECORDS from the Table

-- STEP 1: Marking Duplicate Records
SELECT *, ROW_NUMBER() OVER( PARTITION BY ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference
							 ORDER BY UniqueID) AS row_num
FROM projectportfolio.nashvillehousing;

-- STEP 2: Identifying Duplicate Records
SELECT UniqueID
FROM (SELECT *, ROW_NUMBER() OVER( PARTITION BY ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference
							 ORDER BY UniqueID) AS row_num
FROM projectportfolio.nashvillehousing
) AS t
WHERE row_num >1;

-- STEP 3: DELETING DUPLICATE RECORDS
DELETE FROM projectportfolio.nashvillehousing
WHERE UniqueID IN (
SELECT UniqueID
FROM (SELECT *, ROW_NUMBER() OVER( PARTITION BY ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference
							 ORDER BY UniqueID) AS row_num
FROM projectportfolio.nashvillehousing
) AS t
WHERE row_num >1);

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# 7) DELETE REDUNDANT OR UNNECESSARY COLUMNS

SELECT *
FROM projectportfolio.nashvillehousing;

ALTER TABLE projectportfolio.nashvillehousing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# CLEANED NASHVILLE HOUSING DATASET
SELECT *
FROM projectportfolio.nashvillehousing;