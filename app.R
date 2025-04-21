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

# Reusable function to render maps
createDeltaMap <- function(energyType, popupLabel) {
  deltaData <- computeDelta4yr(energyType)
  mapData <- merge(country_coords, deltaData, by = "Country", all.x = TRUE)
  pal <- colorNumeric(palette = "RdYlGn", domain = c(0, 100))
  leaflet(mapData) %>%
    addTiles() %>%
    addCircleMarkers(
      lat = ~Latitude,
      lng = ~Longitude,
      radius = 5,
      color = ~pal(Delta),
      stroke = FALSE,
      fillOpacity = 0.8,
      popup = ~paste("Country:", Country, "<br>", popupLabel, round(Delta, 2), "%")
    ) %>%
    addLegend("bottomright", pal = pal, values = ~Delta,
              title = paste(energyType, "4-yr Delta (%)"), opacity = 1)
}

ui <- fluidPage(
  titlePanel("Renewable Energy Trends Dashboard"),
  sidebarLayout(
    sidebarPanel(
      # Show controls only when NOT in a map tab.
      conditionalPanel(
        condition = "input.mainTabs == 'Time Series Analysis' || input.mainTabs == 'Regression Analysis'",
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
      )
    ),
    mainPanel(
      tabsetPanel(
        id = "mainTabs",
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
    # Group by Year and Country for individual country lines
    tsData <- filteredData() %>% 
      group_by(Year, Country) %>% 
      summarize(Production = sum(get(input$source), na.rm = TRUE), .groups = "drop")
    # Total production line
    totalData <- filteredData() %>% 
      group_by(Year) %>% 
      summarize(Total = sum(get(input$source), na.rm = TRUE))
    
    p <- ggplot() +
      geom_line(data = tsData, aes(x = Year, y = Production, color = Country), size = 1) +
      geom_point(data = tsData, aes(x = Year, y = Production, color = Country)) +
      geom_line(data = totalData, aes(x = Year, y = Total), color = "black", size = 1.2, linetype = "dashed") +
      labs(title = paste(input$source, "Production Over Time"),
           x = "Year", y = "Production")
    
    ggplotly(p)
  })
  
  regressionModel <- reactive({
    regData <- filteredData() %>% 
      filter(!is.na(gdp)) %>% 
      group_by(Country, Year) %>% 
      summarize(GDP = sum(gdp, na.rm = TRUE),
                RenewableProduction = sum(TotalRenewables, na.rm = TRUE), .groups = "drop")
    lm(RenewableProduction ~ GDP, data = regData)
  })
  
  output$regPlot <- renderPlot({
    regData <- filteredData() %>% 
      filter(!is.na(gdp)) %>% 
      group_by(Country, Year) %>% 
      summarize(GDP = sum(gdp, na.rm = TRUE),
                RenewableProduction = sum(TotalRenewables, na.rm = TRUE), .groups = "drop")
    ggplot(regData, aes(x = GDP, y = RenewableProduction)) +
      geom_point() +
      geom_smooth(method = "lm", se = FALSE, color = "red") +
      labs(title = "Regression: GDP vs Renewable Electricity Production",
           x = "GDP (USD)", y = "Renewable Production (GWh)") +
      theme_minimal()
  })
  
  output$regSummary <- renderPrint({
    summary(regressionModel())
  })
  
  output$trendMapSolar <- renderLeaflet({
    createDeltaMap("Solar", "Solar 4-yr Change:")
  })
  
  output$trendMapWind <- renderLeaflet({
    createDeltaMap("Wind", "Wind 4-yr Change:")
  })
  
  output$trendMapHydro <- renderLeaflet({
    createDeltaMap("Hydro", "Water 4-yr Change:")
  })
}

shinyApp(ui = ui, server = server)
