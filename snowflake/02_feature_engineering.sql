CREATE OR REPLACE TABLE SPY_FEATURES AS

WITH lags AS (
    SELECT
        date, open, high, low, close, volume,
        LAG(close, 1) OVER (ORDER BY date) AS prev_close_1,
        LAG(close, 2) OVER (ORDER BY date) AS prev_close_2,
        LAG(close, 3) OVER (ORDER BY date) AS prev_close_3,
        LAG(close, 4) OVER (ORDER BY date) AS prev_close_4,
        LAG(close, 5) OVER (ORDER BY date) AS prev_close_5,
        LAG(close, 20) OVER (ORDER BY date) AS prev_close_20,
        LEAD((high - low) / NULLIF(close, 0) * 100, 1) OVER (ORDER BY date)
            AS target_next_day_range_pct
    FROM SPY_DAILY_PRICES
),

daily AS (
    SELECT
        date, open, high, low, close, volume,
        target_next_day_range_pct,
        (close - prev_close_1) / NULLIF(prev_close_1, 0) * 100 AS daily_return_pct,
        (open - prev_close_1) / NULLIF(prev_close_1, 0) * 100 AS overnight_gap_pct,
        (high - low) / NULLIF(close, 0) * 100 AS intraday_range_pct,
        CASE WHEN high = low THEN 0.5 ELSE (close - low) / (high - low) END AS close_location_in_range,
        (high - prev_close_1) / NULLIF(prev_close_1, 0) * 100 AS high_vs_prev_close_pct,
        (low - prev_close_1) / NULLIF(prev_close_1, 0) * 100 AS low_vs_prev_close_pct,
        (close - prev_close_5) / NULLIF(prev_close_5, 0) * 100 AS return_5d,
        (close - prev_close_20) / NULLIF(prev_close_20, 0) * 100 AS return_20d,
        CASE WHEN prev_close_1 < prev_close_2 THEN 1 ELSE 0 END
      + CASE WHEN prev_close_2 < prev_close_3 THEN 1 ELSE 0 END
      + CASE WHEN prev_close_3 < prev_close_4 THEN 1 ELSE 0 END AS down_days_last_3,
        DAYOFWEEK(date) AS day_of_week,
        MONTH(date) AS month_of_year
    FROM lags
),

features AS (
    SELECT *,
        AVG(intraday_range_pct) OVER (ORDER BY date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS avg_range_5d,
        AVG(intraday_range_pct) OVER (ORDER BY date ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING) AS avg_range_10d,
        AVG(intraday_range_pct) OVER (ORDER BY date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS avg_range_20d,
        STDDEV(daily_return_pct) OVER (ORDER BY date ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING) AS stddev_return_5d,
        STDDEV(daily_return_pct) OVER (ORDER BY date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING) AS stddev_return_20d,
        volume::FLOAT / NULLIF(AVG(volume) OVER (ORDER BY date ROWS BETWEEN 20 PRECEDING AND 1 PRECEDING), 0) AS volume_ratio_20d
    FROM daily
)

SELECT *
FROM features
WHERE target_next_day_range_pct IS NOT NULL
  AND daily_return_pct IS NOT NULL
  AND avg_range_20d IS NOT NULL
ORDER BY date;