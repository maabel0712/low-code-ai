# Uncomment the following line if you're running the code in a Jupyter Notebook
# %%writefile trainer/trainer.py

import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler, OneHotEncoder
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (confusion_matrix, precision_score,
                             recall_score, precision_recall_curve,
                             accuracy_score)


df_raw = pd.read_csv("/gcs/low-code-ai-book/churn_dataset.csv")
df_1 = df_raw.replace({'TotalCharges': {' ': 0.0}})
df_2 = df_1.astype({'TotalCharges':'float64'})

df_2['AvgMonthlyCharge'] = df_2['TotalCharges']/df_2['tenure']
df_2['DiffCharges']=df_2['MonthlyCharges']-df_2['AvgMonthlyCharge']

df_3 = df_2.copy()
df_prep = df_3.drop(columns=['AvgMonthlyCharge', 'gender','StreamingTV',
                          'StreamingMovies','PhoneService',                     
                          'customerID'])

numeric_columns = ['SeniorCitizen', 'tenure', 'MonthlyCharges']
categorical_columns = ['Partner', 'Dependents', 'MultipleLines',
                      'InternetService','OnlineSecurity',
                      'OnlineBackup', 'DeviceProtection',     
                      'TechSupport','Contract',
                      'PaperlessBilling','PaymentMethod']

X_num = df_prep[numeric_columns]
X_cat = df_prep[categorical_columns]

ohe = OneHotEncoder(drop='if_binary')
X_cat_trans = ohe.fit_transform(X_cat)

X = np.concatenate((X_num.values,X_cat_trans.toarray()), axis=1)
y = df_prep['Churn'].values

X_train, X_test, y_train, y_test = train_test_split(X,y,test_size=0.20, 
                                                    random_state=113)

scaler = MinMaxScaler()
X_train_scaled = scaler.fit_transform(X_train)

cls = LogisticRegression()

cls.fit(X_train_scaled, y_train)

X_test_scaled = scaler.transform(X_test)
y_pred = cls.predict(X_test_scaled)

print('Accuracy:', accuracy_score(y_test, y_pred))
print('Precision:', precision_score(y_test, y_pred, labels=['Yes','No'], 
                                   pos_label='Yes'))
print('Recall:',recall_score(y_test, y_pred, labels=['Yes','No'],
                   pos_label='Yes'))

joblib.dump(cls, '/gcs/<YOUR-BUCKET-NAME>/sklearn_model.joblib')
