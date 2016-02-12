React = window.React = require("react")
ReactDOM = require("react-dom")
Timer = require("./ui/Timer.coffee")
mountNode = document.getElementById("app")


{div, h4, pre, code, span} = React.DOM


LogLine = React.createClass(
    displayName: "LogLine"
    getInitialState: ->
        {}

    render: ->
        cls = if @props.selected
            "col-sm-12 btn-primary"
        else
            "col-sm-12"

        React.createElement "div",
            className: "row"
            onClick: @onClick,
            React.createElement "span",
                className: cls,
                @props.absolutePath

    onClick: ->
        @props.select(@props.absolutePath)
)

LogfileList = React.createClass(
  displayName: "LogfileList"

  getInitialState: ->
    selected: null

  select: (item) ->
      @setState
        selected: item
      @props.select(item)

  render: ->
    createItem = (absolutePath) =>
        React.createElement LogLine,
            key: absolutePath,
            absolutePath: absolutePath,
            selected: @state.selected == absolutePath
            select: (absolutePath) => @select(absolutePath)
            null

    React.createElement "div",
        null,
        @props.items.map(createItem)
)

LogfileShow = React.createClass
    displayName: "LogfileShow"
    getInitialState: ->
        content: "-- select a file --"
        sources: []

    componentWillReceiveProps: (nextProps, nextContent) ->
        this.serverRequest = $.get "api/1/files" +  nextProps.item, (result) =>
            rex = /\n/g
            json = "[" + result.replace(rex, ",\n") + "{}]"
            parsed_result = $.parseJSON(json)
            sources = []
            parsed_result.forEach (it) ->
                sources.push(it.source) if !sources.includes(it.source) && it.source

            this.setState
                content: result
                sources: sources
            console.log sources

    componentWillUnmount: ->
        this.serverRequest.abort()


    render: ->
        createFilters = (filter) ->
            React.createElement "div",
                className: "col-md-3",
                key: filter,
                filter

        div className: "row",
            h4(null, @props.item),
            div className: "filter row",
                span className: "col-md-2",
                    "Filters",
                @state.sources.map(createFilters),
            div className: "row",
                pre null,
                    code null, @state.content


LogList = React.createClass(
  displayName: "LogList"
  getInitialState: ->
    selected: "foo"
    items: []
    text: ""

  componentDidMount: ->
    this.serverRequest = $.get "/api/1/list", "json", (result) =>
        this.setState
            text: @state.text
            items: result.files

  componentWillUnmount: ->
    this.serverRequest.abort()

  onChange: (e) ->
    @setState text: e.target.value
    return

  handleSubmit: (e) ->
    e.preventDefault()
    nextItems = @state.items.concat([@state.text])
    nextText = ""
    @setState
      items: nextItems
      text: nextText

    return

  select: (item) -> @setState selected:item

  render: ->
    React.createElement "div",
        className: "row",
        React.createElement "div",
            className: "col-sm-12 col-md-3",
            React.createElement(LogfileList,
              select: (item) => @select(item)
              items: @state.items
            ),
        React.createElement "div",
            className: "col-sm-12 col-md-8",
            React.createElement(LogfileShow,
                item: @state.selected
            )
)


ReactDOM.render React.createElement(LogList, null), mountNode
