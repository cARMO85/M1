# ************************
# 
# Data Collection and Cleaning
#
# ************************

# Load required libraries
library(DBI)
library(RMySQL)
library(tidyverse)
library(ggplot2)

# Establish connection to the MySQL database
con <- dbConnect(RMySQL::MySQL(),
                 dbname = 'q10',
                 host = '127.0.0.1',
                 port = 3306,
                 user = 'root',
                 password = 'kildimo123')

# Query the junction data from the database
df <- dbGetQuery(con, "SELECT * FROM junction_data")

# Close the database connection for security
dbDisconnect(con)

# Combine 'record_date' and 'record_time' into a single datetime column
df <- df %>%
  mutate(
    datetime = as.POSIXct(paste(record_date, record_time), format = "%Y-%m-%d %H:%M:%S")
  )

# Filter the dataset to include only records up to midnight on 15th September 2024
df_filtered <- df %>%
  filter(datetime <= as.POSIXct("2024-09-15 00:00:00"))

# Categorise the times by peak/off-peak hours
df_filtered <- df_filtered %>%
  mutate(
    hour = as.numeric(format(datetime, "%H")),
    time_of_day = case_when(
      hour >= 6 & hour <= 9 ~ "morning_peak",
      hour >= 16 & hour <= 19 ~ "evening_peak",
      TRUE ~ "off_peak"
    )
  )

# Combine northbound (primary) and southbound (secondary) data into a single dataframe
df_long <- df_filtered %>%
  select(
    junction_name,
    primary_direction, primary_speed_limit, primary_avg_speed,
    secondary_direction, secondary_speed_limit, secondary_avg_speed,
    datetime, day_of_week, time_of_day
  ) %>%
  pivot_longer(
    cols = c(primary_avg_speed, secondary_avg_speed),
    names_to = "speed_type",
    values_to = "avg_speed"
  ) %>%
  mutate(
    direction = case_when(
      speed_type == "primary_avg_speed" ~ primary_direction,
      speed_type == "secondary_avg_speed" ~ secondary_direction
    )
  ) %>%
  select(-speed_type, -primary_direction, -secondary_direction)

# ************************
# 
# Statistical Analysis and Visualisation
#
# ************************

# Set seed for reproducibility in sampling
set.seed(123)

# Plotting the histogram of overall traffic speeds
ggplot(df_long, aes(x = avg_speed)) +
  geom_histogram(
    binwidth = 5,
    fill = "steelblue",
    colour = "black",
    alpha = 0.7
  ) +
  labs(title = "Histogram of Overall Traffic Speeds", 
       x = "Average Speed (mph)", 
       y = "Frequency") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12),
    legend.position = "top"
  )

# Perform ANOVA to test for differences between junctions and direction
anova_result <- aov(avg_speed ~ junction_name * direction, data = df_long)
summary(anova_result)

# Perform t-tests for peak vs. off-peak times for northbound and southbound traffic
# Northbound
t_test_result_nb <- t.test(
  avg_speed ~ time_of_day,
  data = df_long %>% filter(direction == "NB" & time_of_day %in% c("morning_peak", "off_peak"))
)
print(t_test_result_nb)

# Southbound
t_test_result_sb <- t.test(
  avg_speed ~ time_of_day,
  data = df_long %>% filter(direction == "SB" & time_of_day %in% c("morning_peak", "off_peak"))
)
print(t_test_result_sb)

# ************************
# 
# Summarisation and Further Visualisation
#
# ************************

# Create a summary of statistics for each day of the week and direction
summary_day <- df_long %>%
  group_by(day_of_week, direction) %>%
  summarise(
    mean_speed = mean(avg_speed, na.rm = TRUE),
    sd_speed = sd(avg_speed, na.rm = TRUE),
    median_speed = median(avg_speed, na.rm = TRUE),
    n = n(),
    .groups = 'drop'
  )

# Correct order of 'day_of_week'
summary_day$day_of_week <- factor(summary_day$day_of_week, 
                                  levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))

# Line graph of average speeds by day of the week and direction
ggplot(summary_day, aes(x = day_of_week, y = mean_speed, colour = direction, group = direction)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Average Speeds by Day of the Week and Direction",
    x = "Day of the Week",
    y = "Average Speed (mph)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "top", 
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12)
  )

# Boxplot of Average Traffic Speeds by Junction and Direction
ggplot(df_long, aes(x = junction_name, y = avg_speed, fill = direction)) +
  geom_boxplot(outlier.size = 1.5, outlier.alpha = 0.5) +
  scale_y_continuous(limits = c(0, 80), breaks = seq(0, 80, by = 10)) +
  labs(
    title = "Boxplot of Average Traffic Speeds by Junction and Direction",
    subtitle = "Comparing Northbound (NB) and Southbound (SB) Traffic",
    x = "Junction Name",
    y = "Average Speed (mph)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "top",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10)
  ) +
  scale_fill_manual(
    values = c("red", "green"),
    name = "Direction",
    labels = c("NB", "SB")
  )

# Boxplot of Traffic Speeds by Junction and Time of Day (Second Boxplot)
ggplot(df_long, aes(x = junction_name, y = avg_speed, fill = time_of_day)) +
  geom_boxplot(outlier.size = 1.5, outlier.alpha = 0.5) +
  scale_y_continuous(limits = c(0, 80), breaks = seq(0, 80, by = 10)) +
  labs(
    title = "Boxplot of Traffic Speeds by Junction and Time of Day",
    subtitle = "Comparing Morning, Evening, and Off-Peak Times",
    x = "Junction Name",
    y = "Average Speed (mph)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "top",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10)
  ) +
  scale_fill_manual(
    values = c("red", "green", "blue"),
    name = "Time of Day",
    labels = c("Morning Peak", "Evening Peak", "Off Peak")
  )
