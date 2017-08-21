# Leaderboards

## Calculation

The leaderboards are calculated for the previous range - so Daily leaderboards
are calculated for the whole of the day before, Weeks from the week before,
etc. - The only exception is all time, which is calculated from 00:00 on the
current day.

## Recalculation

Leaderboard recalculation only affects the latest two leaderboards for any set,
so just need to recalculate the last one and the current one, in that order.
This can be done during the regular leaderboard calculation cronjob, so
verified transactions will show up in the leaderboards the next day.

