-- 1 : Check and handle for duplicate records
-- Initial check for duplicate records
WITH t1 AS (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location_name, industry, total_laid_off, 
		percentage, layoff_date, stage, country, funds_raised_millions) AS row_num
	FROM layoff
)
SELECT * 
FROM t1
WHERE row_num > 1;

-- Create staging table 
CREATE TABLE IF NOT EXISTS layoff_staging(
	company VARCHAR(100),
	location_name VARCHAR(100),
	industry VARCHAR(100),
	total_laid_off VARCHAR(50),
	percentage VARCHAR(50),
	layoff_date VARCHAR(50),
	stage VARCHAR(50),
	country VARCHAR(50),
	funds_raised_millions VARCHAR(50),
	row_num INT
);

-- Insert all existing records with duplicate labels into staging table
INSERT 
INTO layoff_staging(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location_name, industry, total_laid_off, 
		percentage, layoff_date, stage, country, funds_raised_millions) AS row_num
	FROM layoff
);

-- Delete duplicate records from staging table
DELETE 
FROM layoff_staging
WHERE row_num > 1;

-- Ensure the duplicate records are deleted
SELECT * FROM layoff_staging
WHERE row_num > 1;









-- 2 : Standardize values
-- In company, there are whitespaces leading found
-- In order to ensure there are no leading and trailing whitespaces, apply to all String columns
UPDATE layoff_staging
SET 
	company = TRIM(company),
	location_name = TRIM(location_name),
	industry = TRIM(industry),
	layoff_date = TRIM(layoff_date),
	stage = TRIM(stage),
	country = TRIM(country),
	funds_raised_millions = TRIM(funds_raised_millions);

SELECT * FROM layoff_staging;


-- 'Crypto', 'Crypto Currency', 'CryptoCurrency' belong to same industry, set all to 'Crypto' (use 1 as example)
-- 'Ada', 'Ada Health', 'Ada Support' should belong to same company 'Ada' (use 1 as example)
-- 'Dusseldorf' and 'Düsseldorf' should be same location, set to 'Dusseldorf', 'Malmo' and 'Malmö'
-- 'United States' and 'United States.', there is a trailing '.''
SELECT DISTINCT company
FROM layoff_staging
ORDER BY 1;

-- company
UPDATE layoff_staging
SET company = 'Ada'
WHERE company ILIKE 'Ada%';

-- industry
UPDATE layoff_staging
SET industry = 'Crypto'
WHERE industry ILIKE 'Crypto%';

-- location name
CREATE EXTENSION IF NOT EXISTS unaccent;
UPDATE layoff_staging
SET location_name = 'Dusseldorf'
WHERE unaccent(location_name) = 'Dusseldorf';

UPDATE layoff_staging
SET location_name = 'Malmo'
WHERE unaccent(location_name) = 'Malmo';

-- country
UPDATE layoff_staging
SET country = 'United States'
WHERE TRIM(TRAILING '.' FROM country) = 'United States';










-- 3 : Check and handle '' & NULL values
-- set all '' and 'NULL' to just NULL
UPDATE layoff_staging
SET 
    company = CASE WHEN TRIM(company) = '' OR UPPER(TRIM(company)) = 'NULL' THEN NULL ELSE company END,
    location_name = CASE WHEN TRIM(location_name) = '' OR UPPER(TRIM(location_name)) = 'NULL' THEN NULL ELSE location_name END,
    industry = CASE WHEN TRIM(industry) = '' OR UPPER(TRIM(industry)) = 'NULL' THEN NULL ELSE industry END,
    total_laid_off = CASE WHEN TRIM(total_laid_off) = '' OR UPPER(TRIM(total_laid_off)) = 'NULL' THEN NULL ELSE total_laid_off END,
    percentage = CASE WHEN TRIM(percentage) = '' OR UPPER(TRIM(percentage)) = 'NULL' THEN NULL ELSE percentage END,
    layoff_date = CASE WHEN TRIM(layoff_date) = '' OR UPPER(TRIM(layoff_date)) = 'NULL' THEN NULL ELSE layoff_date END,
    stage = CASE WHEN TRIM(stage) = '' OR UPPER(TRIM(stage)) = 'NULL' THEN NULL ELSE stage END,
    country = CASE WHEN TRIM(country) = '' OR UPPER(TRIM(country)) = 'NULL' THEN NULL ELSE country END,
    funds_raised_millions = CASE WHEN TRIM(funds_raised_millions) = '' OR UPPER(TRIM(funds_raised_millions)) = 'NULL' 
		THEN NULL ELSE funds_raised_millions END;

-- delete records with null in necessary columns
DELETE 
FROM layoff_staging
WHERE industry IS NULL OR company IS NULL OR location_name IS NULL OR layoff_date IS NULL OR country IS NULL;

-- check if there are still any NULL records in those columns
SELECT *
FROM layoff_staging
WHERE company IS NULL OR location_name IS NULL OR industry IS NULL OR layoff_date IS NULL OR country IS NULL;










-- 4 : Update to proper column data types
ALTER TABLE layoff_staging
ALTER COLUMN total_laid_off TYPE INT
USING total_laid_off::INT;

ALTER TABLE layoff_staging
ALTER COLUMN percentage TYPE NUMERIC(10,2)
USING percentage::NUMERIC;

ALTER TABLE layoff_staging
ALTER COLUMN layoff_date TYPE DATE
USING TO_DATE(layoff_date, 'MM-DD-YYYY');

ALTER TABLE layoff_staging
ALTER COLUMN funds_raised_millions TYPE NUMERIC(10,2)
USING funds_raised_millions::NUMERIC;

ALTER TABLE layoff_staging
DROP COLUMN row_num;

SELECT * FROM layoff_staging;