library(tidyverse)
library(ggthemes)
library(extrafont)

if (.Platform$OS.type == "windows") loadfonts(device = "win")


### load the shared horror data set

source("scripts/03_horror_base.R")


### fetch and format data from local database

source("scripts/00_get_data.R")

movies_db <- connect_movies_db(movielens = TRUE)


### find the slashers
###
### a movie counts as a slasher if the movielens tag genome gives it a
### "slasher" relevance of 0.7 or more. that keeps out movies only one or
### two people tagged as slashers, like the silence of the lambs (0.09),
### and gory horror the genome sees as close to slasher, like hellraiser
### (0.69). saw (0.72) gets in, as all its sequels do.
### the genome stops in 2019, so a movie it doesn't score counts if at
### least two people tagged it slasher, which brings in newer ones like x.

slasher_query <- 
  
  "
  WITH genome_movies AS (
    SELECT DISTINCT movieId FROM movie_lens_genome_scores
  ),
  
  by_genome AS (
    SELECT movie_lens_genome_scores.movieId
    FROM movie_lens_genome_scores
    INNER JOIN movie_lens_genome_tags
      ON movie_lens_genome_tags.tagId = movie_lens_genome_scores.tagId
    WHERE movie_lens_genome_tags.tag = 'slasher'
      AND movie_lens_genome_scores.relevance >= 0.7
  ),
  
  by_tags AS (
    SELECT movieId
    FROM movie_lens_tags
    WHERE tag ILIKE '%slasher%'
      AND movieId NOT IN (SELECT movieId FROM genome_movies)
    GROUP BY movieId
    HAVING count(DISTINCT userId) >= 2
  )
  
  SELECT DISTINCT movie_lens_links.imdbId
  FROM movie_lens_links
  WHERE movieId IN (SELECT movieId FROM by_genome UNION SELECT movieId FROM by_tags)
  
    "

slasher_tags <- dbGetQuery(movies_db, slasher_query) %>%
  
  mutate(tconst = sprintf("tt%07d", imdbId),
         slasher = "y")

dbDisconnect(movies_db, shutdown = TRUE)


### join slasher list with imdb horror films and then filter for only slashers

slashers <- horror_adj %>%
  
  left_join(., slasher_tags, by = c("tconst" = "tconst")) %>%

  filter(grepl("y", slasher)) %>%
  
  arrange(-adj_score)


### format data for plotting


best_slashers <- slashers %>%
  
  top_n(99, adj_score) %>%
  
  select(primaryTitle, startYear, popularity, quality) %>%
  
  mutate(rank = row_number(),
         facet = ifelse(rank < 34, 1, 
                        ifelse(rank < 67, 2, 3))) %>%
  
  mutate(label = paste0(rank, " - ", primaryTitle, " (", startYear, ")")) %>%
  
  arrange(-rank) %>%
  
  mutate(label = factor(label, levels = label))


ggplot(best_slashers, aes(-rank, y = 1, label = label)) +
  
  facet_wrap(~facet, scales = "free") +
  
  geom_tile(stat = "identity", fill = "dodgerblue3", alpha = 0.2) +
  
  geom_text(size = 5, family = "Trebuchet MS") +
  
  theme_few() +
  
  coord_flip() +
  
  xlab("") +
  
  ylab("") +
  
  ggtitle("IMDB Top 99 Slasher Flicks", subtitle = "movies ranked using a blended score based on popularity and quality | slashers identified based on movielens tags") +
  
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        strip.background = element_blank(),
        strip.text = element_blank())

ggsave(filename = "viz/top_99_slashers.png", height = 10.666, width = 21.333)
