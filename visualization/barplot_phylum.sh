# ==============================================================================
# STEP 0: LOAD LIBRARIES
# ==============================================================================
library(rhdf5)
library(biomformat)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales) # Used for color handling and % formatting

# ==============================================================================
# STEP 1: LOAD DATA
# ==============================================================================

# 1.1 Load Feature Table (HDF5 Format)
biom_path   <- "D:/Microbiome/GCP/Visualization/barplot/feature-table.biom"
biom_object <- read_biom(biom_path)        
asv_table   <- as.matrix(biom_data(biom_object)) 

# 1.2 Load Taxonomy
tax_table <- read.table("D:/Microbiome/GCP/Visualization/barplot/taxonomy.tsv", 
                        header=TRUE, sep="\t", row.names=1, 
                        comment.char="", quote="")

# 1.3 Load Metadata
# Use comment.char="#" to automatically skip the "#q2:types" line if present
metadata <- read.table("D:/Microbiome/GCP/Visualization/metadata.tsv", 
                       header=TRUE, sep="\t", comment.char="#")

# ==============================================================================
# STEP 2: PROCESS TAXONOMY
# ==============================================================================

# Split taxonomy string into 7 levels.
# extra = "drop": Discard extra information at the end (if any)
tax_table_clean <- tax_table %>%
  separate(Taxon, c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species"), 
           sep = ";", fill = "right", extra = "drop")

# Remove excess whitespace and fill "Unassigned" for empty cells
tax_table_clean <- data.frame(lapply(tax_table_clean, trimws), stringsAsFactors = FALSE)
rownames(tax_table_clean) <- rownames(tax_table)
tax_table_clean[is.na(tax_table_clean)] <- "Unassigned"

# ==============================================================================
# STEP 3: MERGE DATA & CALCULATE PERCENTAGES
# ==============================================================================

# Convert ASV table to standard format
asv_df <- as.data.frame(asv_table)
asv_df$FeatureID <- rownames(asv_df)

# Merge table and sum by Phylum
full_data <- asv_df %>%
  pivot_longer(-FeatureID, names_to = "SampleID", values_to = "Count") %>%
  # Join taxonomy names
  inner_join(tax_table_clean %>% mutate(FeatureID = rownames(tax_table_clean)), by = "FeatureID") %>%
  # Aggregate counts by Sample and Phylum
  group_by(SampleID, Phylum) %>%
  summarise(TotalCount = sum(Count), .groups = 'drop') %>%
  # Calculate percentage (Relative Abundance)
  group_by(SampleID) %>%
  mutate(RelativeAbundance = TotalCount / sum(TotalCount)) %>%
  ungroup() %>%
  # Join group information from Metadata
  inner_join(metadata, by = "SampleID")

# ==============================================================================
# STEP 4: FILTER DATA (GROUP SMALL GROUPS < 1% INTO "OTHERS")
# ==============================================================================

# Find phyla with mean relative abundance > 1% (0.01)
keep_phyla <- full_data %>%
  group_by(Phylum) %>%
  summarise(Mean = mean(RelativeAbundance)) %>%
  filter(Mean >= 0.01) %>%
  pull(Phylum)

# Assign "Others <1%" to small phyla and aggregate them
plot_data <- full_data %>%
  mutate(Phylum_Filtered = ifelse(Phylum %in% keep_phyla, Phylum, "Others (<1%)")) %>%
  group_by(SampleID, Phylum_Filtered, group) %>% # 'group' is lowercase matching your file
  summarise(RelativeAbundance = sum(RelativeAbundance), .groups = 'drop')

# ==============================================================================
# STEP 5: PLOT CHART
# ==============================================================================

# Create color palette: Automatic colors for main phyla, Grey for Others
num_colors <- length(unique(plot_data$Phylum_Filtered))
my_colors <- scales::hue_pal()(num_colors)
names(my_colors) <- unique(plot_data$Phylum_Filtered)
if("Others <1%" %in% names(my_colors)) {
  my_colors["Others <1%"] <- "grey90" # Light grey for Others group
}

# Plot the figure
ggplot(plot_data, aes(x = SampleID, y = RelativeAbundance, fill = Phylum_Filtered)) +
  geom_bar(stat = "identity", width = 0.9, color = "black", size = 0.1) + # Add thin black border for aesthetics
  facet_grid(~group, scales = "free_x", space = "free") + 
  scale_fill_manual(values = my_colors) +
  scale_y_continuous(labels = scales::percent, expand = c(0,0)) + # Y-axis starts exactly at the bottom
  theme_bw() +
  labs(y = "Relative Abundance (%)", x = "", fill = "Phylum") +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 10),
    strip.text = element_text(size = 12, face = "bold"), # Bold group names (Human, Soil...)
    legend.title = element_text(face = "bold")
  )
