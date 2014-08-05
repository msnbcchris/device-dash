class Dashing.Meter extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  constructor: ->
    super
    @observe 'value', (value) ->
      meter = $(@node).find(".meter")
      meter.val(value).trigger('change')
      if @get('criticalvalue')
        if parseInt(value) > @get('criticalvalue')
          statuscolor = "chartreuse"
        else
          statuscolor = "red"
        meter.trigger('configure',{"fgColor":statuscolor})

  ready: ->
    meter = $(@node).find(".meter")
    if @get('criticalvalue') then bgcolor = "black" else bgcolor = meter.css("background-color")
    meter.attr("data-bgcolor", bgcolor)
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()
