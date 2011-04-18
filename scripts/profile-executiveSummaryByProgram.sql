SELECT 
	runName
	, count(distinct rule) as numRules
FROM data
WHERE 
	(kind LIKE 'structural' OR kind LIKE 'computational')
	AND rewrites > 0
GROUP BY 
	runName
ORDER BY
	numRules DESC