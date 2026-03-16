Note: data sourced from https://www.nasdaq.com/market-activity/etf/spy/historical?page=1&rows_per_page=10&timeline=y1 
# spy-volatility-forecasting
End-to-end ML pipeline: Snowflake feature engineering → AWS SageMaker training → serverless deployment
# SPY Volatility Forecasting Model

End-to-end ML pipeline predicting next-day realized volatility (intraday range %)
for SPY using 10 years of historical price data.

## Architecture
```
Snowflake (feature engineering) → S3 → SageMaker (training + tuning) → Serverless Endpoint
```

## Results

| Metric | Tuned XGBoost | Naive Baseline |
|--------|--------------|----------------|
| RMSE   | 0.6941       | 0.7023         |
| MAE    | 0.3797       | —              |
| R²     | 0.3967       | —              |

**1.2% RMSE improvement** over naive baseline via Bayesian hyperparameter
tuning (20 jobs).

## Pipeline

1. **Data Ingestion** — 10 years of SPY daily OHLCV loaded into Snowflake
2. **Feature Engineering** — 17 features built entirely in Snowflake SQL
   using a 3-CTE pattern (lag extraction → derived features → rolling aggregates)
3. **Time-Based Split** — Train (pre-2024), Validation (Jan–Jun 2024),
   Test (Jul 2024+). No shuffling to prevent data leakage.
4. **Training** — XGBoost via SageMaker built-in algorithm
5. **Hyperparameter Tuning** — Bayesian optimization (20 jobs) across 9
   hyperparameters. Best validation RMSE: 0.3494
6. **Deployment** — Serverless real-time endpoint
7. **Monitoring** — Model Monitor baseline for data drift detection

## Key Features

| Feature | Correlation with Target |
|---------|------------------------|
| AVG_RANGE_5D | 0.66 |
| STDDEV_RETURN_5D | 0.63 |
| AVG_RANGE_20D | 0.57 |
| ABS(DAILY_RETURN_PCT) | 0.53 |
| VOLUME_RATIO_20D | 0.31 |

## Tech Stack

- **Data Warehouse:** Snowflake
- **Storage:** AWS S3
- **ML Platform:** AWS SageMaker (Studio, Training, Tuning, Endpoints, Model Monitor)
- **Algorithm:** XGBoost (SageMaker built-in)
- **Languages:** Python, SQL

## Project Structure
```
├── snowflake/
│   ├── 01_create_tables.sql
│   ├── 02_feature_engineering.sql
│   └── 03_export_splits.sql
├── notebooks/
│   └── volatility_forecast.ipynb
├── images/
│   ├── eda_plots.png
│   └── evaluation_plots.png
└── README.md
```

## Future Improvements

- Add exogenous features (VIX, put/call ratio, economic calendar)
- Incorporate intraday hourly bars for opening range features
- Wrap pipeline in SageMaker Pipelines for automated retraining
- Register features in SageMaker Feature Store
