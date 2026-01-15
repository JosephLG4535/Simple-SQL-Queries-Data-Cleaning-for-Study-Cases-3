-- table creation
-- set initial INT and MUMERIC data to VARCHAR to support '' and NULL
-- set initial DATE to VARCHAR since the date format does not match
CREATE TABLE IF NOT EXISTS layoff(
	company VARCHAR(100),
	location_name VARCHAR(100),
	industry VARCHAR(100),
	total_laid_off VARCHAR(50),
	percentage VARCHAR(50),
	layoff_date VARCHAR(50),
	stage VARCHAR(50),
	country VARCHAR(50),
	funds_raised_millions VARCHAR(50)
);