class Dashing.Number extends Dashing.Widget
  @accessor 'current', Dashing.AnimatedValue

  @accessor 'difference', ->
    if @get('last')
      precision = parseInt(@get('diffprecision'))
      last = if precision then parseFloat(@get('last')) else parseInt(@get('last'))
      current = if precision then parseFloat(@get('current')) else parseInt(@get('current'))
      if last != 0
        diff = Math.abs((current - last) / last * 100)
        diff = Math.round(diff) unless precision
        if precision
          "#{diff.toFixed(precision)}%"
        else
          "#{diff}%"
    else
      ""

  @accessor 'arrow', ->
    if @get('last')
      precision = parseInt(@get('diffprecision'))
      last = if precision then parseFloat(@get('last')) else parseInt(@get('last'))
      current = if precision then parseFloat(@get('current')) else parseInt(@get('current'))
      if current == last
        'icon-ellipsis-horizontal'
      else
        if current > last then 'icon-arrow-up' else 'icon-arrow-down'

  onData: (data) ->
    if data.status
      # clear existing "status-*" classes
      $(@get('node')).attr 'class', (i,c) ->
        c.replace /\bstatus-\S+/g, ''
      # add new class
      $(@get('node')).addClass "status-#{data.status}"
