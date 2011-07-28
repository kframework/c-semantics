SELECT 
	SUM(matches) as matches
	, SUM(rewrites) as rewrites
	, SUM(matches) - SUM(rewrites) as misses
FROM data
WHERE 
	kind LIKE 'structural' 
	OR kind LIKE 'computational'
ORDER BY
	matches DESC