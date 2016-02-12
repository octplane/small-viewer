React = window.React = require("react")
ReactDOM = require("react-dom")
_ = require("lodash")
Timer = require("./ui/Timer.coffee")
mountNode = document.getElementById("app")


{div, h4, pre, code, span, td, tr, table, tbody} = React.DOM


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

PREFERED_FIELDS_ORDER = ['time', 'source', 'content']

LogfileShow = React.createClass
    displayName: "LogfileShow"
    getInitialState: ->
        content: "-- select a file --"
        sources: []
        fields: []
        data: []

    componentWillReceiveProps: (nextProps, nextContent) ->
        this.serverRequest = $.get "api/1/files" +  nextProps.item, (result) =>
            rex = /\n/g
            json = "[" + result.replace(rex, ",\n") + "{}]"
            parsed_result = $.parseJSON(json)
            sources = []
            fields = []

            _.each parsed_result, (it, ix) ->
                _.forEach Object.keys(it), (field) ->
                    fields.push(field) if !fields.includes(field)
                sources.push(it.source) if !sources.includes(it.source) && it.source

            this.setState
                sources: _.sortBy(sources)
                fields: _.sortBy(fields)
                data: parsed_result

    componentWillUnmount: ->
        this.serverRequest.abort()


    render: ->
        createFilters = (filter, ix) ->
            div className: "col-md-3", key: ix,
                filter

        createLine = (item, ix) ->
            tr key: ix,
                td className: "col-md-3", item.time
                td className: "col-md-1", item.source
                td className: "col-md-5", item.content

        div className: "row",
            h4(null, @props.item)
            div className: "filter row",
                span className: "col-md-2",
                    "Filters",
                @state.sources.map(createFilters)
            table className: "table-striped table-bordered",
                tbody null,
                    @state.data.map(createLine)


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
