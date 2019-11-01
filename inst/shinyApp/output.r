
loadGraphProxy <- function()
{
  loadGraph()
}

# Observer function designed to handle the loading/creation of the output graphs from the Hector model.
loadGraph <- function()
{
  print("in load graph")
  hdata <- data.frame()
  df_total <- data.frame()
  if(length(hcores) > 0)
  {
    if(length(outputVariables) < 5)
    {
      tryCatch(
        {
          if(length(outputVariables) >= 1)
          {
            withProgress(message = 'Loading Output Graphs...\n', value = 0,
            {
              for (i in 1:length(outputVariables))
              {
                # Need local so that each item gets its own number. Without it, the value
                # of i in the renderPlot() will be the same across all instances, because
                # of when the expression is evaluated.
                local(
                {
                    my_i <- i
                    plotname <- paste("plot", i, sep="")
                    plottitle <- paste("plottitle", globalScenarios[i], sep="")
                    tablename <- paste("tablename", globalScenarios[i], sep="")
                    seriesname <- ""
                    for(j in 1:length(hcores))
                    {
                      hdata <- hector::fetchvars(core = hcores[[j]], dates = 1800:globalVars['endDate'], vars = outputVariables[i], "\n")
                      if(names(hcores[j])=="Custom")
                        seriesname <- input$input_ScenarioName
                      else
                        seriesname <- paste("RCP ", names(hcores[j]))
                      hdata <- dplyr::mutate(hdata, scenario=seriesname)
                      df_total <- rbind(df_total,hdata)
                    }
                    x <- dplyr::distinct(hdata, units)
                    #browser()
                    ggplotGraph <- ggplot2::ggplot(data=df_total, ggplot2::aes(x=year, y=value, group=variable, color=scenario)) + ggplot2::geom_line() +
                      ggthemes::theme_solarized(light = TRUE)+ ggplot2::labs(y=x[[1]], title =  attr(outputVariables[[i]], 'longName'))
                    # +  ggplot2::guides(color = ggplot2::guide_colorbar(title = expression(beta)))
                    # +  ggplot2::scale_color_viridis_c()

                    localPlot <- plotly::ggplotly(p = ggplotGraph)
                    plotly::layout(p=localPlot, xaxis = a, yaxis = a )
                    #browser()
                    # output$plot1 <<-  plotly::renderPlotly(localPlot)

                    output[[plotname]] <- plotly::renderPlotly(localPlot)
                    # output[[plottitle]] <- renderText({paste("1:", my_i, ".  n is ", 4, sep = "")})
                    # output[[tablename]] <- renderTable({table(x = 1:my_i, y = 1:my_i)})
                })
                incProgress(1/length(hcores), detail = paste(attr(outputVariables[[i]], 'longName'), " loaded."))
                Sys.sleep(0.25)
              }
            })
            if(length(outputVariables) < 4)
            { #browser()
              output[["plot4"]] <<- NULL
              if(length(outputVariables) < 3)
                output[["plot3"]] <<- NULL
              if(length(outputVariables) < 2)
                output[["plot2"]] <<- NULL
            }
          }
          else
          {
            shinyalert::shinyalert("Invalid Input:", "Please choose at least 1 output variables.", type = "warning")
          }

        },
        warning = function(war)
        {
          # warning handler picks up where error was generated
          showModal(modalDialog(
            title = "Important message",
            paste("MY_WARNING:  ",war)
          ))

        },
        error = function(err)
        {
          # error handler picks up where error was generated
          shinyalert::shinyalert("Error Detected:",print(paste('There was an error when attempting to load the graph:',err)), type = "error")
        })
    }
    else
    {
      shinyalert::shinyalert("Invalid Input:", "Please choose no more than 4 output variables.", type = "warning")
    }
  }
  else
  {
    shinyalert::shinyalert("No active Hector cores", "Please set at least one of the RCP scenarios to active or upload a custom emissions scenario.", type = "warning")
  }
}

# Download handler for downloading the raw data output from a Hector run. This is activated upon button click.
output$downloadData <- downloadHandler(

  filename = function()
  {
    paste('Hector-data-', Sys.Date(), '.csv', sep='')
  },

  content = function(file)
  {
    if(length (hcores) > 0)
    {
      #browser()
      dataList <- list()
      df <- data.frame()
      seriesname <- ""
      for(i in 1:length(hcores))
      {
        hdata <- hector::fetchvars(core = hcores[[i]], dates = 1800:globalVars['endDate'], vars = outputVariables, "\n")
        hdata <- dplyr::mutate(hdata)
        if(names(hcores[i])=="Custom")
          seriesname <- input$input_ScenarioName
        else
          seriesname <- paste("RCP ", names(hcores[i]))
        hdata <- dplyr::mutate(hdata, scenario=seriesname)
        df <- data.frame(hdata)
        dataList[[i]] <- df
        # browser()
      }
    }
    header_text <- paste("File created with Hector UI - https://github.com/JGCRI/hector-ui\n" ,
                         "Model Parameters: " , input$input_paramToggle , "\n")

    cat(header_text, file = file)
    lapply(dataList, function(x) write.table( data.frame(x), file  , append= T, sep=',', row.names = F,  ))
    #write.csv(df, file, row.names = FALSE)
  }
)
