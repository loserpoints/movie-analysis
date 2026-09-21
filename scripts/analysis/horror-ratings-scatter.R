library(tidyverse)
library(ggthemes)
library(extrafont)
library(ggrepel)


loadfonts(device = "win")


### load the shared horror data set

source("scripts/04-horror-base.R")


horror_2020 <- horror %>%
  
  filter(startYear == 2020)


ggplot(horror_2020, aes(numVotes, averageRating, label = primaryTitle)) +
  
  geom_point(size = 4, color = "gray54") +
  
  geom_label_repel(fill = "firebrick4", color = "white", fontface = "bold", family = "Trebuchet MS", segment.color = "gray54") +
  
  geom_vline(xintercept = mean(horror_2020$numVotes), linetype = "dashed", color = "gray54") +
  
  geom_hline(yintercept = mean(horror_2020$averageRating), linetype = "dashed", color = "gray54") +
  
  theme_few() +
  
  xlab("\nNumber of Ratings") +
  
  ylab("Average Rating\n") +
  
  ggtitle("IMDB Horror Movie Ratings 2020", subtitle = "") +
  
  theme(axis.text = element_text(size = 16, face = "bold", family = "Trebuchet MS"),
        axis.title = element_text(size = 18, face = "bold", family = "Trebuchet MS"),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        legend.position = "none")

ggsave(filename = "viz/horror_2020_scatter.png", width = 21.333, height = 10.666)


horror_2019 <- horror %>%
  
  filter(startYear == 2019)

ggplot(horror_2019, aes(numVotes, averageRating, label = primaryTitle)) +
  
  geom_point(size = 4, color = "gray54") +
  
  geom_label_repel(fill = "firebrick4", color = "white", fontface = "bold", family = "Trebuchet MS", segment.color = "gray54") +
  
  geom_vline(xintercept = mean(horror_2019$numVotes), linetype = "dashed", color = "gray54") +
  
  geom_hline(yintercept = mean(horror_2019$averageRating), linetype = "dashed", color = "gray54") +
  
  theme_few() +
  
  xlab("\nNumber of Ratings") +
  
  ylab("Average Rating\n") +
  
  ggtitle("IMDB Horror Movie Ratings 2019", subtitle = "excluding Us and It Chapter Two") +
  
  xlim(0, 75000) +
  
  theme(axis.text = element_text(size = 16, face = "bold", family = "Trebuchet MS"),
        axis.title = element_text(size = 18, face = "bold", family = "Trebuchet MS"),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        legend.position = "none")

ggsave(filename = "viz/horror_2019_scatter_truncated.png", width = 21.333, height = 10.666)
