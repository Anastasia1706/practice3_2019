library('data.table')

library('shiny')

library('dplyr')

library('bindrcpp')

shinyUI(
  
  pageWithSidebar(
    
    
    
    # название приложения:
    
    headerPanel('Статистика импорта'),
    
    
    
    # боковая панель
    
    sidebarPanel(
      
      # радиокнопки: период агрегирования данных
      
      radioButtons('period.name', 
                   
                   'Выберите период агрегирования', 
                   
                   c('Месяц', 'Квартал'), 
                   
                   selected = 'Месяц'),
      
      # слайдер: фильтр по годам
      
      sliderInput('year.range', 'Месяцы:',
                  
                  min = 1, max = 12, value = c(1, 12),
                  
                  width = "100%", sep = ''),
      
      # выпадающее меню: страна для отбора наблюдений
      
      uiOutput('stateList'),
      
      uiOutput('flow')
      
      
      
    ),
    
    
    
    # главная область
    
    mainPanel(
      
      # текст с названием выбранной страны
      
      textOutput('text'),
      
      # график ряда
      
      plotOutput('ts.plot'),
      
      # таблица данных
      
      dataTableOutput('table'),
      
      # кнопка сохранения данных
      
      actionButton('save.csv', 'Сохранить данные в .csv')
      
    )
    
  )
  
)
