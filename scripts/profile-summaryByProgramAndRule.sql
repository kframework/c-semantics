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
	runName NOT LIKE 'tmpSemanticCalibration'
	AND (kind LIKE 'structural' OR kind LIKE 'computational')
GROUP BY 
	runName
	, rule
ORDER BY
	matches DESC