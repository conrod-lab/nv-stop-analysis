# Load necessary libraries
library(tidyverse)
library(lme4)
library(brms)
library(ggplot2)
library(corrplot)

# Read the CSV file
data <- read.csv("/Users/venturelab/Downloads/fmri-task/roi_values/roi_values.csv")

# Define the columns to keep as IDs
id_cols <- c("subject_id", "session_id", "SEX", "SES", "SLEEP", "PLE")
value_cols <- setdiff(names(data), id_cols)

# Calculate the correlation matrix
cor_matrix <- cor(data[, value_cols],use="complete.obs")

# Create the heatmap
corrplot(cor_matrix, type = "upper", order = "hclust", 
         title = "Correlation Heatmap")

# Define the columns to pivot longer
value_cols <- setdiff(names(data), id_cols)

# Reshape the data into long format
long_data <- data %>%
  pivot_longer(cols = value_cols, names_to = "roi", values_to = "roi_value")

long_data <- long_data %>%
  mutate(time = as.integer(str_extract(session_id, "\\d+")))

# Show the first few rows of the long format data
head(long_data)

# Replace all instances of 9999 with NA in the dataset
long_data[long_data == 9999] <- NA

#roi_subset <- c("Hippocampus_L", "Hippocampus_R")

roi_subset <- unique(long_data$roi)


brm_model <- brm(
  formula = roi_value ~ roi + SEX + SEX*roi + (1 | subject_id) + (1 | session_id) + (1 | roi),
  data = long_data,
  family = gaussian(),
  chains = 4,
  iter = 2000,
  warmup = 500,
  cores = 4  # Set the number of cores to use
)

# # Calculate predicted values for males
pred_males <- predict(brm_model, newdata = long_data[long_data$SEX == 1, ], re_form = NA)
# 
# # Calculate predicted values for females
pred_females <- predict(brm_model, newdata = long_data[long_data$SEX == 2, ], re_form = NA)
# 
# # Calculate the difference between males and females
difference <- pred_males - pred_females
# 
# 
# # Extract the estimates and standard errors from the model
estimates <- summary(brm_model)$fixed
std_errors <- summary(brm_model)$fixed[, "Std.Error"]

posterior_summary <- posterior_summary(brm_model)
std_errors <- (posterior_summary$97.5 - posterior_summary$Q2.5) / (2 * qnorm(0.975))

effect_sizes <- estimates / std_errors
roi_effects <- data.frame(
  ROI = unique(long_data$roi),
  Effect_Size = effect_sizes)
# # Extract the ROI names and effect sizes
roi_info <- roi_effects[, c("ROI", "Effect_Size.Estimate")]
# 
# # Save the ROI information to a CSV file
write.csv(roi_info, "/Users/venturelab/Downloads/roi_effects.csv", row.names = FALSE)