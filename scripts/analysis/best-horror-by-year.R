library(tidyverse)
library(ggthemes)
library(extrafont)
library(ggrepel)


loadfonts(device = "win")


### load the shared horror data set

source("scripts/04-horror-base.R")


horror_best <- horror_adj %>%
  
  filter(startYear > 1965, 
         startYear < 2020) %>%
  
  group_by(startYear) %>%
  
  filter(adj_score == max(adj_score))


ggplot(horror_best, aes(startYear, averageRating, label = primaryTitle)) +
  
  geom_line() +
  
  geom_point(size = 4, color = "gray54") +
  
  geom_label_repel(fill = "firebrick4", color = "white", fontface = "bold", family = "Trebuchet MS", segment.color = "gray54") +
  
  theme_few() +
  
  xlab("\nYear") +
  
  ylab("Adjusted Average Rating\n") +
  
  ggtitle("IMDB Top Horror Movie by Year Since 1966", subtitle = "movies ranked using a blended score based on popularity and quality") +
  
  theme(axis.text = element_text(size = 16, face = "bold", family = "Trebuchet MS"),
        axis.title = element_text(size = 18, face = "bold", family = "Trebuchet MS"),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        legend.position = "none")

ggsave(filename = "viz/horror_best_by_year.png", width = 21.333, height = 10.666)