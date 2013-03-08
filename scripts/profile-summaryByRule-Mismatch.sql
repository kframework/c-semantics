SELECT 
	ruleName
	, rule
	, kind
	, SUM(matches) as matches
	, SUM(rewrites) as rewrites
	, SUM(matches) - SUM(rewrites) as diff
	, locationFile
	, locationFrom
	, locationTo
FROM data
WHERE 
	kind LIKE 'structural' 
	OR kind LIKE 'computational'
GROUP BY 
	rule
ORDER BY
	diff DESC
	, locationFile DESC
	