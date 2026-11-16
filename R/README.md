# Wholesale Customer Segmentation in R

This project adapts my earlier [Python unsupervised-learning analysis](../notebooks) to R. It explores whether wholesale customers can be grouped by similar annual spending patterns across six product categories: Fresh, Milk, Grocery, Frozen, Detergents/Paper, and Delicatessen.

## Files

- `wholesale_customer_segmentation.R` — data validation, preprocessing, K-means clustering, model selection, PCA, and output generation
- `Wholesale_Data.csv` — input data (440 customer records)
- `wholesale_customer_clusters.csv` — generated customer-level cluster assignments (created when the script runs)
- `wholesale_segmentation_plots.pdf` — generated silhouette-score and PCA plots (created when the script runs)

## How to run

Requires R (tested locally with R 4.6.2); no additional R packages are required.

From this folder, run:

```sh
Rscript wholesale_customer_segmentation.R Wholesale_Data.csv
```

The script writes the two output files above into the current working directory.

## Methods

1. Validate the required fields, missing values, duplicate rows, and nonnegative spending amounts.
2. Apply `log1p` to reduce the effect of highly skewed spending values, then standardize the six spending variables.
3. Fit K-means models for 2–6 clusters and compare mean silhouette widths.
4. Fit the selected K-means model using multiple random starts and a fixed random seed.
5. Summarize average spending in the original units for each segment.
6. Use principal component analysis (PCA) to visualize clusters in two dimensions.

Channel and Region are retained in the source data but excluded from clustering so segments reflect spending patterns.

## Results

The run on 440 customers selected **two clusters** (mean silhouette width **0.290**, higher than the other candidate solutions):

| Metric | Cluster 1 | Cluster 2 |
| --- | ---: | ---: |
| Customers | 188 | 252 |
| Fresh | 9,355.9 | 13,973.1 |
| Milk | 10,346.4 | 2,401.8 |
| Grocery | 14,697.1 | 2,918.7 |
| Frozen | 2,222.5 | 3,705.7 |
| Detergents/Paper | 6,084.5 | 491.9 |
| Delicatessen | 2,177.4 | 1,038.0 |

Cluster 1 has higher average spending on milk, groceries, and detergents/paper; Cluster 2 has higher average spending on fresh and frozen products. The first two principal components explain **71.3%** of the transformed variables' total variance.

The silhouette score indicates modest rather than strong separation, so these groups should be treated as exploratory customer segments, not definitive customer types or causal explanations.

## Reproducibility

This script uses base R and recommended R packages only, sets a random seed for clustering, and outputs both the customer assignments and the visualization PDF. The input file must be in the working directory or provided by path.
