my_data <- read.table("D:/Microbiome/GCP/Visualization/alpha_diversity/shannon.tsv", 
                      header = TRUE, 
                      sep = "\t")

# Create the plot
ggplot(my_data, aes(x = group, y = shannon_entropy, fill = group)) +
  
  # 1. Add the boxplot layer
  geom_boxplot(alpha = 0.7, outlier.shape = NA) +
  
  # 2. Add individual points (jitter) so you can see sample distribution
  geom_jitter(width = 0.2, size = 2, alpha = 0.6) +
  
  # 3. Add theme
  theme_bw() +
  labs(y = "Shannon index",   
       x = "Group") +         
  
  # 4.Remove the legend
  theme(legend.position = "none")
