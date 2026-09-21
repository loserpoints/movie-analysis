library(tidyverse)
library(ggthemes)
library(extrafont)
library(ggrepel)

loadfonts(device = "win")


### load the shared horror data set

source("scripts/04_horror_base.R")


person_name <- "John Carpenter" 


name_id <- imdb_names %>%
  
  filter(primaryName == person_name,
         birthYear != "\\N")


name_id <- name_id$nconst


career <- horror %>%
  
  filter(grepl(name_id, directors))



ggplot(career, aes(startYear, averageRating, label = primaryTitle)) +
  
  geom_hline(yintercept = quantile(horror$averageRating, 0.25) [[1]], linetype = "dashed", color = "dodgerblue3", alpha = 0.6) +
  
  geom_hline(yintercept = quantile(horror$averageRating, 0.50) [[1]], linetype = "dashed", color = "dodgerblue3", alpha = 0.6) +
  
  geom_hline(yintercept = quantile(horror$averageRating, 0.75) [[1]], linetype = "dashed", color = "dodgerblue3", alpha = 0.6) +
  
  geom_line() +
  
  geom_point(size = 4, color = "gray54") +
  
  geom_label_repel(fill = "firebrick4", color = "white", fontface = "bold", family = "Trebuchet MS", segment.color = "gray54") +
  
  theme_few() +
  
  xlab("\nYear") +
  
  ylab("Average Rating\n") +
  
  ggtitle(paste0(person_name, " Career Horror Movie IMDB Ratings"), subtitle = "Guide lines at 25th, 50th, and 75th percentile among horror movies") +
  
  ylim(0, 9) +
  
  theme(axis.text = element_text(size = 16, face = "bold", family = "Trebuchet MS"),
        axis.title = element_text(size = 18, face = "bold", family = "Trebuchet MS"),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        legend.position = "none")

ggsave(filename = paste0("viz/director_career_", gsub("[^a-z0-9]+", "_", tolower(person_name)), ".png"), width = 21.333, height = 10.666)

       