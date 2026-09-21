# Movies

Exploratory analysis of film data, mostly horror — director careers, franchise
trajectories, and how ratings distribute across genres and years.

Written in R in 2019–2020. This is finished work, kept for reference rather
than actively maintained.

## Data

Two public sources, loaded into a local MariaDB database:

- **IMDb datasets** (`datasets.imdbws.com`) — titles, ratings, crew, episodes
  and names, published by IMDb as gzipped TSVs.
- **MovieLens** (GroupLens Research) — ratings, tags, links and the tag genome.

`scripts/Data gathering (public).R` downloads them; `scripts/Create MySQL
Tables.R` builds the schema and loads them; `scripts/Update MySQL database.R`
refreshes it. Everything else queries that database.

**These scripts were last run in 2020.** The IMDb dataset URLs are unchanged,
but MovieLens release names and file layouts have shifted since, so expect the
loading scripts to need adjustment before they run today.

## What's here

| Script | Question it answers |
|---|---|
| `Best horror directors.R` | Which horror directors have the strongest body of work? |
| `Career plots.R` | How does a director's rating trajectory look over a career? |
| `Horror.R`, `Slashers.R` | How do horror and slasher films rate against each other? |
| `Horror franchises.R` | How do franchises hold up across sequels? |
| `Best of the year.R`, `Best ever.R` | Top-rated titles by year and all-time |
| `Sports Movies.R`, `TV Series.R` | The same treatment for other categories |
| `Exploration.R` | Scratch work, kept deliberately |

Charts are in `viz/`.

## Running these

The database scripts read the password from an environment variable rather
than hardcoding it. Set it in `~/.Renviron`:

```
MOVIES_DB_PASSWORD=your_password_here
```

Then restart R. The scripts expect a local MariaDB instance with a `movies`
database.

## License

No license specified — personal analysis work, shared for reference.
