SELECT 
	locationFile
	, SUM(matches) as matches
	, SUM(rewrites) as rewrites
FROM data
WHERE 
	runName NOT LIKE 'tmpSemanticCalibration'
GROUP BY
	locationFile
ORDER BY
	matches DESC