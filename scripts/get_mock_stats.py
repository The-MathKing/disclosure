import pandas as pd
import scipy.stats as stats
import statsmodels.api as sm
from statsmodels.formula.api import ols

# 1. Pretest Data
pretest = pd.read_csv('../data/pretest_data.csv')
pretest['ai_disclosure'] = pretest['ai_disclosure'].astype('category')
print("--- PRETEST ---")
means = pretest.groupby('ai_disclosure')['ai_score'].agg(['mean', 'std', 'count'])
print(means)
anova_pre = ols('ai_score ~ C(ai_disclosure)', data=pretest).fit()
aov_table_pre = sm.stats.anova_lm(anova_pre, typ=2)
print(aov_table_pre)

# 2. Main Data
main = pd.read_csv('../data/main_data.csv')
main['disclosure'] = main['disclosure'].astype('category')
main['product'] = main['product'].astype('category')

print("\n--- MAIN STUDY: AUTHENTICITY ---")
means_main = main.groupby(['product', 'disclosure'])['authenticity'].agg(['mean', 'std', 'count'])
print(means_main)

anova_main = ols('authenticity ~ C(disclosure) * C(product)', data=main).fit()
aov_table_main = sm.stats.anova_lm(anova_main, typ=2)
# Calculate partial eta squared
aov_table_main['eta_sq'] = aov_table_main['sum_sq'] / (aov_table_main['sum_sq'] + aov_table_main.loc['Residual', 'sum_sq'])
print(aov_table_main)

print("\n--- MAIN STUDY: MEDIATION (OLS step) ---")
# M on X
mod_m = ols('authenticity ~ C(disclosure) * C(product)', data=main).fit()
print("R-squared for M:", mod_m.rsquared)

# Y on X + M
mod_y = ols('purchase_intent ~ C(disclosure) * C(product) + authenticity', data=main).fit()
print("Authenticity coefficient on Y:", mod_y.params['authenticity'])
print("p-value:", mod_y.pvalues['authenticity'])
print("Confidence interval:", mod_y.conf_int().loc['authenticity'])
