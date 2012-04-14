{exec} = require 'child_process'
fs     = require 'fs'
path   = require 'path'
jade   = require 'jade'
stylus = require 'stylus'
md     = require('node-markdown').Markdown

exports.sitebuilder = (conffilepath) ->
  sb = {}
  conf = JSON.parse(fs.readFileSync(conffilepath))
  allfiles = [].concat.apply([], (v for k, v of conf.files))
  sb.inbasepath = path.resolve path.join '.', (conf.inputdir or 'in')
  sb.outbasepath = path.resolve path.join '.', (conf.outputdir or 'out')
  sb.testServerPort = conf.testserverport or 3030

  sb.readFileToContent = (fname, cb) ->
    content = sb.readContentFromFile fname
    ext = path.extname fname
    basename = path.basename fname, ext
    conf.sitedata.content[basename] = cb content

  sb.compileStylus = (fname) ->
    outname = fname.replace /\.styl/, '.css'
    outpath = path.join sb.outbasepath, outname
    content = sb.readContentFromFile fname

    stylus(content).set('filename', outname).render (err, css) ->
      throw err if err
      fs.writeFileSync outpath, css

  sb.compileJade = (fname) ->
    outname = fname.replace /\.jade$/, '.html'
    outpath = path.join sb.outbasepath, outname
    content = sb.readContentFromFile fname

    jdfn = jade.compile content
    html = jdfn conf.sitedata
    fs.writeFileSync outpath, html

  sb.readContentFromFile = (fname) ->
    fs.readFileSync(path.join(sb.inbasepath, fname)).toString()

  sb.launchTestServer = () ->
    console.log 'launching test server on port', sb.testServerPort
    try
      node_static = require 'node-static'
      file = new(node_static.Server)(sb.outbasepath)
      server = require('http').createServer (req, res) ->
        req.addListener 'end', ->
          file.serve req, res
      server.listen sb.testServerPort
    catch error
      console.log "Couldn't launch test server:", error.message

  sb.build = () ->
    if not path.existsSync sb.outbasepath
      console.log 'output dir not found. creating...'
      fs.mkdirSync sb.outbasepath

    console.log 'compiling content files...'
    conf.files.markdown.forEach (fname) -> sb.readFileToContent fname, md
    conf.files.plain.forEach (fname) ->
      sb.readFileToContent fname, (data) -> data

    console.log 'compiling templates...'
    conf.files.templates.forEach sb.compileJade

    console.log 'compiling stylesheets...'
    conf.files.stylesheets.forEach sb.compileStylus

  sb.watch = () ->
    console.log 'watching files for changes...'
    fs.watch sb.inbasepath, { persistent: true }, (event, fname) ->
      if event is 'change' and fname in allfiles
        console.log 'change found in', fname
        try
          sb.build()
        catch error
          console.log "** Error:"
          console.log error.stack

  return sb

