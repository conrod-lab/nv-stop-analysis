# Load necessary libraries
library(tidyverse)
library(lme4)
library(brms)
library(ggplot2)
library(corrplot)

# Read the CSV file
data <- read.csv("roi_values.csv")

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


# brm_model <- brm(
#   formula = roi_value ~ roi + SEX + SEX*roi + (1 | subject_id) + (1 | session_id) + (1 | roi),
#   data = long_data,
#   family = gaussian(),
#   chains = 4,
#   iter = 2000,
#   warmup = 500,
#   cores = 4  # Set the number of cores to use
# )

# # Calculate predicted values for males
# pred_males <- predict(brm_model, newdata = long_data[long_data$SEX == 1, ], re_form = NA)
# 
# # Calculate predicted values for females
# pred_females <- predict(brm_model, newdata = long_data[long_data$SEX == 2, ], re_form = NA)
# 
# # Calculate the difference between males and females
# difference <- pred_males - pred_females
# 
# 
# # Extract the estimates and standard errors from the model
# estimates <- summary(brm_model)$fixed
# std_errors <- summary(brm_model)$fixed[, "Std.Error"]
# 
# # Calculate Cohen's d for each ROI
# effect_sizes <- estimates / std_errors
# 
# # Create a data frame to store the results
# roi_effects <- data.frame(
#   ROI = unique(long_data$roi),
#   Effect_Size = effect_sizes
# )
# 
# 
# # Extract the ROI names and effect sizes
# roi_info <- roi_effects[, c("ROI", "Effect_Size")]
# 
# # Save the ROI information to a CSV file
# write.csv(roi_info, "roi_effects.csv", row.names = FALSE)


# Loop over each ROI and run the model
# Initialize an empty data frame to store results
sleep_roi_tvalue <- data.frame(ROI = character(), T_Value = numeric(), stringsAsFactors = FALSE)

# Loop over each ROI and run the model
for (roi in roi_subset) {
  # Subset the data for the current ROI
  roi_data <- filter(long_data, roi == !!roi)
  
  # Define the formula
  formula <- paste("roi_value ~ SEX + session_id + SES + SLEEP + (1 + session_id| subject_id)")
  
  # Fit the linear mixed-effects model
  model <- lmer(as.formula(formula), data = roi_data)
  
  # Extract the t-value for the SLEEP variable
  sleep_tvalue <- summary(model)$coefficients[,"t value"]["SLEEP"]
  sleep_pvalue <- summary(model)$coefficients[, "Pr(>|t|)"]["SLEEP"]
  
  if (sleep_pvalue < 0.05) {
    cat("ROI:", roi, "\n")
    cat("P-value for sleep:", sleep_pvalue, "\n")  
  }
  # Print the ROI name
  #cat("ROI:", roi, "\n")
  #cat("T-value for sleep:", sleep_tvalue, "\n")  
  # Summarize the model
  #print(summary(model))
  
  # Add ROI name and associated t-value to the data frame
  sleep_roi_tvalue <- rbind(sleep_roi_tvalue, data.frame(ROI = roi, T_Value = sleep_tvalue, P_Value = sleep_pvalue))
}


write.csv(sleep_roi_tvalue, "sleep_roi_tvalues_2.csv", row.names = FALSE)
