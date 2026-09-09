# ============================================================
# PROJECT: Heart Disease Classification with Logistic Regression
# AUTHOR: Oluwatobiloba Adenola
# WEBSITE: https://tobiadenola.com
#
# PURPOSE:
# Build and evaluate a logistic regression classifier for
# heart disease using the UCI Heart Disease dataset.
# ============================================================


# 1. LOAD PACKAGES --------------------------------------------------------

library(tidyverse)
library(tidymodels)


# 2. LOAD DATA ------------------------------------------------------------

heart_data <- read_csv(
  "data/heart_disease_uci.csv",
  show_col_types = FALSE
)


# 3. PREPARE OUTCOME ------------------------------------------------------

# Convert the diagnosis variable into a binary classification outcome.
# Values greater than 0 indicate the presence of heart disease.

heart_data <- heart_data %>%
  mutate(
    heart_disease = factor(
      if_else(num > 0, "Disease", "No Disease"),
      levels = c("No Disease", "Disease")
    )
  ) %>%
  select(-num)


# 4. TRAIN / TEST SPLIT ---------------------------------------------------

set.seed(123)

heart_split <- initial_split(
  heart_data,
  prop = 0.80,
  strata = heart_disease
)

heart_train <- training(heart_split)
heart_test <- testing(heart_split)


# 5. PREPROCESSING RECIPE -------------------------------------------------

heart_recipe <- recipe(
  heart_disease ~ .,
  data = heart_train
) %>%
  step_impute_median(all_numeric_predictors()) %>%
  step_impute_mode(all_nominal_predictors()) %>%
  step_dummy(all_nominal_predictors()) %>%
  step_zv(all_predictors())


# 6. SPECIFY LOGISTIC REGRESSION MODEL -----------------------------------

logistic_model <- logistic_reg(
  mode = "classification",
  engine = "glm"
)


# 7. CREATE WORKFLOW ------------------------------------------------------

heart_workflow <- workflow() %>%
  add_recipe(heart_recipe) %>%
  add_model(logistic_model)


# 8. FIT MODEL ------------------------------------------------------------

heart_fit <- fit(
  heart_workflow,
  data = heart_train
)


# 9. GENERATE TEST-SET PREDICTIONS ---------------------------------------

heart_predictions <- predict(
  heart_fit,
  heart_test,
  type = "class"
) %>%
  bind_cols(
    predict(
      heart_fit,
      heart_test,
      type = "prob"
    )
  ) %>%
  bind_cols(
    heart_test %>%
      select(heart_disease)
  )


# 10. MODEL PERFORMANCE ---------------------------------------------------

classification_metrics <- heart_predictions %>%
  metrics(
    truth = heart_disease,
    estimate = .pred_class
  )

print(classification_metrics)


# ROC AUC
roc_auc_result <- heart_predictions %>%
  roc_auc(
    truth = heart_disease,
    .pred_Disease,
    event_level = "second"
  )

print(roc_auc_result)


# 11. CONFUSION MATRIX ----------------------------------------------------

heart_confusion <- heart_predictions %>%
  conf_mat(
    truth = heart_disease,
    estimate = .pred_class
  )

print(heart_confusion)


# 12. SAVE CONFUSION MATRIX FIGURE ---------------------------------------

confusion_plot <- autoplot(
  heart_confusion,
  type = "heatmap"
) +
  labs(
    title = "Heart Disease Classification Confusion Matrix"
  ) +
  theme_minimal()

confusion_plot

ggsave(
  filename = "figures/heart_disease_cm.png",
  plot = confusion_plot,
  width = 7,
  height = 6,
  dpi = 300
)
