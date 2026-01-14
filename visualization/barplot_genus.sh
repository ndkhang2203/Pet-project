# ==============================================================================
# STEP 0: LOAD LIBRARIES
# ==============================================================================
library(rhdf5)
library(biomformat)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
library(RColorBrewer) 

# ==============================================================================
# STEP 1: LOAD DATA (KEEP AS IS)
# ==============================================================================

# 1.1 Load Feature Table
biom_path   <- "D:/Microbiome/GCP/Visualization/barplot/feature-table.biom"
biom_object <- read_biom(biom_path)        
asv_table   <- as.matrix(biom_data(biom_object)) 

# 1.2 Load Taxonomy
tax_table <- read.table("D:/Microbiome/GCP/Visualization/barplot/taxonomy.tsv", 
                        header=TRUE, sep="\t", row.names=1, 
                        comment.char="", quote="")

# 1.3 Load Metadata
metadata <- read.table("D:/Microbiome/GCP/Visualization/metadata.tsv", 
                       header=TRUE, sep="\t", comment.char="#")

# ==============================================================================
# STEP 2: PROCESS TAXONOMY (KEEP AS IS)
# ==============================================================================

tax_table_clean <- tax_table %>%
  separate(Taxon, c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species"), 
           sep = ";", fill = "right", extra = "drop")

tax_table_clean <- data.frame(lapply(tax_table_clean, trimws), stringsAsFactors = FALSE)
rownames(tax_table_clean) <- rownames(tax_table)

is_bad_name <- function(x) {
  is.na(x) | x == "" | x == "Unassigned" | x == "uncultured" | x == "Incertae_sedis" | grepl("__$", x)
}

tax_table_clean <- tax_table_clean %>%
  mutate(
    Genus_Final = case_when(
      !is_bad_name(Genus) ~ Genus,
      is_bad_name(Genus) & !is_bad_name(Family) ~ paste0("f__", Family),
      is_bad_name(Genus) & is_bad_name(Family) & !is_bad_name(Order) ~ paste0("o__", Order),
      TRUE ~ "Unclassified_Bacteria"
    )
  )

# ==============================================================================
# STEP 3: MERGE DATA & CALCULATE PERCENTAGES (KEEP AS IS)
# ==============================================================================

asv_df <- as.data.frame(asv_table)
asv_df$FeatureID <- rownames(asv_df)

full_data <- asv_df %>%
  pivot_longer(-FeatureID, names_to = "SampleID", values_to = "Count") %>%
  inner_join(tax_table_clean %>% mutate(FeatureID = rownames(tax_table_clean)), by = "FeatureID") %>%
  group_by(SampleID, Genus_Final) %>%
  summarise(TotalCount = sum(Count), .groups = 'drop') %>%
  group_by(SampleID) %>%
  mutate(RelativeAbundance = TotalCount / sum(TotalCount)) %>%
  ungroup() %>%
  inner_join(metadata, by = "SampleID")

# ==============================================================================
# STEP 4: FILTER DISPLAY LIST (CHANGE TO MATCH QIIME2)
# ==============================================================================

# Instead of group-wise, we take the global Top 30-40 to better visualize diversity
# This number is large enough to limit the "Others" group but can still be drawn in R
number_of_taxa <- 30 

top_taxa_list <- full_data %>%
  group_by(Genus_Final) %>%
  summarise(Mean_Abundance = mean(RelativeAbundance)) %>%
  arrange(desc(Mean_Abundance)) %>%
  slice(1:number_of_taxa) %>%
  pull(Genus_Final)

# Assign "Others" group
plot_data <- full_data %>%
  mutate(Genus_Filtered = ifelse(Genus_Final %in% top_taxa_list, Genus_Final, "Others (<1%)")) %>%
  group_by(SampleID, Genus_Filtered, group) %>% 
  summarise(RelativeAbundance = sum(RelativeAbundance), .groups = 'drop')

# Sort order: Others at the bottom, common species on top
plot_data$Genus_Filtered <- factor(plot_data$Genus_Filtered, 
                                   levels = c("Others (<1%)", rev(top_taxa_list)))

# ==============================================================================
# STEP 5: PLOT CHART (REMOVE TITLE & SUBTITLE)
# ==============================================================================

# 1. Create large color palette (enough for 30 species)
# Combine multiple palettes for good contrast
getPalette <- colorRampPalette(c(brewer.pal(12, "Paired"), brewer.pal(8, "Set2"), brewer.pal(8, "Dark2")))
my_colors <- getPalette(length(top_taxa_list))
names(my_colors) <- top_taxa_list

# Color for Others (pale grey)
final_colors <- c(my_colors, "Others (<1%)" = "#E0E0E0") 

# 2. Plot figure
ggplot(plot_data, aes(x = SampleID, y = RelativeAbundance, fill = Genus_Filtered)) +
  
  # --- IMPORTANT: size = 0 to remove black borders ---
  # This helps small proportion species show color clearly instead of being obscured
  geom_bar(stat = "identity", width = 0.95, size = 0) + 
  
  facet_grid(~group, scales = "free_x", space = "free") + 
  
  scale_fill_manual(values = final_colors) +
  scale_y_continuous(labels = scales::percent, expand = c(0,0)) + 
  
  theme_bw() +
  # --- MODIFICATION START: Removed 'title' and 'subtitle' arguments ---
  labs(y = "Relative Abundance (%)", x = "", fill = "Genus") +
  # --- MODIFICATION END ---
  
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 10),
    
    # Adjust legend to be compact because the list is long
    legend.position = "right",
    legend.text = element_text(size = 8), 
    legend.key.size = unit(0.4, "cm"),
    
    # Remove grid background
    panel.grid = element_blank(),
    strip.background = element_rect(fill="white", color="black"),
    strip.text = element_text(face="bold", size=12)
  ) +
  
  # Split legend into 1 vertical column for readability
  guides(fill = guide_legend(ncol = 1))
