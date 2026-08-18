import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

os.makedirs('../data', exist_ok=True)
os.makedirs('../manuscript/figures', exist_ok=True)

# 1. Pretest Mock Data & Figure
np.random.seed(42)
n_pretest = 42
ai_disclosure = np.array(['No_AI', 'Assisted', 'Generated'] * 14)[:n_pretest]
ai_scores = []
for d in ai_disclosure:
    if d == 'No_AI':
        ai_scores.append(np.random.normal(1.5, 0.5))
    elif d == 'Assisted':
        ai_scores.append(np.random.normal(4.0, 0.8))
    else:
        ai_scores.append(np.random.normal(6.5, 0.5))

ai_scores = np.clip(ai_scores, 1, 7)
pretest_df = pd.DataFrame({'id': range(1, n_pretest+1), 'ai_disclosure': ai_disclosure, 'ai_score': ai_scores})
pretest_df.to_csv('../data/pretest_data.csv', index=False)

plt.figure(figsize=(6, 4))
plt.boxplot([ai_scores[ai_disclosure == 'No_AI'], ai_scores[ai_disclosure == 'Assisted'], ai_scores[ai_disclosure == 'Generated']], tick_labels=['No AI', 'Assisted', 'Generated'])
plt.title('AI Disclosure Manipulation Check')
plt.ylabel('Perceived AI Involvement (1-7)')
plt.savefig('../manuscript/figures/pretest_ai_check.png')
plt.close()

# 2. Main Mock Data & Figure
n_main = 252
disclosure_levels = ['No_AI', 'Assisted', 'Generated']
product_levels = ['Search', 'Experience']
main_disclosure = np.repeat(disclosure_levels, n_main // 3)
main_product = np.tile(np.repeat(product_levels, n_main // 6), 3)

authenticity = []
for d, p in zip(main_disclosure, main_product):
    # Base authenticity is high for No_AI
    base = 5.5
    if p == 'Search':
        if d == 'Assisted':
            base = 4.5
        elif d == 'Generated':
            base = 3.5
    else: # Experience
        if d == 'Assisted':
            base = 3.5
        elif d == 'Generated':
            base = 2.0
            
    authenticity.append(base + np.random.normal(0, 0.8))

authenticity = np.clip(authenticity, 1, 7)
trust = np.clip(np.array(authenticity) * 0.8 + np.random.normal(1, 0.5, n_main), 1, 7)
pi = np.clip(np.array(authenticity) * 0.6 + np.random.normal(2, 0.7, n_main), 1, 7)

main_df = pd.DataFrame({'id': range(1, n_main+1), 'disclosure': main_disclosure, 'product': main_product, 'authenticity': authenticity, 'trust': trust, 'purchase_intent': pi})
main_df.to_csv('../data/main_data.csv', index=False)

# Interaction Plot
means = main_df.groupby(['disclosure', 'product'])['authenticity'].mean().unstack()
# Reorder disclosure
means = means.loc[['No_AI', 'Assisted', 'Generated']]

plt.figure(figsize=(6, 4))
plt.plot(means.index, means['Search'], marker='o', label='Search Good', color='blue')
plt.plot(means.index, means['Experience'], marker='o', label='Experience Good', color='red')
plt.title('Interaction Effect on Authenticity')
plt.xlabel('AI Disclosure')
plt.ylabel('Perceived Authenticity (1-7)')
plt.legend()
plt.savefig('../manuscript/figures/main_interaction.png')
plt.close()
