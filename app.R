library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)
library(leaflet)

renewable_data <- read.csv("data/energy-data.csv", stringsAsFactors = FALSE)
country_coords <- read.csv("data/country_coords.csv", stringsAsFactors = FALSE)

renewable_data <- renewable_data %>% 
  rename(
    Country = country,
    Year = year,
    Solar = solar_electricity,
    Wind = wind_electricity,
    Hydro = hydro_electricity,
    TotalRenewables = renewables_electricity
  )

computeDelta4yr <- function(energy_col) {
  latest_year <- max(renewable_data$Year, na.rm = TRUE)
  start_year <- latest_year - 4
  data_latest <- renewable_data %>% filter(Year == latest_year)
  data_start <- renewable_data %>% filter(Year == start_year)
  deltaData <- merge(
    data_start %>% select(Country, valueStart = !!sym(energy_col)),
    data_latest %>% select(Country, valueLatest = !!sym(energy_col)),
    by = "Country", all = TRUE
  )
  deltaData <- deltaData %>% 
    mutate(Delta = ifelse(!is.na(valueStart) & valueStart > 0,
                          ((valueLatest - valueStart) / valueStart) * 100,
                          NA)) %>%
    mutate(Delta = ifelse(is.na(Delta) | Delta < 0, 0, ifelse(Delta > 100, 100, Delta)))
  return(deltaData)
}

ui <- fluidPage(
  titlePanel("Renewable Energy Trends Dashboard"),
  sidebarLayout(
    sidebarPanel(
      selectInput("country", "Select Country",
                  choices = unique(renewable_data$Country),
                  selected = unique(renewable_data$Country)[1],
                  multiple = TRUE),
      sliderInput("year", "Select Year Range",
                  min = 2000,
                  max = max(renewable_data$Year, na.rm = TRUE),
                  value = c(2000, max(renewable_data$Year, na.rm = TRUE)),
                  step = 1,
                  sep = ""),
      selectInput("source", "Select Renewable Source",
                  choices = c("Solar", "Wind", "Hydro", "TotalRenewables"),
                  selected = "Solar",
                  multiple = FALSE)
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Time Series Analysis", plotlyOutput("timeSeriesPlot")),
        tabPanel("Regression Analysis", 
                 plotOutput("regPlot"),
                 verbatimTextOutput("regSummary")),
        tabPanel("Solar 4-yr Delta", leafletOutput("trendMapSolar", height = 600)),
        tabPanel("Wind 4-yr Delta", leafletOutput("trendMapWind", height = 600)),
        tabPanel("Water 4-yr Delta", leafletOutput("trendMapHydro", height = 600))
      )
    )
  )
)

server <- function(input, output, session) {
  filteredData <- reactive({
    renewable_data %>% 
      filter(Country %in% input$country,
             Year >= input$year[1],
             Year <= input$year[2])
  })
  
  output$timeSeriesPlot <- renderPlotly({
    tsData <- filteredData() %>% 
      group_by(Year) %>% 
      summarize(Production = sum(get(input$source), na.rm = TRUE))
    p <- ggplot(tsData, aes(x = Year, y = Production)) +
      geom_line(color = "blue") +
      geom_point() +
      labs(title = paste(input$source, "Production Over Time"),
           x = "Year", y = "Production")
    ggplotly(p)
  })
  
  regressionModel <- reactive({
    regData <- filteredData() %>% 
      filter(!is.na(gdp)) %>% 
      group_by(Country, Year) %>% 
      summarize(GDP = sum(gdp, na.rm = TRUE),
                RenewableProduction = sum(TotalRenewables, na.rm = TRUE))
    lm(RenewableProduction ~ GDP, data = regData)
  })
  
  output$regPlot <- renderPlot({
    regData <- filteredData() %>% 
      filter(!is.na(gdp)) %>% 
      group_by(Country, Year) %>% 
      summarize(GDP = sum(gdp, na.rm = TRUE),
                RenewableProduction = sum(TotalRenewables, na.rm = TRUE))
    ggplot(regData, aes(x = GDP, y = RenewableProduction)) +
      geom_point() +
      geom_smooth(method = "lm", se = FALSE, color = "red") +
      labs(title = "Regression: GDP vs Renewable Electricity Production",
           x = "GDP (proxy for Investment)", y = "Renewable Production")
  })
  
  output$regSummary <- renderPrint({
    summary(regressionModel())
  })
  
  output$trendMapSolar <- renderLeaflet({
    solarDelta <- computeDelta4yr("Solar")
    mapData <- merge(country_coords, solarDelta, by = "Country", all.x = TRUE)
    pal <- colorNumeric(palette = "RdYlGn", domain = c(0, 100))
    leaflet(mapData) %>%
      addTiles() %>%
      addCircleMarkers(lat = ~Latitude, lng = ~Longitude, radius = 5,
                       color = ~pal(Delta), stroke = FALSE, fillOpacity = 0.8,
                       popup = ~paste("Country:", Country, "<br>",
                                      "Solar 4-yr Change:", round(Delta, 2), "%")) %>%
      addLegend("bottomright", pal = pal, values = ~Delta,
                title = "Solar 4-yr Delta (%)", opacity = 1)
  })
  
  output$trendMapWind <- renderLeaflet({
    windDelta <- computeDelta4yr("Wind")
    mapData <- merge(country_coords, windDelta, by = "Country", all.x = TRUE)
    pal <- colorNumeric(palette = "RdYlGn", domain = c(0, 100))
    leaflet(mapData) %>%
      addTiles() %>%
      addCircleMarkers(lat = ~Latitude, lng = ~Longitude, radius = 5,
                       color = ~pal(Delta), stroke = FALSE, fillOpacity = 0.8,
                       popup = ~paste("Country:", Country, "<br>",
                                      "Wind 4-yr Change:", round(Delta, 2), "%")) %>%
      addLegend("bottomright", pal = pal, values = ~Delta,
                title = "Wind 4-yr Delta (%)", opacity = 1)
  })
  
  output$trendMapHydro <- renderLeaflet({
    hydroDelta <- computeDelta4yr("Hydro")
    mapData <- merge(country_coords, hydroDelta, by = "Country", all.x = TRUE)
    pal <- colorNumeric(palette = "RdYlGn", domain = c(0, 100))
    leaflet(mapData) %>%
      addTiles() %>%
      addCircleMarkers(lat = ~Latitude, lng = ~Longitude, radius = 5,
                       color = ~pal(Delta), stroke = FALSE, fillOpacity = 0.8,
                       popup = ~paste("Country:", Country, "<br>",
                                      "Water 4-yr Change:", round(Delta, 2), "%")) %>%
      addLegend("bottomright", pal = pal, values = ~Delta,
                title = "Water 4-yr Delta (%)", opacity = 1)
  })
}

shinyApp(ui = ui, server = server)
