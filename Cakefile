{exec} = require 'child_process'
fs     = require 'fs'
path   = require 'path'
jade   = require 'jade'
stylus = require 'stylus'
md     = require('node-markdown').Markdown

conffile = 'configuration.json'
conf = JSON.parse(fs.readFileSync(conffile))
allfiles = [].concat.apply([], (v for k, v of conf.files))
inbasepath = path.resolve path.join '.', (if conf.inputdir then conf.inputdir else 'in')
outbasepath = path.resolve path.join '.', (if conf.outputdir then conf.outputdir else 'out')
testServerPort = if conf.testserverport then conf.testserverport else 3030

readFileToContent = (fname, cb) ->
  content = readContent fname
  ext = path.extname fname
  basename = path.basename fname, ext
  conf.sitedata.content[basename] = cb content

compileStylus = (fname) ->
  outname = fname.replace /\.styl/, '.css'
  outpath = path.join outbasepath, outname
  content = readContent fname

  stylus(content).set('filename', outname)
    .render (err, css) ->
      throw err if err
      fs.writeFileSync outpath, css

compileJade = (fname) ->
  outname = fname.replace /\.jade$/, '.html'
  outpath = path.join outbasepath, outname
  content = readContent fname

  jdfn = jade.compile content
  html = jdfn conf.sitedata
  fs.writeFileSync outpath, html

readContent = (fname) -> fs.readFileSync(path.join(inbasepath, fname)).toString()

launchTestServer = (port) ->
  try
    static = require 'node-static'
    file = new(static.Server)(outbasepath)
    server = require('http').createServer (req, res) ->
      req.addListener 'end', ->
        file.serve req, res
    server.listen port
  catch error
    console.log "Couldn't launch test server. Are you sure you have node-static installed?"

task 'build', 'compiles all the source files', ->
  if not path.existsSync outbasepath
    console.log 'output dir not found. creating...'
    fs.mkdirSync outbasepath

  console.log 'compiling content files...'
  conf.files.markdown.forEach (fname) -> readFileToContent fname, md
  conf.files.plain.forEach (fname) -> readFileToContent fname, (data) -> data

  console.log 'compiling templates...'
  conf.files.templates.forEach compileJade

  console.log 'compiling stylesheets...'
  conf.files.stylesheets.forEach compileStylus

task 'watch', 'watches for source file changes', ->
  console.log 'launching test server on port', testServerPort
  launchTestServer testServerPort

  console.log 'watching files for changes...'
  fs.watch inbasepath, { persistent: true }, (event, fname) ->
    if event is 'change' and fname in allfiles
      console.log 'change found in', fname
      invoke 'build'

