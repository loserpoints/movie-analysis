### load required packages

library(RMariaDB)
library(tidyverse)
library(scales)


### load the shared horror data set

source("scripts/04-horror-base.R")


### fetch and format data from local database

movies_db <-
  
  dbConnect(
    MariaDB(),
    user = "root",
    password = Sys.getenv("MOVIES_DB_PASSWORD"),
    dbname = "movies",
    host = "localhost"
  )


horror_director_query <-
  
  "
  
  SELECT * FROM imdb_basics
  
  INNER JOIN imdb_titles
  ON imdb_basics.tconst = imdb_titles.tconst
  
  INNER JOIN imdb_crew
  ON imdb_titles.tconst = imdb_crew.tconst
  
  INNER JOIN imdb_names
  ON imdb_crew.directors = imdb_names.nconst
  
  AND numVotes > 500
  WHERE genres LIKE '%Horror%'
  AND genres NOT LIKE '%Documentary%'
  AND (titleType = 'movie' OR titleType = 'video')
  AND runtimeMinutes > 75

"

horror_director_db <- dbSendQuery(movies_db, horror_director_query)

horror_director <- dbFetch(horror_director_db)

dbClearResult(horror_director_db)


### join director data with adjusted movie ratings

horror_director <-
  
  left_join(horror_director, horror_adj %>% select(tconst, adj_score))


### summarize director data to get summed ratings  

horror_director_totals <- horror_director %>%  
  
  select(primaryName, adj_score) %>%
  
  group_by(primaryName) %>%
  
  add_tally() %>%
  
  mutate(max = max(adj_score)) %>%
  
  summarize_all(mean) %>%
  
  ungroup() %>%
  
  mutate(quality = rescale(adj_score, to = c(0, 10/3)),
         quantity = rescale(n, to = c(0, 10/3)),
         peak = rescale(max, to = c(0, 10/3)),
         total = quantity + quality + peak) %>%
  
  arrange(-total)


### filter aummarized directors data to get top 18 to be included in plot

top_horror_directors <- horror_director_totals %>%
  
  filter(n > 3) %>%
  
  top_n(18)


### filter director data to only include the top 18

top_horror_directors_plot <- horror_director %>%
  
  filter(primaryName %in% top_horror_directors$primaryName) %>%
  
  mutate(startYear = as.numeric(startYear),
         primaryName = factor(primaryName, levels = top_horror_directors$primaryName))


### create data frame to use for labeling

top_horror_directors_plot_labels <- top_horror_directors_plot %>%
  
  group_by(primaryName) %>%
  
  mutate(mean_adj_score = mean(adj_score)) %>%
  
  filter(adj_score == max(adj_score))


### create function to force integer breaks on plot

int_breaks <-
  function(x, n = 5)
    pretty(x, n)[pretty(x, n) %% 1 == 0]


### plot top 18 director densities with labels

ggplot(top_horror_directors_plot, aes(adj_score, fill = n)) +
  
  facet_wrap(~primaryName, nrow = 3) +
  
  geom_density(aes(y = ..count..)) +
  
  geom_text(data = top_horror_directors_plot_labels,
            aes(
              x = 5,
              y = 7,
              label = paste0
              (
                "Horror Movies Directed: ",
                round(n),
                "\n",
                "Average Score: ",
                round(mean_adj_score, 2),
                "\n",
                "Best: ",
                primaryTitle
              )
            )) +
  
  theme_few() +
  
  xlab("\nAdjusted Score") +
  
  ylab("Count\n") +
  
  ggtitle("BEST HORROR DIRECTORS",
          subtitle = "Based on quality and quantity of horror movies, data via IMDB\n") +
  
  scale_fill_gradient2(high = "firebrick3", low = "darkorchid4", mid = "gray93", limits = c(0, 24), midpoint = 11, name = "# of Horror Movies Directed\n") +
  
  scale_x_continuous(breaks = int_breaks, limits = c(0, 10)) +
  
  theme(axis.text = element_text(size = 16, face = "bold", family = "Trebuchet MS"),
        axis.title = element_text(size = 18, face = "bold", family = "Trebuchet MS"),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        strip.text = element_text(size = 16, family = "Trebuchet MS"),
        legend.position = "bottom",
        legend.title = element_text(size = 14, family = "Trebuchet MS"),
        legend.text = element_text(size = 12, family = "Trebuchet MS"),
        legend.key.width = unit(1.5, "cm"))

ggsave(filename = "viz/horror_directors.png", width = 21.333, height = 10.666)
