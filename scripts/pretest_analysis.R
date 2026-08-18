# Pretest Analysis Script (N ~ 40)
# Validates the product typology and AI disclosure manipulation checks

# Install required packages if missing
if (!require("dplyr")) install.packages("dplyr")
if (!require("car")) install.packages("car")

library(dplyr)
library(car)

# 1. Load the pretest data
# Replace with actual file path once data is collected from Prolific/Qualtrics
# pretest_data <- read.csv("../data/pretest_data.csv")

# ==============================================================================
# MOCK DATA GENERATION (for testing the script before real data collection)
# ==============================================================================
set.seed(42)
n_pretest <- 40
pretest_data <- data.frame(
  id = 1:n_pretest,
  product_type = factor(rep(c("Search", "Experience"), each = n_pretest/2)),
  ai_disclosure = factor(rep(rep(c("None", "Assisted", "Generated"), length.out = n_pretest/2), 2)),
  # Manipulate the typoloy check (1 = Search, 7 = Experience)
  typology_score = c(rnorm(n_pretest/2, mean = 2.5, sd = 1), rnorm(n_pretest/2, mean = 5.5, sd = 1)),
  # Manipulate the AI involvement check (1 = Human, 4 = Assisted, 7 = Generated)
  ai_score = NA
)

# Populate mock AI scores based on condition
pretest_data$ai_score[pretest_data$ai_disclosure == "None"] <- rnorm(sum(pretest_data$ai_disclosure == "None"), 1.5, 0.5)
pretest_data$ai_score[pretest_data$ai_disclosure == "Assisted"] <- rnorm(sum(pretest_data$ai_disclosure == "Assisted"), 4.0, 0.8)
pretest_data$ai_score[pretest_data$ai_disclosure == "Generated"] <- rnorm(sum(pretest_data$ai_disclosure == "Generated"), 6.5, 0.5)

# Ensure scores stay within 1-7 scale bounds
pretest_data$typology_score <- pmin(pmax(pretest_data$typology_score, 1), 7)
pretest_data$ai_score <- pmin(pmax(pretest_data$ai_score, 1), 7)

# Save the generated mock data
write.csv(pretest_data, "../data/pretest_data.csv", row.names = FALSE)

# ==============================================================================
# ANALYSIS 1: Product Typology Check
# ==============================================================================
cat("\n--- Product Typology Manipulation Check ---\n")
# We expect the Experience good to have a significantly higher score than the Search good
t_test_typology <- t.test(typology_score ~ product_type, data = pretest_data)
print(t_test_typology)

# Calculate means and SDs
typology_summary <- pretest_data %>%
  group_by(product_type) %>%
  summarise(Mean = mean(typology_score), SD = sd(typology_score), N = n())
print(typology_summary)

# ==============================================================================
# ANALYSIS 2: AI Disclosure Involvement Check
# ==============================================================================
cat("\n--- AI Disclosure Manipulation Check ---\n")
# We expect an ordinal progression: None < Assisted < Generated
anova_ai <- aov(ai_score ~ ai_disclosure, data = pretest_data)
summary(anova_ai)

# Post-hoc comparisons to ensure each level is distinct from the others
tukey_ai <- TukeyHSD(anova_ai)
print(tukey_ai)

# Calculate means and SDs
ai_summary <- pretest_data %>%
  group_by(ai_disclosure) %>%
  summarise(Mean = mean(ai_score), SD = sd(ai_score), N = n()) %>%
  arrange(factor(ai_disclosure, levels = c("None", "Assisted", "Generated")))
print(ai_summary)

cat("\n--- Plotting AI Disclosure Manipulation Check ---\n")
png("../manuscript/figures/pretest_ai_check.png", width=600, height=400)
boxplot(ai_score ~ ai_disclosure, data = pretest_data, 
        main="AI Disclosure Manipulation Check",
        xlab="Disclosure Level", ylab="Perceived AI Involvement (1-7)",
        col=c("lightblue", "lightgreen", "lightpink"))
dev.off()

cat("\n--- Pretest Analysis Complete ---\n")
# If t-test p < .05 and Tukey post-hocs are all p < .05, the manipulations are successful.
