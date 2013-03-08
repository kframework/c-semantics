SELECT 
	locationFile
	, SUM(matches) as matches
	, SUM(rewrites) as rewrites
FROM data
GROUP BY
	locationFile
ORDER BY
	matches DESC