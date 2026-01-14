# ==============================================================================
# STEP 0: LOAD LIBRARIES
# ==============================================================================
library(rhdf5)
library(biomformat)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales) 

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
tax_table_clean[is.na(tax_table_clean)] <- "Unassigned"

# ==============================================================================
# STEP 3: MERGE DATA & CALCULATE PERCENTAGES (KEEP AS IS)
# ==============================================================================

asv_df <- as.data.frame(asv_table)
asv_df$FeatureID <- rownames(asv_df)

full_data <- asv_df %>%
  pivot_longer(-FeatureID, names_to = "SampleID", values_to = "Count") %>%
  inner_join(tax_table_clean %>% mutate(FeatureID = rownames(tax_table_clean)), by = "FeatureID") %>%
  group_by(SampleID, Phylum) %>%
  summarise(TotalCount = sum(Count), .groups = 'drop') %>%
  group_by(SampleID) %>%
  mutate(RelativeAbundance = TotalCount / sum(TotalCount)) %>%
  ungroup() %>%
  inner_join(metadata, by = "SampleID")

# ==============================================================================
# STEP 4: FILTER DATA (KEEP AS IS)
# ==============================================================================

# Find phyla with mean relative abundance > 1% (0.01)
keep_phyla <- full_data %>%
  group_by(Phylum) %>%
  summarise(Mean = mean(RelativeAbundance)) %>%
  filter(Mean >= 0.01) %>%
  pull(Phylum)

# Assign "Others (<1%)"
plot_data <- full_data %>%
  mutate(Phylum_Filtered = ifelse(Phylum %in% keep_phyla, Phylum, "Others (<1%)")) %>%
  group_by(SampleID, Phylum_Filtered, group) %>% 
  summarise(RelativeAbundance = sum(RelativeAbundance), .groups = 'drop')

# ==============================================================================
# STEP 5: PLOT CHART (CORRECTED COLOR LOGIC)
# ==============================================================================

# 1. Create color palette
unique_phyla <- unique(plot_data$Phylum_Filtered)
num_colors <- length(unique_phyla)
my_colors <- scales::hue_pal()(num_colors)
names(my_colors) <- unique_phyla

# --- FIXED SECTION START ---
# Ensure the spelling matches EXACTLY what was defined in Step 4: "Others (<1%)"
if("Others (<1%)" %in% names(my_colors)) {
  my_colors["Others (<1%)"] <- "grey90" 
}
# --- FIXED SECTION END ---

# 2. Plot the figure
ggplot(plot_data, aes(x = SampleID, y = RelativeAbundance, fill = Phylum_Filtered)) +
  geom_bar(stat = "identity", width = 0.9, color = "black", size = 0.1) + 
  facet_grid(~group, scales = "free_x", space = "free") + 
  scale_fill_manual(values = my_colors) +
  scale_y_continuous(labels = scales::percent, expand = c(0,0)) + 
  theme_bw() +
  labs(y = "Relative Abundance (%)", x = "", fill = "Phylum") +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 10),
    strip.text = element_text(size = 12, face = "bold"), 
    legend.title = element_text(face = "bold")
  )
