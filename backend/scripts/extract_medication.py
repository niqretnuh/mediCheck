import pandas as pd 
import numpy as np

df = pd.read_csv('product.csv')
new_df = pd.DataFrame(df['PROPRIETARYNAME'].unique())

new_df.to_csv('unique_prod_names.csv', index=False)