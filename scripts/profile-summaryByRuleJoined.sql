SELECT 
	data.ruleName
	, data.kind
	, SUM(matches) as matches
	, SUM(rewrites) as rewrites
	, rules.locationFile
	, rules.locationFrom
	, rules.locationTo
FROM rules 
LEFT OUTER JOIN data ON
	data.locationFile = rules.locationFile
	AND data.locationFrom = rules.locationFrom
	AND data.locationTo = rules.locationTo
WHERE 
	NOT rules.locationFile = "common-c-syntax.k"
	AND NOT rules.locationFile = "dynamic-c-standard-lib.k"
	AND NOT rules.locationFile = "dynamic-c-errors.k"
GROUP BY
	rules.locationFile,
	rules.locationFrom,
	rules.locationTo
ORDER BY
	matches DESC