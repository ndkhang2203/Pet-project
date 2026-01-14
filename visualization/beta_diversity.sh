library(ggplot2)

# header=FALSE is CRITICAL here because your file starts directly with data
data <- read.table("D:/Microbiome/GCP/Visualization/beta_diversity/ordination.txt", header=FALSE, row.names=1)

# Manually name the columns
colnames(data) <- paste0("PC", 1:ncol(data))

# Create the Group column for coloring (extracts "Human" from "Human1")
data$Group <- gsub("[0-9]", "", rownames(data))

# Plot
ggplot(data, aes(x=PC1, y=PC2, color=Group)) +
  geom_point(size=4) +
  theme_bw()
