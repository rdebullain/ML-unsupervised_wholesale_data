# Wholesale customer segmentation in R
# Adapted from my earlier Python unsupervised-learning project.
# Run: Rscript wholesale_customer_segmentation.R Wholesale_Data.csv
# Uses only base R and the recommended 'stats' and 'graphics' packages.

args <- commandArgs(trailingOnly = TRUE)
input_file <- if (length(args) >= 1) args[1] else "Wholesale_Data.csv"
if (!file.exists(input_file)) stop("Input CSV not found: ", input_file)

customers <- read.csv(input_file, check.names = FALSE)
spend_cols <- c("Fresh", "Milk", "Grocery", "Frozen",
                "Detergents_Paper", "Delicassen")
required <- c("Channel", "Region", spend_cols)
if (!all(required %in% names(customers))) {
  stop("Missing columns: ", paste(setdiff(required, names(customers)), collapse = ", "))
}
if (anyNA(customers[required])) stop("Missing values in required columns")
if (!all(vapply(customers[required], is.numeric, logical(1)))) {
  stop("Expected numeric channel, region, and spending fields")
}
if (any(as.matrix(customers[spend_cols]) < 0)) {
  stop("Annual spending cannot be negative")
}
if (nrow(customers) < 4) stop("At least four customer records required")

cat("Customers:", nrow(customers), "\n")
cat("Duplicate rows:", sum(duplicated(customers)), "\n\n")
cat("Annual spending summary:\n")
print(summary(customers[spend_cols]))

# Spending is strongly right-skewed. Log transformation reduces the influence
# of extreme values; standardization gives the six categories equal weight.
x <- scale(log1p(customers[spend_cols]))
if (anyNA(x)) stop("At least one spending column has zero variance")

# Compare k=2..6 using average silhouette width, computed without packages.
set.seed(42)
max_k <- min(6L, nrow(x) - 1L)
distances <- as.matrix(dist(x))
silhouette_mean <- function(labels, distances) {
  groups <- sort(unique(labels))
  values <- numeric(length(labels))
  for (i in seq_along(labels)) {
    own <- which(labels == labels[i])
    if (length(own) == 1L) {
      values[i] <- 0  # singleton cluster: silhouette convention
      next
    }
    a <- mean(distances[i, own[own != i]])
    b <- min(vapply(groups[groups != labels[i]], function(g) {
      mean(distances[i, labels == g])
    }, numeric(1)))
    values[i] <- if (max(a, b) == 0) 0 else (b - a) / max(a, b)
  }
  mean(values)
}

k_values <- 2:max_k
scores <- vapply(k_values, function(k) {
  fit <- kmeans(x, centers = k, nstart = 25, iter.max = 100)
  silhouette_mean(fit$cluster, distances)
}, numeric(1))
best_k <- k_values[which.max(scores)]

set.seed(42)
model <- kmeans(x, centers = best_k, nstart = 50, iter.max = 100)
customers$cluster <- factor(model$cluster)

cat("\nMean silhouette width by k:\n")
print(data.frame(k = k_values, mean_silhouette = round(scores, 3)))
cat("Selected clusters:", best_k, "\n")
cat("Cluster sizes:\n")
print(table(customers$cluster))
cat("\nMean annual spending by cluster (original units):\n")
cluster_means <- aggregate(customers[spend_cols],
                           by = list(cluster = customers$cluster), FUN = mean)
cluster_means[spend_cols] <- round(cluster_means[spend_cols], 1)
print(cluster_means)

# PCA is used for a two-dimensional visualization, not to fit the clusters.
pca <- prcomp(x, center = FALSE, scale. = FALSE)
cat("\nVariance explained by PC1 and PC2:\n")
print(round(summary(pca)$importance[2, 1:2], 3))

pdf("wholesale_segmentation_plots.pdf", width = 9, height = 6)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
plot(k_values, scores, type = "b", pch = 19,
     xlab = "Number of clusters (k)", ylab = "Mean silhouette width",
     main = "Cluster selection")
abline(v = best_k, lty = 2, col = "gray50")
palette_cols <- grDevices::hcl.colors(best_k, "Dark 3")
plot(pca$x[, 1], pca$x[, 2], pch = 19,
     col = palette_cols[model$cluster],
     xlab = "Principal component 1", ylab = "Principal component 2",
     main = "Customer segments (PCA)")
legend("topright", legend = paste("Cluster", seq_len(best_k)),
       pch = 19, col = palette_cols, cex = 0.7)
dev.off()

write.csv(customers, "wholesale_customer_clusters.csv", row.names = FALSE)
cat("\nSaved wholesale_customer_clusters.csv and wholesale_segmentation_plots.pdf\n")
cat("Clusters describe spending similarity; they do not establish causes.\n")
