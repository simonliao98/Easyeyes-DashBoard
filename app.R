
library(shiny)
require(foreach)
require(dplyr)
require(readr)
require(ggplot2)
require(stringr)
require(emojifont)
require(DT)
library(ggpubr)
library(shinyjs)
library(lubridate)
library(ggpp)

source('./constant.R')
source("preprocess.R")
source("./error report/summary_table.R")
source("threshold_and_warning.R")
source("./error report/random_rgb.R")
source("./plotting/mean_median_plot.R")
source("./plotting/regression_plot.R")
source("./plotting/histogram.R")
source("./plotting/crowding_plot.R")
source("./plotting/test_retest.R")
source("./other/getBits.R")
source("./plotting/scatter_plots.R")

options(shiny.maxRequestSize=70*1024^2)
ui <- navbarPage(
  title = textOutput("app_title"),
  tabPanel('Sessions', 
           # span(textOutput("experiment"), style="font-size:20px; margin-top:0px"),
           tags$head(
             # Note the wrapping of the string in HTML()
             tags$style(HTML("
    .navbar{
    margin-bottom: 10px
    }
      .dataTables_filter{
      float: left !important;
      }
  .form-group {
  margin-bottom: 10px;
  }
  .form-group .form-control {
  width: 150px;
  }
  .container-fluid {
  padding-left:5px;
  padding-right:0px;
  }
  "))),
           fluidRow(column(width = 3, fileInput("file", NULL, accept = ".csv", buttonLabel = "Select CSV files", multiple = T)),
                    column(width = 2, downloadButton("report", "Download report")),
                    column(width = 2, textInput("search", label = NULL))
                    ),
           textOutput("instruction"),
           shinycssloaders::withSpinner(DT::dataTableOutput('ex1')), type = 5, color = "#0dc5c1", size = 2),
  tabPanel('Stats',  
           downloadButton("threshold", "Download"),
           fluidRow(tableOutput('ex3')),
           fluidRow(tableOutput('ex2'))),
  tabPanel('Plots', 
           radioButtons("fileType", "Select download file type:",
                        c("pdf" = "pdf",
                          "eps" = "eps"),
                        inline = TRUE, selected = "pdf"),
           #### mean - median ####
           splitLayout(cellWidths = c("50%", "50%"),
                       shinycssloaders::withSpinner(plotOutput("meanPlot", width = "100%")),
                       shinycssloaders::withSpinner(plotOutput("medianPlot", width = "100%"))),
           splitLayout(cellWidths = c("50%", "50%"),
                       downloadButton("downloadMeanPlot", "Download"), 
                       downloadButton("downloadMedianPlot", "Download")
                       ),
           #### regression ####
           splitLayout(cellWidths = c("50%", "50%"),
                       shinycssloaders::withSpinner(plotOutput("regressionPlot", width = "100%")),
                       shinycssloaders::withSpinner(plotOutput("regressionAndMeanPlot", width = "100%"))
                       ),
           splitLayout(cellWidths = c("50%", "50%"),
                       downloadButton("downloadRegressionPlot", "Download"),
                       downloadButton("downloadRegressionAndMeanPlot", "Download")
           ),
           ####fluency ####
           splitLayout(cellWidths = c("50%", "50%"),
                       shinycssloaders::withSpinner(plotOutput("fluencyHistogram", width = "100%"))
           ),
           splitLayout(cellWidths = c("50%", "50%"),
                       downloadButton("downloadFluencyHistogram", "Download")
           ),
           #### retention ####
           splitLayout(cellWidths = c("50%", "50%"),
                       shinycssloaders::withSpinner(plotOutput("retentionHistogram", width = "100%")),
                       shinycssloaders::withSpinner(plotOutput("readingSpeedRetention", width = "100%"))
           ),
           splitLayout(cellWidths = c("50%", "50%"),
                       downloadButton("downloadRetentionHistogram", "Download"),
                       downloadButton("downloadReadingSpeedRetention", "Download")
           ),
           #### crowding ####
           splitLayout(cellWidths = c("50%", "50%"),
                       shinycssloaders::withSpinner(plotOutput("crowdingAvgPlot", width = "100%")),
                       shinycssloaders::withSpinner(plotOutput("crowdingScatterPlot", width = "100%"))
           ),
           splitLayout(cellWidths = c("50%", "50%"),
                       downloadButton("downloadCrowdingAvgPlot", "Download"),
                       downloadButton("downloadCrowdingScatterPlot", "Download")
           ),
           h3("Test and Retest plots"),
           splitLayout(cellWidths = c("50%", "50%"),
                       shinycssloaders::withSpinner(plotOutput("readingTestRetest", width = "100%")),
                       shinycssloaders::withSpinner(plotOutput("crowdingTestRetest", width = "100%"))
           ),
           splitLayout(cellWidths = c("50%", "50%"),
                       downloadButton("downloadReadingTestRetest", "Download"),
                       downloadButton("downloadCrowdingTestRetest", "Download")
           ),
           splitLayout(cellWidths = c("50%", "50%"),
                       shinycssloaders::withSpinner(plotOutput("rsvpReadingTestRetest", width = "100%"))
           ),
           splitLayout(cellWidths = c("50%", "50%"),
                       downloadButton("downloadRsvpReadingTestRetest", "Download")
           ),
  ),
  tabPanel('Bits',  
           h3("All Participant"),
           textOutput('all participant I'),
           splitLayout(cellWidths = c("50%", "50%"),
                       tableOutput('all participant prob')
           ),
           h3("Each Participant"),
           tableOutput('each participant I'),
           splitLayout(cellWidths = c("50%", "50%"),
                       tableOutput('each participant prob')
           ))
)

server <- function(input, output, session) {
  output$file_name <- renderText({input$file_name})
  
  #### reactive objects ####
  files <- reactive({
    require(input$file)
    return(read_files(input$file))
  })
  data_list <- reactive({
    return(files()[[1]])
  })
  summary_list <- reactive({
    return(files()[[2]])
  })
  experiment_names <- reactive({
    return(trimws(files()[[3]]))
  })
  app_title <- reactiveValues(default = "EasyEyes Analysis")
  output$app_title <- renderText({
    "EasyEyes Analysis"
  })
  observeEvent(input$file,{
    app_title$default <- experiment_names()
    output$app_title <- renderText({
      ifelse(app_title$default == "", "EasyEyes Analysis", app_title$default)
    })
  })
  #### place holder ####
  output$ex1 <- renderDataTable({
    datatable(tibble())
  })
  
  output$meanPlot <- renderPlot({
    ggplot()
  }, res = 96)
  output$medianPlot <- renderPlot({
    ggplot()
  }, res = 96)
  output$regressionPlot <- renderPlot({
    ggplot()
  })
  output$regressionAndMeanPlot <- renderPlot({
    ggplot()
  })
  output$fluencyHistogram <- renderPlot({
    ggplot()
  })
  output$retentionHistogram <- renderPlot({
    ggplot()
  })
  output$crowdingScatterPlot <- renderPlot({
    ggplot()
  })
  output$crowdingAvgPlot <- renderPlot({
    ggplot()
  })
  output$readingTestRetest <- renderPlot({
    ggplot()
  })
  output$crowdingTestRetest <- renderPlot({
    ggplot()
  })
  output$rsvpReadingTestRetest <- renderPlot({
    ggplot()
  })
  output$readingSpeedRetention <- renderPlot({
    ggplot()
  })
  
  readingCorpus <- reactive({
    return(trimws(files()[[4]]))
  })
  
  #### reactive dataframes ####
  
  summary_table <- reactive({
    generate_summary_table(data_list())
  })
  threshold_and_warnings <- reactive({
    require(input$file)
    return(generate_threshold(data_list(), summary_list()))
  })
  df_list <- reactive({
    return(generate_rsvp_reading_crowding_fluency(data_list(), summary_list()))
    })
  reading_rsvp_crowding_df <- reactive({
    return(get_mean_median_df(df_list()))
    })
  
  #### reactive plots #####
  
  meanPlot <- reactive({
    require(input$file)
    mean_plot(reading_rsvp_crowding_df()) +
      labs(title = paste(c("Reading Speed, mean", 
                           experiment_names()), collapse = "\n")) +
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  medianPlot <- reactive({
    require(input$file)
    median_plot(reading_rsvp_crowding_df()) + 
      labs(title = paste(c("Reading Speed, median", 
                         experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  crowdingBySide <- reactive({
    crowding_by_side(df_list()[[2]])
  })
  crowdingPlot <- reactive({
    crowding_scatter_plot(crowdingBySide())  + 
      labs(title = paste(c("Crowding, left vs. right, by observer", 
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  crowdingAvgPlot <- reactive({
    crowding_mean_scatter_plot(crowdingBySide())  + 
      labs(title = paste(c("Crowding, left vs. right, by font", 
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  regressionPlot <- reactive({
    regression_plot(df_list()) +
      labs(title = paste(c("Regression of reading vs crowding", 
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  regressionAndMeanPlot <- reactive({
    regression_and_mean_plot(df_list(), reading_rsvp_crowding_df()) +
      labs(title = paste(c("Regression of reading vs crowding",
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  fluency_histogram <- reactive({
    get_fluency_histogram(df_list()[[4]]) + 
      labs(title = paste(c("English fluency histogram", 
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  retention_histogram <- reactive({
    get_reading_retention_histogram(df_list()[[1]]) + 
      labs(title = paste(c("Reading retention histogram", 
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  readingTestRetest <- reactive({
    get_test_retest_reading(df_list()[[1]]) + 
      labs(title = paste(c("Test retest of reading", 
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  crowdingTestRetest <- reactive({
    get_test_retest_crowding(df_list()[[2]]) + 
      labs(title = paste(c("Test retest of crowding", 
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  rsvpReadingTestRetest <- reactive({
    get_test_retest_rsvp(df_list()[[3]])  + 
      labs(title = paste(c("Test retest of rsvp reading", 
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  
  readingSpeedRetention <- reactive({
    reading_speed_vs_retention(df_list()[[1]]) + 
      labs(title = paste(c("Reading vs retention", 
                           experiment_names()), collapse = "\n")) + 
      ggpp::geom_text_npc(
        aes(npcx = "left",
            npcy = "bottom",
            label = paste0("italic('N=')~", length(unique(df_list()[[1]]$participant)))), 
        parse = T)
  })
  
  
  ##### request from Francesca #####
  
  allMeasures <- reactive({
    get_measures(data_list())
  })
  
  prob_all <- reactive({
    get_prob(get_counts_all(allMeasures())) %>% select(-participant)
  })
  
  prob_each <- reactive({
    get_prob(get_counts_each_participant(allMeasures()))
  })
  
  
  #### Event Handler ####
  
  # This execute when user upload a bunch of csv files
  
  observeEvent(input$file, 
               {
                 set.seed(2023)
                 participants <- reactive({
                   unique(summary_table()$`Pavlovia session ID`)
                   })
                 prolific_id <- reactive({
                   unique(summary_table()$`Prolific participant ID`)
                 })
                 output$ex1 <- DT::renderDataTable(
                   dt <- datatable(
                     summary_table(),
                     class = list(stripe = FALSE),
                     selection = 'none',
                     filter = "top",
                     escape = FALSE,
                     width = "200%",
                     options = list(
                       autoWidth = FALSE,
                       paging = FALSE,
                       scrollX=TRUE,
                       searching = FALSE,
                       language = list(
                         info = 'Showing _TOTAL_ entries',
                         infoFiltered =  "(filtered from _MAX_ entries)"
                       ),
                       columnDefs = list(
                         list(visible = FALSE, targets = c(0,22)),
                         list(orderData=22, targets=17),
                         list(targets = c(14),
                              width = '500px',
                              className = 'details-control1',
                              render = JS(
                                "function(data, type, row, meta) {",
                                "return type === 'display' && data.length > 20 ?",
                                "data.substr(0, 20) + '...' : data;",
                                "}")),
                         list(targets = c(15),
                              width = '250px',
                              className = 'details-control2',
                              render = JS(
                                "function(data, type, row, meta) {",
                                "return type === 'display' && data.length > 20 ?",
                                "data.substr(0, 20) + '...' : data;",
                                "}")),
                         list(targets = c(1), render = JS(
                           "function(data, type, row, meta) {",
                           "return type === 'display' && data.length > 6 ?",
                           "'<span title=\"' + data + '\">' + data.substr(0, 6) + '...</span>' : data;",
                           "}"), className = 'information-control1'),
                         list(targets = c(2), render = JS(
                           "function(data, type, row, meta) {",
                           "return type === 'display' && data.length > 6 ?",
                           "'<span title=\"' + data + '\">' + data.substr(0, 6) + '...</span>' : data;",
                           "}"), className = 'information-control2'),
                         list(width = '250px', targets = c(5, 6), className = 'dt-center'),
                         list(width = '50px', targets = c(3,4,7,13,17), className = 'dt-center'),
                         list(width = '200px', targets = c(18))
                       )
                     ),
                     callback = JS(
                       data_table_call_back
                     )) %>%
                     formatStyle(names(summary_table()), lineHeight="15px") %>% 
                     formatStyle(names(summary_table())[-1],
                                 'Pavlovia session ID',
                                 backgroundColor = styleEqual(participants(), random_rgb(length(participants())))) %>% 
                     formatStyle(names(summary_table())[1],
                                 'Prolific participant ID',backgroundColor = styleEqual(prolific_id(), random_rgb(length(prolific_id()))))
                 )
                 
                 output$ex2 <- renderTable(
                   threshold_and_warnings()[[2]] %>% select(-thresholdParameter)
                 )
                 output$ex3 <- renderTable(
                   threshold_and_warnings()[[1]]
                 )
                 output$instruction <- renderText(instruction)
                 output$experiment <- renderText(experiment_names())
                 output$meanPlot <- renderPlot({
                   meanPlot() + plt_theme
                   }, res = 96)
                 output$medianPlot <- renderPlot({
                   medianPlot() + plt_theme
                   }, res = 96)
                 output$regressionPlot <- renderPlot({
                   regressionPlot() + plt_theme + coord_fixed(ratio = 1)
                 })
                 output$regressionAndMeanPlot <- renderPlot({
                   regressionAndMeanPlot() + plt_theme + coord_fixed(ratio = 1)
                 })
                 output$fluencyHistogram <- renderPlot({
                   fluency_histogram() + plt_theme
                 })
                 output$retentionHistogram <- renderPlot({
                   retention_histogram() + plt_theme
                 })
                 output$crowdingScatterPlot <- renderPlot({
                   crowdingPlot()
                 })
                 output$crowdingAvgPlot <- renderPlot({
                   crowdingAvgPlot() + plt_theme + coord_fixed(ratio = 1)
                 })
                 output$readingTestRetest <- renderPlot({
                   readingTestRetest()
                 })
                 output$crowdingTestRetest <- renderPlot({
                   crowdingTestRetest()
                 })
                 output$rsvpReadingTestRetest <- renderPlot({
                   rsvpReadingTestRetest()
                 })
                 output$readingSpeedRetention <- renderPlot({
                   readingSpeedRetention()
                 })
                 output$`all participant prob` <- renderTable(prob_all())
                 output$`all participant I` <- renderText(paste0("I(X;Y) = ", round(get_bits(prob_all()),2)))
                 output$`each participant prob` <- renderTable(prob_each())
                 output$`each participant I` <- renderTable(get_bits_each(prob_each()))
               })
  
  #### download handlers ####
  
  output$report <- downloadHandler(
    filename = function(){ ifelse(experiment_names() == "", "error report.html", paste0(experiment_names(), ".html"))},
    content = function(file) {
      tempReport <- file.path(tempdir(), "error report.Rmd")
      file.copy("rmd/error report.Rmd", tempReport, overwrite = TRUE)
      rmarkdown::render(tempReport, output_file = file,
                        params = summary_table() %>% mutate(experiment = experiment_names()),
                        envir = new.env(parent = globalenv())
      )
    }
  )
  
  output$threshold <- downloadHandler(
    filename = function(){ ifelse(experiment_names() == "", "threshold.pdf", paste0("threshold-",experiment_names(), ".pdf"))},
    content = function(file) {
      tempReport <- file.path(tempdir(), "threshold.Rmd")
      file.copy("rmd/threshold.Rmd", tempReport, overwrite = TRUE)
      rmarkdown::render(tempReport, output_file = file,
                        params = c(threshold_and_warnings()[[1]], threshold_and_warnings()[[2]] %>% mutate(experiment = experiment_names())),
                        envir = new.env(parent = globalenv())
      )
    }
  )
  toListen <- reactive({
    list(input$file,input$fileType)
  })
  # download plots handlers
  observeEvent(toListen(), {
    
    output$downloadMeanPlot <- downloadHandler(
      filename = paste(experiment_names(), paste0('mean.', input$fileType), sep = "-"),
      content = function(file) {
        ggsave(file, plot = meanPlot() + downloadtheme)
      })
    
    output$downloadMedianPlot <- downloadHandler(
      filename = paste(experiment_names(),paste0('median.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = medianPlot() + downloadtheme)
      })
    
    output$downloadRegressionPlot <- downloadHandler(
      filename = paste(experiment_names(),paste0('regression.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = regressionPlot() + downloadtheme + coord_fixed(ratio = 1))
      })
    
    output$downloadRegressionAndMeanPlot <- downloadHandler(
      filename = paste(experiment_names(),paste0('regression.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = regressionAndMeanPlot() + downloadtheme + coord_fixed(ratio = 1))
      })
    
    output$downloadFluencyHistogram <- downloadHandler(
      filename = paste(experiment_names(),paste0('fluency.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = fluency_histogram() + downloadtheme)
      }) 
    
    output$downloadRetentionHistogram <- downloadHandler(
      filename = paste(experiment_names(),paste0('retention.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = retention_histogram() + downloadtheme)
      })
    
    output$downloadCrowdingScatterPlot <- downloadHandler(
      filename = paste(experiment_names(),paste0('crowding_left_vs_right.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = crowdingPlot())
      })
    
    output$downloadCrowdingAvgPlot <- downloadHandler(
      filename = paste(experiment_names(),paste0('average_crowding_left_vs_right.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = crowdingAvgPlot() + downloadtheme + coord_fixed(ratio = 1))
      })
    
    output$downloadReadingSpeedRetention <- downloadHandler(
      filename = paste(experiment_names(),paste0('reading-speed-vs-retention.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = readingSpeedRetention())
      })
    
    output$downloadReadingTestRetest <- downloadHandler(
      filename = paste(experiment_names(),paste0('reading-test-retest.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = readingTestRetest())
      })
    
    output$downloadCrowdingTestRetest <- downloadHandler(
      filename = paste(experiment_names(),paste0('crowding-test-retest.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = crowdingTestRetest())
      })
    
    output$downloadRsvpReadingTestRetest <- downloadHandler(
      filename = paste(experiment_names(),paste0('rsvp-test-retest.', input$fileType),sep = "-"),
      content = function(file) {
        ggsave(file, plot = rsvpReadingTestRetest())
      })
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
