CREATE DATABASE nashville;

USE nashville;

DROP TABLE IF EXISTS housing;
CREATE TABLE housing (
UniqueID INT,
ParcelID VARCHAR(255),
LandUse VARCHAR(255),
PropertyAddress VARCHAR(255),
SaleDate DATETIME,
SalePrice INT,
LegalReference VARCHAR(255),
SoldAsVacant VARCHAR(255),
OwnerName VARCHAR(255),
OwnerAddress VARCHAR(255),
Acreage FLOAT,
TaxDistrict VARCHAR(255),
LandValue INT,
BuildingValue INT,
TotalValue INT,
YearBuilt INT,
Bedrooms INT,
FullBath INT,
HalfBath INT);

LOAD DATA LOCAL INFILE "/Users/nicholas/Desktop/MySQL/Nashville_Housing.csv" INTO TABLE housing FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

-- Standardise date format
SET SQL_SAFE_UPDATES = 0;

ALTER TABLE housing
ADD SaleDateConverted Date;

UPDATE housing
SET SaleDateConverted = CONVERT(SaleDate, Date);

SELECT SaleDateConverted, SaleDate
FROM housing
LIMIT 10;


-- Populate property address date
SELECT *
FROM housing
WHERE PropertyAddress = '';

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IF(a.PropertyAddress = '', b.PropertyAddress, a.PropertyAddress) as UpdatedAddress
FROM housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress = '';

UPDATE housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = IF(a.PropertyAddress = '', b.PropertyAddress, a.PropertyAddress)
WHERE a.PropertyAddress = '';


-- Breaking out address into different columns (Address, City, State)

	-- PropertyAddress
SELECT PropertyAddress FROM housing;

SELECT 
SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Street, SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) AS City
FROM housing;

ALTER TABLE housing
ADD PropertySplitAddress VARCHAR(255);

UPDATE housing
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress,',',1);

ALTER TABLE housing
ADD PropertySplitCity VARCHAR(255);

UPDATE housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress));

SELECT * FROM housing;

	-- OwnerAddress
    
CREATE FUNCTION SPLIT_STR(
  x VARCHAR(255),
  delim VARCHAR(12),
  pos INT
)
RETURNS VARCHAR(255)
DETERMINISTIC
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
       LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
       delim, '') ;
       
SELECT
SPLIT_STR(OwnerAddress, ',', 1) as Street,
SPLIT_STR(OwnerAddress, ',', 2) as City,
SPLIT_STR(OwnerAddress, ',', 3) as State
FROM housing;

ALTER TABLE housing
ADD OwnerSplitStreet VARCHAR(255),
ADD OwnerSplitCity VARCHAR(255),
ADD OwnerSplitState VARCHAR(255);

UPDATE housing
SET OwnerSplitStreet = SPLIT_STR(OwnerAddress, ',', 1),
OwnerSplitCity = SPLIT_STR(OwnerAddress, ',', 2),
OwnerSplitState = SPLIT_STR(OwnerAddress, ',', 3);


-- Change Y and N to Yes and No in "SoldAsVacant"
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM housing
GROUP BY SoldAsVacant;

SELECT SoldAsVacant, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						  WHEN SoldAsVacant = 'N' THEN 'No'
                          ELSE SoldAsVacant
                          END
FROM housing
WHERE SoldAsVacant = 'Y'
OR SoldAsVacant = 'N';

UPDATE housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END;
                        


-- Remove duplicates
DELETE hd 
FROM housing hd INNER JOIN
(
SELECT UniqueID, ROW_NUMBER() OVER (
				 PARTITION BY ParcelID,
							  PropertyAddress,
                              SalePrice,
                              SaleDate,
                              LegalReference
                              ORDER BY
								UniqueID) AS row_num
FROM housing) t1
ON hd.UniqueID = t1.UniqueID
WHERE t1.row_num>1;

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY
					UniqueID
                    ) AS row_num
FROM housing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;


-- Delete unused columns
SELECT * FROM housing;

ALTER TABLE housing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;

						

