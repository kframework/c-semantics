SELECT 
	ruleName
	, rule
	, kind
	, SUM(matches) as matches
	, SUM(rewrites) as rewrites
	, locationFile
	, locationFrom
	, locationTo
FROM data
WHERE 
	runName NOT LIKE 'tmpSemanticCalibration'
	AND (kind LIKE 'structural' OR kind LIKE 'computational')
GROUP BY 
	rule
ORDER BY
	matches DESC