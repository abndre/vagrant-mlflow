# Vagrant MLFLOW

Repository to user mlflow with vagrant and apply in production.


## Comando to run in terminal
```
mlflow server --backend-store-uri postgresql://mlflow:mlflow@localhost/mlflow --host 0.0.0.0 --default-artifact-root file:/opt/mlflow/mlruns
```