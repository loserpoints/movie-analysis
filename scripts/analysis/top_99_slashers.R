library(RMariaDB)
library(rvest)
library(tidyverse)
library(ggthemes)
library(extrafont)

loadfonts(device = "win")


### load the shared horror data set

source("scripts/04_horror_base.R")


### fetch and format data from local database

movies_db <-
  
  dbConnect(
    MariaDB(),
    user = "root",
    password = Sys.getenv("MOVIES_DB_PASSWORD"),
    dbname = "movies",
    host = "localhost"
  )


slasher_tags_query <- 
  
  "
  SELECT imdbId, tag FROM movie_lens_tags 
	
	WHERE tag LIKE '%slasher%'
	
    "

slasher_tags_db <- dbSendQuery(movies_db, slasher_tags_query)

slasher_tags <- dbFetch(slasher_tags_db)

slasher_tags <- slasher_tags %>%
  
  group_by(imdbId, tag) %>%
  
  add_tally() %>%
  
  ungroup() %>%
  
  select(imdbId) %>%
  
  unique() %>%
  
  mutate(tconst = sprintf("tt%07d", imdbId),
         slasher = "y")


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
