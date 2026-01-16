# ==============================================================================
# STEP 0: LOAD LIBRARIES
# ==============================================================================
library(ggplot2)
library(dplyr)
library(agricolae, lib.loc = "D:/R/Library") # Essential for generating "a, b, c" letters

# ==============================================================================
# STEP 1: LOAD DATA
# ==============================================================================
my_data <- read.table("D:/Microbiome/GCP/Visualization/alpha_diversity/shannon.tsv", 
                      header = TRUE, 
                      sep = "\t")

# ==============================================================================
# STEP 2: CALCULATE STATISTICS (KRUSKAL-WALLIS)
# ==============================================================================

# 1. Run the Kruskal-Wallis test followed by post-hoc analysis to get letters
# 'group' is your categorical column, 'shannon_entropy' is your value
kw_result <- kruskal(my_data$shannon_entropy, my_data$group, group = TRUE, p.adj = "bonferroni")

# 2. Extract the letters dataframe
# The output of kruskal() puts the groups as row names, let's clean it up
stats_df <- kw_result$groups
stats_df$group <- rownames(stats_df) # Create a column for merging

# 3. Prepare positions for the letters
# We want the letter to appear slightly ABOVE the highest point of each group
max_values <- my_data %>%
  group_by(group) %>%
  summarise(ymax = max(shannon_entropy)) %>%
  ungroup()

# 4. Merge letters with positions
# We join the stats letters with the y-positions
final_stats <- inner_join(max_values, stats_df, by = "group")

# ==============================================================================
# STEP 3: PLOT WITH LETTERS
# ==============================================================================

ggplot(my_data, aes(x = group, y = shannon_entropy, fill = group)) +
  
  # 1. Boxplot & Jitter
  geom_boxplot(alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.2, size = 2, alpha = 0.6) +
  
  # 2. ADD SIGNIFICANCE LETTERS
  # label = groups: This pulls the "a", "b", "c" from the stats_df
  geom_text(data = final_stats, 
            aes(x = group, y = ymax, label = groups), 
            vjust = -0.5,  # Move text slightly up
            size = 5,      # Font size
            fontface = "bold",
            color = "black") + # Keep letters black for readability
  
  # 3. Formatting
  theme_bw() +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) + # Add extra space at top for letters
  labs(y = "Shannon index", x = "Group") +
  theme(legend.position = "none")
