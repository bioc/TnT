# TnT
Jialin Ma  
January 31, 2017  




This is a R package that wraps the tnt javascript library (https://github.com/tntvis).
It can provide tree- and track-based visulizations, including a simple genome browser.
You can install it by

```r
if (!require(devtools)) {
    install.packages('devtools')
    require(devtools)
}
devtools::install_github("marlin-na/TnT")
```









This package is currently in development, but the following snippet of code may
illustrate the way of using:


```r
library(TnT)
mydata1 <- data.frame (
    start = c(42, 69, 233),
    end = c(54, 99, 250)
)
mydata2 <- data.frame(
    start = c(23, 66, 300),
    end = c(38, 74, 318)
)
tnt_board(from = 14, to = 114, min = -100, max = 500) %>%
    add_track_block(mydata1, label = "My Track 1") %>%
    add_track_block(mydata2, label = "My Track 2", color.feature = "green") %>%
    TnT()
```

<!--html_preserve--><div id="htmlwidget-b62e91a61515c3521e2f" style="width:672px;height:480px;" class="TnT html-widget"></div>
<script type="application/json" data-for="htmlwidget-b62e91a61515c3521e2f">{"x":{"tntdef":"tnt.board()\n.from(14)\n.to(114)\n.min(-100)\n.max(500)\n.allow_drag(true)\n.add_track(tnt.board.track()\n.color('white')\n.height(20)\n.display(tnt.board.track.feature.location()))\n.add_track(tnt.board.track()\n.height(0)\n.display(tnt.board.track.feature.axis()\n.orientation('top')))\n.add_track(tnt.board.track()\n.color('white')\n.height(40)\n.label('My Track 1')\n.data(tnt.board.track.data.sync()\n.retriever(function () {  return [{\"start\":42,\"end\":54},{\"start\":69,\"end\":99},{\"start\":233,\"end\":250}]  }))\n.display(tnt.board.track.feature.block()\n.color('black')))\n.add_track(tnt.board.track()\n.color('white')\n.height(40)\n.label('My Track 2')\n.data(tnt.board.track.data.sync()\n.retriever(function () {  return [{\"start\":23,\"end\":38},{\"start\":66,\"end\":74},{\"start\":300,\"end\":318}]  }))\n.display(tnt.board.track.feature.block()\n.color('green')))"},"evals":["tntdef"],"jsHooks":[]}</script><!--/html_preserve-->



## Technical Notes

### TnT libraries

TnT is a set of javascript visualization libraries that include a simple genome
browser, you can see http://tntvis.github.io/tnt.genome/index.html for what it may
achieve. The aim of this package is to wrap the TnT libraries into R so that we
can eaisly create interactive track-based visulization in Rmarkdown and shiny apps
using data from R environment (as the example above).

### htmlwidgets

This package is based on the htmlwidgets framework to wrap the TnT library into
R, you can find some great packages that utilizes htmlwidgets
at [here](http://www.htmlwidgets.org/showcase_leaflet.html). Packages that are
based on htmlwidgets can be used in Rmarkdown files and shiny webapps. 

### TnT api

Basicly, the creation of a tnt component need a definition about the component
as a javascript function cascade,
which includes the general properties, track properties, track data, etc. For the
TnT board library, you can find documentation of the these api at 
http://tntvis.github.io/tnt.board/api/board/index.html .

For example, the following is the definition of the tnt board at the beginning of
this page.

```js
tnt.board()
.from(14)
.to(114)
.min(-100)
.max(500)
.allow_drag(true)
.add_track(tnt.board.track()
           .color('white')
           .height(20)
           .display(tnt.board.track.feature.location()))
.add_track(tnt.board.track()
           .height(0)
           .display(tnt.board.track.feature.axis()
                    .orientation('top')))
.add_track(tnt.board.track()
           .color('white')
           .height(40)
           .label('My Track 1')
           .data(tnt.board.track.data.sync()
                 .retriever(function () {
                     return [{"start":42,"end":54},{"start":69,"end":99},{"start":233,"end":250}]
                 }))
           .display(tnt.board.track.feature.block()
                    .color('black')))
.add_track(tnt.board.track()
           .color('white')
           .height(40)
           .label('My Track 2')
           .data(tnt.board.track.data.sync()
                 .retriever(function () {
                     return [{"start":23,"end":38},{"start":66,"end":74},{"start":300,"end":318}]
                 }))
           .display(tnt.board.track.feature.block()
                    .color('green')))
```

### Pass information from R to JS

Based on the fact that definition of tnt components are linked by javascript functions
with mostly single argument (either numeric, character or another function result),
I decided to use a somehow "violent" approach to pass information/data from R side
to javascript side -- to directly generate this character string as javascript code
and pass it to javascript side.

For example,


```r
tntdef <-
"
  tnt.board()
  .from(14)
  .to(114)
  .min(-100)
  .max(500)
  .allow_drag(true)
  .add_track(tnt.board.track()
             .color('white')
             .height(20)
             .display(tnt.board.track.feature.location()))
  .add_track(tnt.board.track()
             .height(0)
             .display(tnt.board.track.feature.axis()
                      .orientation('top')))
  .add_track(tnt.board.track()
             .color('white')
             .height(40)
             .label('My Track 1')
             .data(tnt.board.track.data.sync()
                   .retriever(function () {
                       return [{'start':42,'end':54},{'start':69,'end':99},{'start':233,'end':250}]
                   }))
             .display(tnt.board.track.feature.block()
                      .color('black')))
  .add_track(tnt.board.track()
             .color('white')
             .height(40)
             .label('My Track 2')
             .data(tnt.board.track.data.sync()
                   .retriever(function () {
                       return [{'start':23,'end':38},{'start':66,'end':74},{'start':300,'end':318}]
                   }))
             .display(tnt.board.track.feature.block()
                      .color('green')))
"
TnT(tntdef)
```

<!--html_preserve--><div id="htmlwidget-038dc4155233abfd7a34" style="width:672px;height:480px;" class="TnT html-widget"></div>
<script type="application/json" data-for="htmlwidget-038dc4155233abfd7a34">{"x":{"tntdef":"\n  tnt.board()\n  .from(14)\n  .to(114)\n  .min(-100)\n  .max(500)\n  .allow_drag(true)\n  .add_track(tnt.board.track()\n             .color('white')\n             .height(20)\n             .display(tnt.board.track.feature.location()))\n  .add_track(tnt.board.track()\n             .height(0)\n             .display(tnt.board.track.feature.axis()\n                      .orientation('top')))\n  .add_track(tnt.board.track()\n             .color('white')\n             .height(40)\n             .label('My Track 1')\n             .data(tnt.board.track.data.sync()\n                   .retriever(function () {\n                       return [{'start':42,'end':54},{'start':69,'end':99},{'start':233,'end':250}]\n                   }))\n             .display(tnt.board.track.feature.block()\n                      .color('black')))\n  .add_track(tnt.board.track()\n             .color('white')\n             .height(40)\n             .label('My Track 2')\n             .data(tnt.board.track.data.sync()\n                   .retriever(function () {\n                       return [{'start':23,'end':38},{'start':66,'end':74},{'start':300,'end':318}]\n                   }))\n             .display(tnt.board.track.feature.block()\n                      .color('green')))\n"},"evals":["tntdef"],"jsHooks":[]}</script><!--/html_preserve-->

In the example above, the character vector `tntdef` is passed from R side to JS side as
an option of the htmlwidgets framework (by `TnT` function).
The JS side is handled at [inst/htmlwidgets/TnT.js](inst/htmlwidgets/TnT.js), which
is simply `eval` and initiated (only three lines of code).


### Model the api

If based on my approach obove, the goal of this package is to provide functions
that can generate these javascript code from common R function calls. But first,
I consider it would be better to model the api on R side. I use a list structure
to model the api -- name as the js function name, list body as argument of
the js function, then assign class attribute and provide methods to make it a S3 
object. I name this class "JScascade".

For example,


```r
myjc <- JScascade(
    tnt.board = NULL,
    from = 0,
    to = 500,
    min = 50,
    max = 1000,
    width = 500,
    add_track = JScascade(
        tnt.board.track = NULL,
        height = 20,
        color = "white",
        display = JScascade(tnt.board.track.feature.axis = NULL)
    ),
    add_track = JScascade(
        tnt.board.track = NULL,
        height = 30,
        color = "yellow",
        data = JScascade(
            tnt.board.track.data.sync = NULL,
            retriever = JS("function() {return [{start : 200, end : 350}]}")
        ),
        display = JScascade(
            tnt.board.track.feature.block = NULL,
            color = "blue",
            index = JS("function (d) {return d.start}")
        )
    )
) 
myjc
```

```
## Javascript function cascade:
##        js_functions       arguments
## step 1    tnt.board                
## step 2         from               0
## step 3           to             500
## step 4          min              50
## step 5          max            1000
## step 6        width             500
## step 7    add_track <S3: JScascade>
## step 8    add_track <S3: JScascade>
## ---------
## You can use 'asJS' to convert it to javascript code
```

It is essentially a list:


```r
str(myjc)
```

```
## List of 8
##  $ tnt.board: NULL
##  $ from     : num 0
##  $ to       : num 500
##  $ min      : num 50
##  $ max      : num 1000
##  $ width    : num 500
##  $ add_track:List of 4
##   ..$ tnt.board.track: NULL
##   ..$ height         : num 20
##   ..$ color          : chr "white"
##   ..$ display        :List of 1
##   .. ..$ tnt.board.track.feature.axis: NULL
##   .. ..- attr(*, "class")= chr "JScascade"
##   ..- attr(*, "class")= chr "JScascade"
##  $ add_track:List of 5
##   ..$ tnt.board.track: NULL
##   ..$ height         : num 30
##   ..$ color          : chr "yellow"
##   ..$ data           :List of 2
##   .. ..$ tnt.board.track.data.sync: NULL
##   .. ..$ retriever                :Class 'JS_EVAL'  chr "function() {return [{start : 200, end : 350}]}"
##   .. ..- attr(*, "class")= chr "JScascade"
##   ..$ display        :List of 3
##   .. ..$ tnt.board.track.feature.block: NULL
##   .. ..$ color                        : chr "blue"
##   .. ..$ index                        :Class 'JS_EVAL'  chr "function (d) {return d.start}"
##   .. ..- attr(*, "class")= chr "JScascade"
##   ..- attr(*, "class")= chr "JScascade"
##  - attr(*, "class")= chr "JScascade"
```


A "JScascade" object can be easily converted to javascript code using function `asJS`.
For example,


```r
asJS(myjc)
```

```
## tnt.board()
## .from(0)
## .to(500)
## .min(50)
## .max(1000)
## .width(500)
## .add_track(tnt.board.track()
## .height(20)
## .color('white')
## .display(tnt.board.track.feature.axis()))
## .add_track(tnt.board.track()
## .height(30)
## .color('yellow')
## .data(tnt.board.track.data.sync()
## .retriever(function() {return [{start : 200, end : 350}]}))
## .display(tnt.board.track.feature.block()
## .color('blue')
## .index(function (d) {return d.start})))
```

And it can be directly utilized by `TnT` function:


```r
TnT(myjc)
```

<!--html_preserve--><div id="htmlwidget-311e5f269f5412d17957" style="width:672px;height:480px;" class="TnT html-widget"></div>
<script type="application/json" data-for="htmlwidget-311e5f269f5412d17957">{"x":{"tntdef":"tnt.board()\n.from(0)\n.to(500)\n.min(50)\n.max(1000)\n.width(500)\n.add_track(tnt.board.track()\n.height(20)\n.color('white')\n.display(tnt.board.track.feature.axis()))\n.add_track(tnt.board.track()\n.height(30)\n.color('yellow')\n.data(tnt.board.track.data.sync()\n.retriever(function() {return [{start : 200, end : 350}]}))\n.display(tnt.board.track.feature.block()\n.color('blue')\n.index(function (d) {return d.start})))"},"evals":["tntdef"],"jsHooks":[]}</script><!--/html_preserve-->


Other functions in this package are aimmed at this class and provide ways to create/combine
`JScascade` objects.


### Further

Currently I have only wrapped the
[tnt board api](http://tntvis.github.io/tnt.board/api/board/index.html) and provide
limited user-side functions. This package further need to wrap other tnt libraries
(tnt genome, tnt tooltip, etc.) and provide more user-side
functions to help easily convert R/bioconductor data into tnt components.
Also, for visulization of large datasets in shiny app, consider how to serve
the data on the server-side (like the `DT` package).


