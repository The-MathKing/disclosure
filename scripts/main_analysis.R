# Main Study Analysis Script (N ~ 252)
# Tests the main effects, interaction, and moderated mediation (PROCESS Model 7 or 8)

if (!require("dplyr")) install.packages("dplyr")
if (!require("car")) install.packages("car")
if (!require("emmeans")) install.packages("emmeans")
# Note: To run PROCESS in R, users typically download the macro directly from Andrew Hayes' website 
# and source it: source("process.R"). For the sake of this script, we assume that is done or we use `processR`.

library(dplyr)
library(car)
library(emmeans)

# 1. Load the main data
# data <- read.csv("../data/main_data.csv")

# ==============================================================================
# MOCK DATA GENERATION (for testing the script before real data collection)
# ==============================================================================
set.seed(123)
n_main <- 252

# Disclosure levels: None (1), Assisted (2), Generated (3)
# Product Type: Search (1), Experience (2)
main_data <- data.frame(
  id = 1:n_main,
  disclosure = factor(rep(c("None", "Assisted", "Generated"), each = n_main/3), levels=c("None", "Assisted", "Generated")),
  product = factor(rep(rep(c("Search", "Experience"), each = n_main/6), 3), levels=c("Search", "Experience"))
)

# Generating DVs based on Hypotheses:
# H1: None > Assisted > Generated for Authenticity and Trust
# H2: The penalty is larger for Experience goods

# Base authenticity
main_data$authenticity <- 5.0
# Main effect of disclosure
main_data$authenticity[main_data$disclosure == "Assisted"] <- 4.0
main_data$authenticity[main_data$disclosure == "Generated"] <- 2.5
# Interaction effect for experience good (larger penalty)
main_data$authenticity[main_data$disclosure == "Assisted" & main_data$product == "Experience"] <- 3.0
main_data$authenticity[main_data$disclosure == "Generated" & main_data$product == "Experience"] <- 1.5
# Add noise
main_data$authenticity <- main_data$authenticity + rnorm(n_main, 0, 0.8)

# Trust (highly correlated with authenticity)
main_data$trust <- main_data$authenticity * 0.8 + rnorm(n_main, 1, 0.5)

# Purchase Intention (mediated by authenticity)
main_data$purchase_intent <- main_data$authenticity * 0.6 + rnorm(n_main, 2, 0.7)

# Bound to 1-7 scales
main_data$authenticity <- pmin(pmax(main_data$authenticity, 1), 7)
main_data$trust <- pmin(pmax(main_data$trust, 1), 7)
main_data$purchase_intent <- pmin(pmax(main_data$purchase_intent, 1), 7)

# Save the generated mock data
write.csv(main_data, "../data/main_data.csv", row.names = FALSE)


# ==============================================================================
# ANALYSIS 1: Main Effects & Interaction (Two-Way ANOVA)
# ==============================================================================
cat("\n--- Two-Way ANOVA: Perceived Authenticity ---\n")
# Set contrasts for Type III sums of squares
options(contrasts = c("contr.sum", "contr.poly"))

anova_auth <- lm(authenticity ~ disclosure * product, data = main_data)
print(Anova(anova_auth, type = "III"))

# Simple Main Effects (emmeans) to probe the interaction
cat("\n--- Simple Main Effects (emmeans) ---\n")
em_auth <- emmeans(anova_auth, ~ disclosure | product)
print(pairs(em_auth))

cat("\n--- Plotting Interaction ---\n")
png("../manuscript/figures/main_interaction.png", width=600, height=400)
# Use interaction.plot for base R plotting without emmip dependencies on grid output
interaction.plot(main_data$disclosure, main_data$product, main_data$authenticity,
                 type="b", pch=19, col=c("blue", "red"),
                 xlab="AI Disclosure", ylab="Perceived Authenticity (1-7)",
                 trace.label="Product Type", main="Interaction Effect on Authenticity")
dev.off()


cat("\n--- Two-Way ANOVA: Purchase Intention ---\n")
anova_pi <- lm(purchase_intent ~ disclosure * product, data = main_data)
print(Anova(anova_pi, type = "III"))


# ==============================================================================
# ANALYSIS 2: Moderated Mediation (PROCESS Model 8 logic)
# ==============================================================================
cat("\n--- Moderated Mediation ---\n")
# X = Disclosure (multicategorical), W = Product Type, M = Authenticity, Y = Purchase Intention
# To run this formally using the PROCESS macro:
# process(data=main_data, y="purchase_intent", x="disclosure", m="authenticity", w="product", model=8, mcx=1)

# Doing it step-by-step using standard OLS for transparency:
# Model M (Authenticity)
mod_m <- lm(authenticity ~ disclosure * product, data = main_data)
summary(mod_m)

# Model Y (Purchase Intention)
mod_y <- lm(purchase_intent ~ disclosure * product + authenticity, data = main_data)
summary(mod_y)

cat("\nAnalysis Pipeline Ready. Await real data from Phase 5.\n")
