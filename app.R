library(shiny)
library(dplyr)
library(quantmod)
library(TTR)
library(magrittr)
library(plotly)
library(jsonlite)
library(httr)
library(htmlwidgets)

# --- 1. 기본 설정 및 데이터 함수 (기존과 동일) ---
get_fear_greed <- function() {
  url <- "https://production.dataviz.cnn.io/index/fearandgreed/graphdata"
  tryCatch({
    ua <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    res <- httr::GET(url, httr::user_agent(ua), httr::timeout(10))
    if (httr::status_code(res) != 200) return(list(score = 0, rating = "Error", success = FALSE))
    
    data_text <- httr::content(res, "text", encoding = "UTF-8")
    data <- jsonlite::fromJSON(data_text)
    
    score <- round(data$fear_and_greed$score)
    rating <- data$fear_and_greed$rating
    rating <- paste0(toupper(substr(rating, 1, 1)), substr(rating, 2, nchar(rating)))
    
    return(list(score = score, rating = rating, success = TRUE))
  }, error = function(e) {
    return(list(score = 0, rating = "Connection Failed", success = FALSE))
  })
}

# --- 2. UI ---
my_ui <- fluidPage(
  titlePanel("박정우의 주식 차트 (국장 포함)"),
  
  tags$head(
    tags$script(HTML("
      $(document).on('keyup', '#ticker', function(event) {
        if(event.keyCode == 13){
          $('#search').click();
        }
      });
    ")),
    tags$style(HTML("
      body { font-size: 18px; }
      h2 { font-size: 48px !important; font-weight: bold; margin-bottom: 30px; }
      label { font-size: 24px !important; margin-bottom: 10px; }
      .form-control { font-size: 24px !important; height: 50px !important; }
      .btn { font-size: 24px !important; padding: 6px 24px !important; height: 50px; }
      .help-block { font-size: 18px !important; color: #333 !important; }
      /* 라디오 버튼 크기 키우기 */
      .radio label { font-size: 20px !important; margin-right: 20px; }
      .shiny-options-group { margin-bottom: 15px; }
    "))
  ),
  
  fluidRow(
    column(4, 
           div(style = "background-color: #f8f9fa; padding: 20px; border-radius: 10px;",
               # [추가됨] 시장 선택 버튼
               radioButtons("market", "Market Select:",
                            choices = c("US (미국)" = "US", 
                                        "KOSPI (코스피)" = "KS", 
                                        "KOSDAQ (코스닥)" = "KQ"),
                            selected = "US", inline = TRUE),
               
               div(style = "display: flex; align-items: flex-end; gap: 10px;",
                   textInput("ticker", "Enter Ticker / Code:", value = ""),
                   actionButton("search", "Search", class = "btn-primary", style = "margin-bottom: 15px;")
               )
           )
    ),
    column(8,
           helpText("1. 시장을 먼저 선택하세요 (미국/코스피/코스닥)."),
           helpText("2. 종목코드 입력 (예: 삼성전자 -> 005930, 테슬라 -> TSLA)."),
           helpText("3. 상단 도구모음 'Draw Line'으로 선을 그으면 수익률이 계산됩니다."),
           helpText("4. 국장은 Yahoo Finance 데이터 특성상 20분 지연될 수 있습니다.")
    )
  ),
  
  hr(),
  
  fluidRow(
    column(12,
           plotlyOutput("stockChart", height = "1000px")
    )
  )
)

# --- 3. Server ---
my_server <- function(input, output, session) {
  
  stock_data <- eventReactive(input$search, {
    req(input$ticker)
    
    # [수정됨] 티커 처리 로직
    raw_ticker <- input$ticker
    market <- input$market
    
    # 시장에 따라 접미사(Suffix) 붙이기
    full_ticker <- switch(market,
                          "US" = raw_ticker,           # 미국은 그대로
                          "KS" = paste0(raw_ticker, ".KS"), # 코스피
                          "KQ" = paste0(raw_ticker, ".KQ")  # 코스닥
    )
    
    start_date <- Sys.Date() - 365*1 
    
    tryCatch({
      # full_ticker 사용
      data <- getSymbols(full_ticker, src = "yahoo", from = start_date, auto.assign = FALSE, warnings = FALSE)
      
      # 데이터가 없거나 NA가 많은 경우 처리
      data <- na.omit(data) 
      if(nrow(data) == 0) stop("No Data")
      
      stock_cl <- Cl(data)
      rsi_val <- RSI(stock_cl, n = 14)
      bb <- BBands(stock_cl)
      
      df <- data.frame(Date = index(data),
                       Open = as.numeric(Op(data)),
                       High = as.numeric(Hi(data)),
                       Low = as.numeric(Lo(data)),
                       Close = as.numeric(Cl(data)),
                       RSI = as.numeric(rsi_val),
                       BB_Up = as.numeric(bb[,"up"]),
                       BB_Dn = as.numeric(bb[,"dn"]),
                       BB_Mavg = as.numeric(bb[,"mavg"]))
      
      # [추가] 차트 제목용 이름 저장
      attr(df, "ticker_name") <- full_ticker 
      
      return(df)
    }, error = function(e) {
      showNotification(paste("데이터를 찾을 수 없습니다:", full_ticker), type = "error")
      return(NULL)
    })
  }) 
  
  fng_data <- reactive(get_fear_greed())
  
  output$stockChart <- renderPlotly({
    df <- stock_data()
    req(df)
    
    # 저장해둔 티커 이름 가져오기
    current_ticker <- attr(df, "ticker_name") %>% toupper()
    
    fng <- fng_data()
    # 공포탐욕지수는 미국 시장 기준이므로 국장 볼 때 참고용으로만 표시
    fng_label <- if(fng$success) {
      paste0("CNN 공포탐욕: ", fng$score, " (", fng$rating, ")")
    } else {
      paste0("공포탐욕: ", fng$rating)
    }
    
    # 마지막 종가 포맷팅 (천단위 콤마)
    last_close <- tail(df$Close, 1)
    last_close_str <- format(last_close, big.mark = ",", scientific = FALSE)
    
    last_rsi_val <- tail(df$RSI, 1) %>% round(2)
    
    spike_settings <- list(showspikes = TRUE, spikemode = "across",
                           spikesnap = "cursor", showspikelabels = TRUE,
                           spikedash = "solid", spikethickness = 1)
    
    # 캔들차트 그리기
    p1 <- plot_ly(data = df, x = ~Date, type = "candlestick",
                  open = ~Open, close = ~Close, high = ~High, low = ~Low,
                  name = paste0(current_ticker, " (", last_close_str, ")")) %>%
      add_lines(x = ~Date, y = ~BB_Up, name = "BB Upper", line = list(color = 'gray', width = 1, dash = 'dot'), inherit = FALSE, showlegend = FALSE) %>%
      add_lines(x = ~Date, y = ~BB_Dn, name = "BB Lower", line = list(color = 'gray', width = 1, dash = 'dot'), inherit = FALSE, showlegend = FALSE) %>%
      add_lines(x = ~Date, y = ~BB_Mavg, name = "BB MA", line = list(color = 'orange', width = 1), inherit = FALSE, showlegend = FALSE) %>%
      add_lines(x = ~Date[1], y = ~Close[1], name = fng_label, line = list(color = 'transparent'), showlegend = TRUE, inherit = FALSE, hoverinfo = "skip") %>% 
      layout(yaxis = c(list(title = "Price (KRW/USD)"), spike_settings))
    
    p2 <- plot_ly(data = df, x = ~Date, y = ~RSI, type = 'scatter', mode = 'lines', 
                  name = paste0("RSI (", last_rsi_val, ")"), line = list(color = 'purple', width = 1.5)) %>%
      layout(yaxis = c(list(title = "RSI", range = c(0, 100)), spike_settings)) %>%
      add_lines(x = ~Date, y = 70, name = "Overbought (70)", line = list(color = "red", dash = "dash"), inherit = FALSE, showlegend = FALSE) %>%
      add_lines(x = ~Date, y = 30, name = "Oversold (30)", line = list(color = "blue", dash = "dash"), inherit = FALSE, showlegend = FALSE)
    
    fig <- subplot(p1, p2, heights = c(0.7, 0.3), nrows = 2, shareX = TRUE, titleY = TRUE) %>%
      layout(
        font = list(size = 18),
        hovermode = "closest",
        xaxis = list(rangeslider = list(visible = FALSE), type = "date", showspikes = TRUE, spikemode = "across", spikesnap = "cursor"),
        plot_bgcolor = "#f5f5f5", paper_bgcolor = "white",
        legend = list(orientation = "h", x = 0.5, xanchor = "center", y = 1.1)
      ) %>%
      plotly::config(modeBarButtonsToAdd = list("drawline", "eraseshape"))
    
    # JS 수익률 계산 로직 (기존과 동일)
    yield <- "
    function(el, x) {
      var gd = document.getElementById(el.id);
      gd.on('plotly_relayout', function(eventData) {
        var isShape = false;
        var keys = Object.keys(eventData);
        for (var i=0; i<keys.length; i++) {
          if (keys[i].indexOf('shapes') !== -1) { isShape = true; break; }
        }
        if (isShape) {
          var shapes = gd.layout.shapes || [];
          var anns = [];
          for (var i=0; i<shapes.length; i++) {
            var s = shapes[i];
            if (s.type === 'line' && (s.yref === 'y' || s.yref === undefined)) {
              var y0 = parseFloat(s.y0);
              var y1 = parseFloat(s.y1);
              if (!isNaN(y0) && !isNaN(y1) && y0 !== 0) {
                var pct = ((y1 - y0) / y0) * 100;
                var col = pct >= 0 ? '#00c853' : '#d50000';
                var txt = pct.toFixed(2) + '%';
                if (pct > 0) txt = '+' + txt;
                anns.push({
                  x: s.x1, y: s.y1, xref: s.xref, yref: s.yref,
                  text: txt, showarrow: true, arrowhead: 2, ax: 0, ay: -20,
                  bgcolor: col, bordercolor: col, borderwidth: 1,
                  font: {color: 'white', size: 12}, opacity: 0.9, captureevents: false
                });
              }
            }
          }
          Plotly.relayout(gd, {annotations: anns});
        }
      });
    }
    "
    
    fig <- htmlwidgets::onRender(fig, yield)
    return(fig)
  })
}

shinyApp(ui = my_ui, server = my_server)

