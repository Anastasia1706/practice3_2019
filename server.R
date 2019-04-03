library('shiny')              # загрузка пакетов
library('dplyr')
library('data.table')
library('lubridate')
library('ggplot2')
library('zoo')
library('rsconnect')



my_data <- data.table(read.csv('comtrade (9).csv'
                               ))



my_data[, Period.Date := 
          as.POSIXct(as.yearmon(as.character(Period), 
                                
                                '%Y%m'))]
date_dat <- my_data$Period
date_dat <- as.integer(gsub('20170','',date_dat))
my_data <- mutate(my_data,date_dat)

work_data <- select(my_data, Period.Date,date_dat, Trade.Flow, Reporter, Partner, Commodity,
                    Trade.Value..US..)


shinyServer(function(input, output) {
  # список стран для выбора
  output$stateList <- renderUI({
    state.list <- sort(unique(work_data$Reporter))
    radioButtons('state',   # связанная переменная
                 'Выберите торгового партнёра:', state.list, 
                 selected = state.list[1])
    
  })
  
  output$flow <- renderUI({
    trade.flow <- sort(unique(work_data$Trade.Flow))
    radioButtons('flow',
                 
                 'Выберите поток:', trade.flow,
                 
                 selected = trade.flow[1])
    
  })
  
  # реагирующая таблица данных
  
  DT <- reactive({
    # фильтруем по годам
    DT <- filter(work_data, between((as.integer(date_dat)), 
                                    input$year.range[1],
                                    input$year.range[2]))
    # агрегируем
    if (input$period.name == 'Месяц') {
      DT <- filter(DT, Reporter == input$state, Trade.Flow ==input$flow) %>% 
        mutate(period = as.yearmon(Period.Date))
      
    } else {
      
      DT <- filter(DT, Reporter == input$state, Trade.Flow ==input$flow) %>%
        mutate(period = as.yearqtr(Period.Date))
      
    }
    
    DT <- DT %>% group_by(period) %>% 
      
      mutate(Trade.Value.USD = sum(Trade.Value..US..))
    
    DT <- data.table(DT)
    
    # добавляем ключевой столбец: период времени
    
    setkey(DT, 'period')
    
    # оставляем только уникальные периоды времени
    
    DT <- data.table(unique(DT))
    
  })
  
  
  
  # текст: выбрана страна
  
  output$text <- renderText({input$state}) 
  
  
  
  # график динамики
  
  output$ts.plot <- renderPlot({
    
    gp <- ggplot(DT(), aes(x = period, y = Trade.Value.USD))
    
    if (input$period.name == 'Месяц') {
      
      gp + geom_histogram(stat = 'identity') +
        
        scale_x_yearmon(format = "%b %Y")
      
    } else {
      
      gp + geom_histogram(stat = 'identity') +
        
        scale_x_yearqtr(format = "%YQ%q")
      
    }
    
  })
  
  
  
  # таблица данных в отчёте
  
  output$table <- renderDataTable({
    
    DT()
    
  }, options = list(lengthMenu = c(5, 10, 20), pageLength = 5))
  
  
  
  # событие "нажатие на кнопку 'сохранить'"
  
  observeEvent(input$save.csv, {
    
    if (input$period.name == 'Месяц') {
      
      by.string <- '_by_mon_'
      
    } else {
      
      by.string <- '_by_qrt_'
      
    }
    
    file.name <- paste('import_', input$year.range[1], '-',
                       
                       input$year.range[2], by.string, 'from_',
                       
                       input$state, '.csv',
                       
                       sep = '')
    
    # файл будет записан в директорию приложения
    
    write.csv(DT(), file = file.name,
              
              fileEncoding = 'UTF-8', row.names = F)
    
  })
  
})
