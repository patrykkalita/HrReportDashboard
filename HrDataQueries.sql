USE HR;

SELECT * FROM hr_data;

SELECT termdate FROM hr_data ORDER BY termdate DESC;

UPDATE hr_data SET termdate = FORMAT(CONVERT(DATETIME, LEFT(termdate, 19), 120), 'yyyy-MM-dd');

-- Creating new column 'new_termdate'
ALTER TABLE hr_data ADD new_termdate DATE;
UPDATE hr_data SET new_termdate = 
CASE
	WHEN termdate IS NOT NULL AND ISDATE(termdate) = 1 THEN CAST(termdate AS DATETIME)
	ELSE NULL
END;

-- Creating column 'age'
ALTER TABLE hr_data ADD age NVARCHAR(50);

UPDATE hr_data SET age = DATEDIFF(YEAR, birthdate, GETDATE());

-- Age distribution
SELECT MIN(age) AS Youngest, MAX(age) AS Oldest FROM hr_data;

SELECT age_group, COUNT(*) AS Count FROM
(SELECT
CASE
	WHEN age >= 21 AND age <= 30 THEN '21 to 30'
	WHEN age >= 31 AND age <= 40 THEN '31 to 40'
	WHEN age >= 41 AND age <= 50 THEN '41 to 50'
	ELSE '50+'
END AS age_group
FROM hr_data WHERE new_termdate IS NULL) AS subquery
GROUP BY age_group ORDER BY age_group;

-- Age group by gender
SELECT age_group, gender, COUNT(*) AS Count FROM
(SELECT
CASE
	WHEN age >= 21 AND age <= 30 THEN '21 to 30'
	WHEN age >= 31 AND age <= 40 THEN '31 to 40'
	WHEN age >= 41 AND age <= 50 THEN '41 to 50'
	ELSE '50+'
END AS age_group, gender
FROM hr_data WHERE new_termdate IS NULL) AS subquery
GROUP BY age_group, gender ORDER BY age_group, gender;


-- Gender breakdown in the company
SELECT gender, COUNT(gender) AS Count
FROM hr_data WHERE new_termdate IS NULL
GROUP BY gender ORDER BY gender;

-- How does gender vary across departments and job titles
SELECT department, gender, COUNT(gender) AS Count
FROM hr_data WHERE new_termdate IS NULL
GROUP BY department, gender ORDER BY department, gender;

-- Job titles
SELECT department, jobtitle, gender, COUNT(gender) AS Count
FROM hr_data WHERE new_termdate IS NULL
GROUP BY department, jobtitle, gender ORDER BY department, jobtitle, gender;

-- Race distribution in the company
SELECT race, COUNT(*) AS Count FROM hr_data
WHERE new_termdate IS NULL
GROUP BY race ORDER BY Count DESC;

-- Average duration of employment in the company
SELECT AVG(DATEDIFF(YEAR, hire_date, new_termdate)) AS Tenure
FROM hr_data WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE();

-- Department with the highest turnover rate
SELECT department, total_count, terminated_count, 
ROUND(CAST(terminated_count AS FLOAT) / total_count, 2) * 100 AS turnover_rate
FROM(
	SELECT department, COUNT(*) AS total_count,
	SUM(
	CASE
		WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1
		ELSE 0
	END) AS terminated_count
	FROM hr_data GROUP BY department) AS subquery
ORDER BY turnover_rate DESC;

-- Tenure distribution for each department
SELECT department, AVG(DATEDIFF(YEAR, hire_date, new_termdate)) AS Tenure
FROM hr_data WHERE new_termdate IS NOT NULL AND new_termdate <= GETDATE()
GROUP BY department ORDER BY tenure DESC;

-- Number of employees that work remotely in each department
SELECT location, COUNT(*) AS Count FROM hr_data
WHERE new_termdate IS NULL GROUP BY location;

-- The distribution of employees across different states
SELECT location_state, COUNT(*) AS Count
FROM hr_data WHERE new_termdate IS NULL
GROUP BY location_state ORDER BY Count DESC;

-- Job titles distribution in the company
SELECT jobtitle, COUNT(*) AS Count
FROM hr_data WHERE new_termdate IS NULL
GROUP BY jobtitle ORDER BY Count DESC;

-- How have employee hire counts varied over time
SELECT hire_year, hires, terminations, (hires - terminations) AS net_change, ROUND(CAST(hires - terminations AS FLOAT) / hires, 2) * 100 AS percent_hire_change
FROM(
	SELECT YEAR(hire_date) AS hire_year, COUNT(*) AS hires, 
	SUM(
	CASE
		WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1
		ELSE 0
	END 
	) AS terminations
	FROM hr_data GROUP BY YEAR(hire_date)) AS subquery
ORDER BY percent_hire_change;