# Leaderboards

## Recalculation

To figure out if a Leaderboard needs recalculation, the easiest way is to get
the transaction set that it corresponds to, and compare either the sum or count
of that result set to the sum of the leaderboard values.

This can be done at any time, but if recalculation is needed then ALL
leaderboards newer than one that doesnt match (of the same type) will need
recalculating due to possible position changes, and therefore the trend
changing.
