SELECT 
	runName
	, ruleName
	, rule
	, kind
	, SUM(matches) as matches
	, SUM(rewrites) as rewrites
	, locationFile
	, locationFrom
	, locationTo
FROM data
WHERE 
	kind LIKE 'structural' 
	OR kind LIKE 'computational'
GROUP BY 
	runName
	, rule
ORDER BY
	matches DESC