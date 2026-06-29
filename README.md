# 국내·해외 주식 분석 대시보드

R Shiny와 Plotly를 활용해 국내·해외 주식 데이터를 조회하고 기술적 지표를 시각화하는 인터랙티브 주식 분석 대시보드입니다.

## 프로젝트 소개

사용자는 미국, 코스피, 코스닥 시장을 선택한 뒤 종목 티커 또는 종목코드를 입력해 최근 1년간의 주가 흐름을 확인할 수 있습니다. 캔들차트, RSI, 볼린저밴드, CNN 공포탐욕지수를 함께 제공하여 투자 판단에 필요한 보조 지표를 한 화면에서 확인할 수 있도록 구성했습니다.

## 주요 기능

- 미국, 코스피, 코스닥 시장 선택
- Yahoo Finance 기반 주가 데이터 조회
- 캔들차트 기반 주가 시각화
- RSI 지표 계산 및 과매수·과매도 구간 표시
- 볼린저밴드 상단선, 하단선, 중심선 표시
- CNN Fear & Greed Index 연동
- Plotly 기반 확대, 이동, 호버 정보 확인
- 차트 위에 선을 그리면 JavaScript로 수익률 자동 계산

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

- 미국 주식: 시장을 `US`로 선택한 뒤 `TSLA`, `NVDA`, `AAPL` 등 입력
- 코스피: 시장을 `KOSPI`로 선택한 뒤 `005930` 등 입력
- 코스닥: 시장을 `KOSDAQ`으로 선택한 뒤 `247540` 등 입력

## 구현 내용

Shiny 기반 UI와 서버 로직을 구성하고 `quantmod`를 활용해 Yahoo Finance에서 주가 데이터를 불러오도록 구현했습니다. `TTR` 패키지로 RSI와 볼린저밴드를 계산했으며, `plotly`를 사용해 인터랙티브 캔들차트를 제작했습니다.

또한 `htmlwidgets::onRender()`를 사용해 JavaScript 기능을 연결하고 사용자가 차트 위에 직접 선을 그렸을 때 해당 구간의 수익률이 자동으로 표시되도록 구현했습니다.

## 배운 점

이 프로젝트를 통해 R Shiny의 반응형 프로그래밍 구조, 금융 데이터 수집, 기술적 지표 계산, Plotly 기반 인터랙티브 시각화, R과 JavaScript 연동 방식을 학습했습니다.

