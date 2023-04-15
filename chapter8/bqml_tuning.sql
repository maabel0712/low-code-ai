## SQL statement in BigQuery to create dataset and load data into tables. Directions for using Console are in Chapter 8

CREATE SCHEMA car_sales_prices OPTIONS(location='US');

LOAD DATA OVERWRITE cars_sales_prices.car_prices_train
  FROM FILES(
    format='CSV',
    uris = ['gs://low-code-ai/chapter_8/car_prices_train.csv']
  );
 
 LOAD DATA OVERWRITE cars_sales_prices.car_prices_valid
  FROM FILES(
    format='CSV',
    uris = ['gs://low-code-ai/chapter_8/car_prices_valid.csv']
  );

LOAD DATA OVERWRITE cars_sales_prices.car_prices_test
  FROM FILES(
    format='CSV',
    uris = ['gs://low-code-ai/chapter_8/car_prices_test.csv']
  );
  
## SQL statement to preprocess and explore a few rows of data.

SELECT
  * EXCEPT (int64_field_0, mmr, odometer, year, condition),
  ML.QUANTILE_BUCKETIZE(odometer,10) OVER() AS odo_bucket,
  ML.QUANTILE_BUCKETIZE(year, 10) OVER() AS year_bucket,
  ML.QUANTILE_BUCKETIZE(condition, 10) OVER() AS cond_bucket,
  ML.FEATURE_CROSS(STRUCT(make,model)) AS make_model,
  ML.FEATURE_CROSS(STRUCT(color,interior)) AS color_interior
FROM
  `car_sales_prices.car_prices_train`
LIMIT 10;

## CREATE MODEL statement for a linear model using the TRANSFORM statement.

CREATE OR REPLACE MODEL
  `car_sales_prices.linear_car_model` 
  TRANSFORM (
    * EXCEPT (int64_field_0, mmr, odometer, year, condition),
    ML.QUANTILE_BUCKETIZE(odometer,10) OVER() AS odo_bucket,
    ML.QUANTILE_BUCKETIZE(year, 10) OVER() AS year_bucket,
    ML.QUANTILE_BUCKETIZE(condition, 10) OVER() AS cond_bucket,
    ML.FEATURE_CROSS(STRUCT(make,model)) AS make_model,
    ML.FEATURE_CROSS(STRUCT(color,interior)) AS color_interior)
  OPTIONS (
    model_type='linear_reg',
    input_label_cols=['sellingprice'],
    data_split_method='NO_SPLIT') AS
SELECT
  *
FROM
  `car_sales_prices.car_prices_train`;

## ML.EVALUATE statement for linear_car_model.

SELECT mean_absolute_error
FROM ML.EVALUATE(MODEL `ddml.linear_car_model`,
    (SELECT * FROM `car_sales_prices.car_prices_valid`))

## ML.PREDICT statement for linear_car_model.

SELECT *
FROM ML.PREDICT(MODEL `ddml.linear_car_model`,
    (SELECT * FROM `car_sales_prices.car_prices_valid`));
    
## CREATE MODEL statement for DNN model.

CREATE OR REPLACE MODEL
  `car_sales_prices.dnn_car_model` 
  TRANSFORM (
    * EXCEPT (int64_field_0, mmr, odometer, year, condition),
    ML.QUANTILE_BUCKETIZE(odometer,10) OVER() AS odo_bucket,
    ML.QUANTILE_BUCKETIZE(year, 10) OVER() AS year_bucket,
    ML.QUANTILE_BUCKETIZE(condition, 10) OVER() AS cond_bucket,
    ML.FEATURE_CROSS(STRUCT(make,model)) AS make_model,
    ML.FEATURE_CROSS(STRUCT(color,interior)) AS color_interior)
  OPTIONS (
    model_type='dnn_regressor',
    hidden_units=[64, 32, 16],
    input_label_cols=['sellingprice'],
    data_split_method='NO_SPLIT') AS
SELECT
  *
FROM
  `car_sales_prices.car_prices_train`;

## Hyperparameter tuning job for DNN in BigQuery ML.

CREATE OR REPLACE MODEL
  `car_sales_prices.dnn_hp_car_model` 
  TRANSFORM (
    * EXCEPT (int64_field_0, mmr, odometer, year, condition),
    ML.QUANTILE_BUCKETIZE(odometer,10) OVER() AS odo_bucket,
    ML.QUANTILE_BUCKETIZE(year, 10) OVER() AS year_bucket,
    ML.QUANTILE_BUCKETIZE(condition, 10) OVER() AS cond_bucket,
    ML.FEATURE_CROSS(STRUCT(make,model)) AS make_model,
    ML.FEATURE_CROSS(STRUCT(color,interior)) AS color_interior)
  OPTIONS (
    model_type='dnn_regressor',
    hidden_units=hparam_candidates([STRUCT([64,32,16]), 
                                    STRUCT([32,16]),
                                    STRUCT([32])]),
    dropout=hparam_range(0,0.8),
    input_label_cols=['sellingprice'],
    num_trials = 10,
    hparam_tuning_objectives=['mean_absolute_error']) 
AS SELECT
  *
FROM
  `car_sales_prices.car_prices_train`;


## Query using ML.TRIAL_INFO to see evaluation metrics for candidate models

SELECT
  *
FROM
  ML.TRIAL_INFO(MODEL `car_sales_prices.dnn_hp_car_model`)






