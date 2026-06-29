# 국내·해외 주식 분석 대시보드

R Shiny와 Plotly로 만든 주식 분석 대시보드입니다. 미국 주식뿐 아니라 코스피와 코스닥 종목도 조회할 수 있게 만들었고 캔들차트와 보조지표를 한 화면에서 확인하도록 구성했습니다.

## 주요 기능

- 미국·코스피·코스닥 시장 선택
- Yahoo Finance 기반 최근 1년 주가 데이터 조회
- 캔들차트 시각화
- RSI 계산 및 과매수·과매도 기준선 표시
- 볼린저밴드 상단선·하단선·중심선 표시
- CNN Fear & Greed Index 표시
- Plotly 도구를 이용한 확대·이동·호버 확인
- 차트 위에 선을 그리면 해당 구간 수익률 자동 계산

## 사용 기술

- R
- Shiny
- Plotly
- quantmod
- TTR
- dplyr
- httr
- jsonlite
- htmlwidgets
- JavaScript

## 내가 신경 쓴 부분

단순히 주가 그래프만 보여주는 앱이 아니라 차트를 보면서 바로 판단에 참고할 수 있는 지표를 같이 배치했습니다. RSI와 볼린저밴드는 R에서 계산하고 사용자가 직접 차트에 선을 그렸을 때 수익률이 표시되는 부분은 `htmlwidgets::onRender()`로 JavaScript를 연결해 처리했습니다.

국내 종목은 Yahoo Finance 형식에 맞게 코스피는 `.KS` 코스닥은 `.KQ` 접미사를 붙이도록 구현했습니다.

## 실행 방법

필요한 R 패키지를 설치한 뒤 `app.R`을 실행합니다.

```r
install.packages(c(
  "shiny",
  "dplyr",
  "quantmod",
  "TTR",
  "magrittr",
  "plotly",
  "jsonlite",
  "httr",
  "htmlwidgets"
))
```

```r
shiny::runApp()
```

## 사용 예시

- 미국 주식: `US` 선택 후 `TSLA`·`NVDA`·`AAPL`
- 코스피: `KOSPI` 선택 후 `005930`
- 코스닥: `KOSDAQ` 선택 후 `247540`

## 참고

국내 주식 데이터는 Yahoo Finance 제공 데이터 특성상 지연되거나 일부 종목에서 조회가 실패할 수 있습니다.
