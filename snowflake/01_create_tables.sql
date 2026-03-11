CREATE DATABASE IF NOT EXISTS ML_PROJECTS;
USE DATABASE ML_PROJECTS;
CREATE SCHEMA IF NOT EXISTS VOLATILITY;
USE SCHEMA VOLATILITY;

-- Drop the old table and features
DROP TABLE IF EXISTS SPY_FEATURES;
DROP TABLE IF EXISTS SPY_DAILY_PRICES;

-- Recreate to match your actual CSV columns
CREATE OR REPLACE TABLE SPY_DAILY_PRICES (
    Date                          DATE,
    Close                        FLOAT,
    Volume                        BIGINT,
    Open                          FLOAT,
    High                          FLOAT,
    Low                           FLOAT,
    ClosePctChange              FLOAT,
    LowvsPrevClosePctChange  FLOAT,
    HighvsPrevClosePctChange FLOAT,
    HighLowPctChange           FLOAT
);
-- Update the file format to handle MM/DD/YYYY dates
ALTER SESSION SET DATE_INPUT_FORMAT = 'MM/DD/YYYY';

CREATE OR REPLACE FILE FORMAT csv_format
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('');

-- Reload (using whichever stage method you used before)
-- If using internal stage:
-- Create an internal stage
CREATE OR REPLACE STAGE spy_stage FILE_FORMAT = csv_format;

-- Upload via SnowSQL CLI:

-- Or load from S3 (if you upload there first):
-- CREATE OR REPLACE STAGE spy_s3_stage
--     URL = 's3://your-bucket/volatility-forecast/data/raw/'
--     CREDENTIALS = (AWS_KEY_ID='...' AWS_SECRET_KEY='...');

COPY INTO SPY_DAILY_PRICES
    FROM @spy_stage
    FILE_FORMAT = csv_format
    ON_ERROR = 'CONTINUE';
