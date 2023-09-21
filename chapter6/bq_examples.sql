-- SQL queries which are used in Chapter 6 in the book "Low-Code AI"
-- If you wish, you can do a "Find and Replace" to replace your-project-id with your Google Cloud Project.

-- Check for NULL values in Temp column

SELECT 
  IF(Temp IS NULL, 1, 0) AS is_temp_null
FROM
  `your-project-id.data_driven_ml.ccpp_raw`

-- Check for NULL values in all columns

SELECT
  SUM(IF(Temp IS NULL, 1, 0)) AS no_temp_nulls,
  SUM(IF(Exhaust_Vacuum IS NULL, 1, 0)) AS no_ev_nulls,
  SUM(IF(Ambient_Pressure IS NULL, 1, 0)) AS no_ap_nulls,
  SUM(IF(Relative_Humidity IS NULL, 1, 0)) AS no_rh_nulls,
  SUM(IF(Energy_Production IS NULL, 1, 0)) AS no_ep_nulls
FROM
  `your-project-id.data_driven_ml.ccpp_raw`

-- Compute the MIN and MAX values of the Temp column 

SELECT
  MIN(Temp) as min_temp,
  MAX(Temp) as max_temp
FROM
  `your-project-id.data_driven_ml.ccpp_raw`

-- Compute the MIN and MAX values for all columns

SELECT 
  MIN(Temp) as min_temp,
  MAX(Temp) as max_temp,
  MIN(Exhaust_Vacuum) as min_ev,
  MAX(Exhaust_Vacuum) as max_ev,
  MIN(Ambient_Pressure) as min_ap,
  MAX(Ambient_Pressure) as max_ap,
  MIN(Relative_Humidity) as min_rh,
  MAX(Relative_Humidity) as max_rh,
  MIN(Energy_Production) as min_ep,
  MAX(Energy_Production) as max_ep
FROM
  `your-project-id.data_driven_ml.ccpp_raw`

-- Create table for preprocessed data

CREATE TABLE
  `data_driven_ml.ccpp_cleaned`
AS
  SELECT 
    *
  FROM 
    `your-project-id.data_driven_ml.ccpp_raw`
  WHERE
    Temp BETWEEN 1.81 AND 37.11 AND
    Ambient_Pressure BETWEEN 992.89 AND 1033.30 AND
    Relative_Humidity BETWEEN 25.56 AND 100.16 AND
    Exhaust_Vacuum BETWEEN 25.36 AND 81.56 AND
    Energy_Production BETWEEN 420.26 AND 495.76

-- Compute Pearson Correlation coefficient between the Temp and Exhaust_Vacuum columns

SELECT
  CORR(Temp, Exhaust_Vacuum)
FROM
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- Compute Pearson Correlation coefficient between the Temp and other feature columns

SELECT 
  CORR(Temp, Ambient_Pressure) AS corr_t_ap,
  CORR(Temp, Relative_Humidity) AS corr_t_rh,
  CORR(Temp, Exhaust_Vacuum) AS corr_t_ev
FROM 
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- Statement to create a linear regression model in BigQuery ML

CREATE OR REPLACE MODEL data_driven_ml.energy_production 
  OPTIONS(model_type='linear_reg',
          input_label_cols=['Energy_Production']) AS
SELECT
  Temp,
  Ambient_Pressure,
  Relative_Humidity,
  Exhaust_Vacuum,
  Energy_Production
FROM
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- Evaluate the newly trained linear regression model

SELECT
  *
FROM
  ML.EVALUATE(MODEL data_driven_ml.energy_production)

-- Serve a prediction on a single example

SELECT
  *
FROM
  ML.PREDICT(MODEL `your-project-id.data_driven_ml.energy_production`,
    (
    SELECT
      27.45 AS Temp,
      1001.23 AS Ambient_Pressure,
      84 AS Relative_Humidity,
      65.12 AS Exhaust_Vacuum) )

-- Train a linear regression model in BigQuery ML with global explanability enabled

CREATE OR REPLACE MODEL data_driven_ml.energy_production
  OPTIONS(model_type='linear_reg',
          input_label_cols=['Energy_Production'],
          enable_global_explain=TRUE) AS
SELECT
  Temp,
  Ambient_Pressure,
  Relative_Humidity,
  Exhaust_Vacuum,
  Energy_Production
FROM
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- Use the ML.GLOBAL_EXPLAIN function 

SELECT 
  *
FROM
  ML.GLOBAL_EXPLAIN(MODEL `data_driven_ml.energy_production`)

-- Serve predictions with explanations

SELECT
  *
FROM
  ML.EXPLAIN_PREDICT(
    MODEL `your-project-id.data_driven_ml.energy_production`,
    (
    SELECT
      Temp,
      Ambient_Pressure,
      Relative_Humidity,
      Exhaust_Vacuum
    FROM
      `your-project-id.some_dataset.some_table`),
    STRUCT(3 AS top_k_features) )

-- Train a neural network regressor

CREATE OR REPLACE MODEL data_driven_ml.energy_production_nn
  OPTIONS 
    (model_type='dnn_regressor',
     hidden_units=[32,16,8],
     input_label_cols=['Energy_Production']) AS
SELECT
  Temp,
  Ambient_Pressure,
  Relative_Humidity,
  Exhaust_Vacuum,
  Energy_Production
FROM
  `your-project-id.data_driven_ml.ccpp_cleaned`

-- Evaluate the newly trained neural network model

SELECT
  *
FROM
  ML.EVALUATE(MODEL data_driven_ml.energy_production)

-- Serve a prediction on a single example with the neural network model

SELECT
  *
FROM
  ML.PREDICT(MODEL `your-project-id.data_driven_ml.energy_production`,
    (
    SELECT
      27.45 AS Temp,
      1001.23 AS Ambient_Pressure,
      84 AS Relative_Humidity,
      65.12 AS Exhaust_Vacuum) )


