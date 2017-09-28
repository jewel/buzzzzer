socket = null

context = new (window.AudioContext || window.webkitAudioContext)()
buffers = {}

play = (name) ->
  source = context.createBufferSource()
  source.buffer = buffers[name]
  source.connect context.destination
  source.start 0

loadSound = (name) ->
  req = new XMLHttpRequest()
  req.open "GET", "/#{name}.wav", true
  req.responseType = 'arraybuffer'
  req.onload = =>
    data = req.response
    context.decodeAudioData data, (buffer) =>
      buffers[name] = buffer
      play 'start' if name == 'start'
  req.send()

loadSound 'start'
loadSound 'tap0'
loadSound 'tap1'
loadSound 'tap2'
loadSound 'clear0'
loadSound 'clear1'
loadSound 'clear2'

names = []

tapped = false

current = null

player_name = ->
  $('#name').val()

reconnect = ->
  socket = io.connect window.location.href

  socket.on 'update', (obj) ->
    if obj.sound
      play obj.sound

    current = obj.current

    if obj.current == player_name()
      if tapped
        tapped = false
        try
          navigator.vibrate 200

      $('body').addClass 'current'
    else
      $('body').removeClass 'current'

    $('#names').empty()
    seen = false
    for name in obj.names
      name_cell = $('<td>').text name
      row = $('<tr>')
        .append(name_cell)
        .appendTo( '#names' )

      if name == obj.current
        row.addClass 'current'
        seen = true
    if !seen && current
      name_cell = $('<td>').text current
      name_cell.css 'background', 'red'
      row = $('<tr>')
        .append(name_cell)
        .appendTo( '#names' )

  socket.on 'connect', ->
    socket.emit 'update',
      name: player_name()
      tap: false

$('#name').on 'change keyup', ->
  localStorage.setItem 'name', player_name()
  socket.emit 'update',
    name: player_name()
    tap: false

try
  $('#name').val( localStorage.getItem('name') )

reconnect()

tap = (e) ->
  return if e.target.tagName == 'INPUT'
  e.preventDefault()
  tapped = true

  try
    navigator.vibrate 50

  try
    socket.emit 'update',
      name: player_name()
      tap: true

stopMouse = false
$('html').on 'mousedown', (e) ->
  return if stopMouse
  tap e

$('html').on 'touchstart', (e) ->
  stopMouse = true
  tap e
