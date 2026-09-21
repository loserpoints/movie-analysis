library(tidyverse)
library(ggthemes)
library(extrafont)


loadfonts(device = "win")


best_ever <- horror_adj %>%
  
  filter(startYear >= 1960) %>%
  
  arrange(-adj_score) %>%
  
  top_n(99, adj_score) %>%
  
  select(primaryTitle, startYear, popularity, quality) %>%
  
  mutate(rank = row_number(),
         facet = ifelse(rank < 34, 1, 
                        ifelse(rank < 67, 2, 3))) %>%
  
  mutate(label = paste0(rank, " - ", primaryTitle, " (", startYear, ")")) %>%
  
  arrange(-rank) %>%
  
  mutate(label = factor(label, levels = label))


ggplot(best_ever, aes(-rank, y = 1, label = label)) +
  
  facet_wrap(~facet, scales = "free") +
  
  geom_tile(stat = "identity", fill = "dodgerblue3", alpha = 0.2) +
  
  geom_text(size = 5, family = "Trebuchet MS") +
  
  theme_few() +
  
  coord_flip() +
  
  xlab("") +
  
  ylab("") +
  
  ggtitle("IMDB Top 99 Horror Movies Since 1960", subtitle = "movies ranked using a blended score based on popularity and quality") +
  
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        plot.title = element_text(size = 22, face = "bold", family = "Trebuchet MS", hjust = 0.5),
        plot.subtitle = element_text(size = 16, face = "italic", family = "Trebuchet MS", hjust = 0.5),
        strip.background = element_blank(),
        strip.text = element_blank())

ggsave(filename = "imdb_top_99_horror.png", height = 10.666, width = 21.333)