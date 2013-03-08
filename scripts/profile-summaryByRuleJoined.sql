SELECT 
	rules.ruleName
	, rules.kind
	, COALESCE(SUM(matches), 0) as matches
	, COALESCE(SUM(rewrites), 0) as rewrites
	, rules.locationFile
	, rules.locationFrom
	, rules.locationTo
FROM rules 
LEFT OUTER JOIN data ON
	data.locationFile = rules.locationFile
	AND data.locationFrom = rules.locationFrom
	AND data.locationTo = rules.locationTo
	AND data.kind = rules.kind
WHERE 
	NOT rules.locationFile = "common-c-syntax.k"
	AND NOT rules.locationFile = "dynamic-c-standard-lib.k"
	AND NOT rules.locationFile = "dynamic-c-errors.k"
	AND NOT rules.locationFile = "common-c-helpers.k"
	AND (rules.kind = "computational" OR rules.kind = "structural")
GROUP BY
	rules.locationFile,
	rules.locationFrom,
	rules.locationTo,
	rules.kind
ORDER BY
	rewrites DESC