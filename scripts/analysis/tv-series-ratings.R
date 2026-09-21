### load required packages

library(RMariaDB)
library(tidyverse)
library(scales)
library(LaCroixColoR)


### fetch and format data from local database

movies_db <-
  
  dbConnect(
    MariaDB(),
    user = "root",
    password = Sys.getenv("MOVIES_DB_PASSWORD"),
    dbname = "movies",
    host = "localhost"
  )


series_query <- 
  
  "SELECT * FROM imdb_basics
	INNER JOIN imdb_episodes 
    ON imdb_basics.tconst = imdb_episodes.parentTconst
    INNER JOIN imdb_titles
    ON imdb_episodes.tconst = imdb_titles.tconst
	WHERE primaryTitle = 'Star Trek: The Next Generation'"

series_db <- dbSendQuery(movies_db, series_query)

series <- dbFetch(series_db)

dbClearResult(series_db)


### select specific show

trek_tng <- series %>%
  
  mutate(seasonNumber = as.numeric(seasonNumber),
         episodeNumber = as.numeric(episodeNumber)) %>%
  
  arrange(parentTconst, seasonNumber, episodeNumber) %>%
  
  mutate(episode = row_number()) %>%
  
  group_by(seasonNumber) %>%
  
  mutate(season_rating = mean(averageRating))


### plot show seasons

ggplot(trek_tng, aes(episode, averageRating, color = interaction(seasonNumber, parentTconst), label = episodeNumber)) +
  
  geom_hline(yintercept = mean(trek_tng$averageRating), linetype = "dashed", color = "gray72") +

  geom_line(size = 1, alpha = 0.5) +
  
  geom_line(aes(y = season_rating), size = 2) +
  
  #geom_label(show.legend = F) +
  
  theme_few() +
  
  xlab("\nEpisode Number") +
  
  ylab("Average Rating\n") +
  
  ggtitle("IMDB STAR TREK: THE NEXT GENERATION EPISODE RATINGS", subtitle = "") +
  
  scale_color_manual(values = c(lacroix_palette("PeachPear", n = 7)), 
                     name = "Season",
                     labels = c("1", "2", "3", "4", "5", "6", "7")) +
  
  guides(label = F) +
  
  theme(axis.text = element_text(size = 16, family = "Trebuchet MS", hjust = 0.5),
        axis.title = element_text(size = 18, family = "Trebuchet MS", hjust = 0.5),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        legend.title = element_text(size = 14, family = "Trebuchet MS"),
        legend.text = element_text(size = 12, family = "Trebuchet MS"))


ggsave(filename = "viz/trek_tng.png", width = 21.333, height = 10.666)
