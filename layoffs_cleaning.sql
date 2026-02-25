CREATE DATABASE layoffs;
USE layoffs;

SELECT * FROM layoffs;

-- Data clenaing steps
-- 1. Remove duplicates
-- 2.Null values or Blank
-- 3.Remove any columns

-- Adding copy table (one should not change or work on raw/real data)
CREATE TABLE layoffs_copy
LIKE layoffs;

-- Imserting into copy table
INSERT layoffs_copy SELECT * FROM layoffs;

SELECT * FROM layoffs_copy2;


-- removing duplicates
SELECT * FROM(SELECT * ,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,date,stage,country,funds_raised_millions ORDER BY company DESC)
AS rn FROM layoffs_copy)t WHERE rn>1;

WITH MonthlyLayoffs AS (
    SELECT 
        YEAR(date) AS year,
        MONTH(date) AS month,
        SUM(total_laid_off) AS total_layoffs
    FROM layoffs_copy2
    GROUP BY YEAR(date), MONTH(date)
),
RankedMonths AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY year
            ORDER BY total_layoffs DESC
        ) AS rn
    FROM MonthlyLayoffs
)
SELECT year, month, total_layoffs
FROM RankedMonths
WHERE rn = 1
ORDER BY year;


WITH monthly AS
(SELECT YEAR(DATE) AS year,MONTH(DATE) AS month,SUM(total_laid_off) AS total_layoffs FROM layoffs_copy2 GROUP BY YEAR,MONTH ) ,
RANKedmonths AS ( SELECT *, ROW_NUMBER() OVER(PARTITION BY YEAR ORDER BY total_layoffs DESC) AS rn FROM monthly) SELECT year,month,total_layoffs FROM RANKedmonths WHERE rn=1;
-- for deleting again we have create a raw table and insert into the data
CREATE TABLE `layoffs_copy2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- inserting into layoffs_copy2
INSERT INTO layoffs_copy2
SELECT * ,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,date,stage,country,funds_raised_millions ORDER BY company DESC)
AS rn FROM layoffs_copy;

-- NOW DELETING DUPLICATES
DELETE  FROM layoffs_copy2 WHERE `row_num` >1 ;
SET SQL_SAFE_UPDATES=0;

-- Standarizing Data


-- Deleting trim spaces(trum only works for text (as num dont have any extra spaces

UPDATE layoffs_copy2
SET country=TRIM(country);

SELECT company,TRIM(company) FROM layoffs_copy2;

SELECT DISTINCT(TRIM(industry)) FROM layoffs_copy2 ORDER BY 1;

SELECT * FROM layoffs_copy2 WHERE industry LIKE "Crypto%";
UPDATE layoffs_copy2 SET industry="Crypto" WHERE industry LIKE "Crypto%"; 


SELECT DISTINCT location FROM layoffs_copy2;


SELECT DISTINCT country FROM layoffs_copy2 ORDER BY 1;
UPDATE layoffs_copy2  SET country="United States" WHERE country LIKE "United States%";


-- Date
UPDATE layoffs_copy2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');

SELECT `date` FROM layoffs_copy2;

ALTER TABLE layoffs_copy2 MODIFY COLUMN `date` DATE;
SELECT * FROM layoffs_copy2 WHERE DATE IS NULL;
-- working with null AND blank values


SELECT * FROM layoffs_copy2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL ;

SELECT * FROM layoffs_copy2 WHERE industry IS NULL OR industry="";


SELECT * FROM layoffs_copy2 WHERE company ="Carvana";

UPDATE layoffs_copy2 SET industry=NULL WHERE industry ="";
SELECT * FROM layoffs_copy2 t1
         JOIN layoffs_copy2 t2 ON t1.company=t2.company OR t1.location = t2.location
         WHERE (t1.industry IS NULL)
         AND t2.industry IS NOT NULL;

UPDATE layoffs_copy2 t1
         JOIN layoffs_copy2 t2 ON t1.company=t2.company OR t1.location = t2.location
         SET t1.industry=t2.industry
		 WHERE t1.industry IS NULL;


-- Removing unnessary coloums 
ALTER TABLE layoffs_copy2 DROP COLUMN `row_num` ;



-- Data Analysis

-- total number of rows
SELECT COUNT(*) FROM layoffs_copy2;

-- earliest and last date
SELECT  MAX(DATE),MIN(DATE) FROM layoffs_copy2;
SELECT  DISTINCT(YEAR(DATE)) FROM layoffs_copy2;

-- Phase 1
-- What is the total number of employees laid off across all companies?
SELECT SUM(total_laid_off) AS total_layoffs FROM layoffs_copy2 ;
-- ow many companies are in this dataset?
SELECT COUNT(DISTINCT(company)) AS total_companies FROM layoffs_copy2;
-- What is the date range of layoffs?
SELECT  MAX(DATE),MIN(DATE) FROM layoffs_copy2;
-- What is the largest number of employees laid off in a single event?
SELECT company,MAX(total_laid_off)AS total_layoffs FROM layoffs_copy2 GROUP BY company ORDER BY 2 DESC LIMIT 1;
-- How many companies completely shut down?
SELECT COUNT(*) AS no_of_shudown_companies FROM layoffs_copy2 WHERE percentage_laid_off=1;
-- Show the list of companies that completely shut down
SELECT DISTINCT(company),total_laid_off,percentage_laid_off FROM layoffs_copy2 WHERE percentage_laid_off=1;
-- Which industry had the highest total layoffs?
SELECT industry,SUM(total_laid_off) AS total_layoffs FROM layoffs_copy2 GROUP BY industry ORDER BY 2 DESC LIMIT 1;

-- Phase 2 (Time Trend Analysis)

-- Which year had the highest total layoffs?
SELECT YEAR(DATE) AS YEAR,SUM(total_laid_off) AS total_layoffs FROM layoffs_copy2 GROUP BY YEAR(DATE) ORDER BY 2 DESC LIMIT 1;
-- Show total layoffs for each year (not just highest)
SELECT YEAR(DATE) AS YEAR,SUM(total_laid_off) AS total_layoffs FROM layoffs_copy2  WHERE DATE IS NOT NULL GROUP BY YEAR(DATE) ORDER BY 2 DESC;
-- Show total layoffs per month
SELECT DATE_FORMAT(DATE,'%Y-%m') AS MONTH,SUM(total_laid_off) AS total_layoffs FROM layoffs_copy2  WHERE DATE IS NOT NULL GROUP BY 1 ORDER BY 1 ASC;
-- How layoffs accumulated over time
WITH cumulative_amount AS(
SELECT DATE_FORMAT(DATE,'%Y-%m') AS MONTH,SUM(total_laid_off) AS total_layoffs FROM layoffs_copy2  WHERE DATE IS NOT NULL GROUP BY 1 ORDER BY 1 ASC
)SELECT MONTH,total_layoffs,SUM(total_layoffs) OVER(ORDER BY MONTH) AS monthly_total_layoffs FROM cumulative_amount ;
-- Which companies had the most layoffs overall (Top 10)?
WITH cte_col AS  (
SELECT company,SUM(total_laid_off) AS total_layoffs  FROM layoffs_copy2  GROUP BY 1 ORDER BY 2 DESC LIMIT 10) SELECT company,total_layoffs,DENSE_RANK()
OVER(ORDER BY total_layoffs DESC) AS Ranking FROM cte_col;

SELECT * FROM layoffs_copy2;















