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

print("\n--- MAIN STUDY: MEDIATION (Model 8) ---")
# Create dummy variables for Disclosure
main['D_Assisted'] = (main['disclosure'] == 'Assisted').astype(int)
main['D_Generated'] = (main['disclosure'] == 'Generated').astype(int)
main['W'] = (main['product'] == 'Experience').astype(int)

# Model M (Authenticity)
mod_m = ols('authenticity ~ D_Assisted + D_Generated + W + D_Assisted:W + D_Generated:W', data=main).fit()
print("Model M Summary:")
print(mod_m.summary())

# Model Y (Purchase Intention)
mod_y = ols('purchase_intent ~ D_Assisted + D_Generated + W + D_Assisted:W + D_Generated:W + authenticity', data=main).fit()
print("\nModel Y Summary:")
print(mod_y.summary())

# Index of Moderated Mediation (IMM) for Generated vs No_AI
a3 = mod_m.params['D_Generated:W']
b = mod_y.params['authenticity']
imm = a3 * b
print(f"\nIndex of Moderated Mediation (Generated vs No_AI): {imm:.4f}")

# Simple bootstrap for IMM CI
import numpy as np
np.random.seed(42)
n_boot = 5000
imm_boot = []
for _ in range(n_boot):
    idx = np.random.choice(main.index, size=len(main), replace=True)
    sample = main.loc[idx]
    m_boot = ols('authenticity ~ D_Assisted + D_Generated + W + D_Assisted:W + D_Generated:W', data=sample).fit()
    y_boot = ols('purchase_intent ~ D_Assisted + D_Generated + W + D_Assisted:W + D_Generated:W + authenticity', data=sample).fit()
    imm_boot.append(m_boot.params['D_Generated:W'] * y_boot.params['authenticity'])

ci_lower, ci_upper = np.percentile(imm_boot, [2.5, 97.5])
print(f"95% Bootstrapped CI for IMM: [{ci_lower:.4f}, {ci_upper:.4f}]")
