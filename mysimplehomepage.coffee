{exec} = require 'child_process'
fs     = require 'fs'
path   = require 'path'
jade   = require 'jade'
stylus = require 'stylus'
md     = require('node-markdown').Markdown

# Object cloning
clone = (obj) ->
  return obj if obj is null or typeof (obj) isnt "object"
  temp = obj.constructor()
  for key of obj
    temp[key] = clone obj[key]
  temp

exports.sitebuilder = (conffilepath) ->
  sb = {}
  compilers = {}
  conf = JSON.parse(fs.readFileSync(conffilepath))

  # Paths
  paths = do ->
    obj = {}
    for k of conf.paths
      obj[k] = path.resolve path.join '.', conf.paths[k]
    obj
  sb.pathList = (paths[k] for k of paths)
  sb.watchDirs = do ->
    dirs = (paths[k] for k of paths when k isnt 'outputdir')
    dirs.push '.'
    dirs

  # Helper functions
  readfile = (fpath) -> fs.readFileSync(fpath).toString()

  # Compilers for static files
  compilers.styl = (fname) ->
    outname = fname.replace /\.styl/, '.css'
    outpath = path.join paths.outputdir, 'css', outname
    content = readfile path.join paths.staticfiles, fname

    stylus(content).set('filename', outname).render (err, css) ->
      throw err if err
      if not path.existsSync path.join paths.outputdir, 'css'
        fs.mkdirSync path.join paths.outputdir, 'css'
      fs.writeFileSync outpath, css

    ['css', outname]

  # Compiles a single static file
  compileStaticfile = (fname) ->
    ext = (path.extname fname).slice(1)
    if ext of compilers
      compilers[ext](fname)
    else
      null

  # Compile all the static files, and returns the relative paths to them
  compileAllStaticfiles = ->
    obj = {}
    staticfiles = fs.readdirSync paths.staticfiles
    for fname in staticfiles
      result = compileStaticfile fname
      if result
        category = result[0]
        p = result[1]
        if not obj[category] then obj[category] = []
        obj[category].push('/' + category + '/' + p)
    obj

  # Compiles one Jade templating function from file
  compileTemplate = (fname) ->
    content = readfile fname
    jade.compile content

  # Compiles Jade templating functions
  compileAllTemplates = ->
    obj = {}
    templatefiles = fs.readdirSync paths.templatesdir
    for fname in templatefiles
      fullpath = path.join paths.templatesdir, fname
      ext = path.extname fname
      if ext is '.jade'
        idname = path.basename fname, '.jade'
        obj[idname] = compileTemplate fullpath
    obj

  # Compiles a single page
  compilePage = (page, staticfiles, templates) ->
    fullpath = path.join paths.pagesdir, page.file
    tmpl = templates[page.template]
    outpath = path.join paths.outputdir, page.outfilepath

    sitedata = clone conf.sitedata
    sitedata.content = page.pagedata
    sitedata.static = staticfiles
    sitedata.content.body = md(readfile fullpath)

    html = tmpl sitedata
    fs.writeFileSync outpath, html

  # Compiles all the pages
  compileAllPages = (staticfiles, templates) ->
    compilePage page, staticfiles, templates for page in conf.pages
    null

  # Launches a test server
  sb.launchTestServer = ->
    console.log 'launching test server on port', conf.testserverport
    try
      node_static = require 'node-static'
      file = new(node_static.Server)(paths.outputdir)
      server = require('http').createServer (req, res) ->
        req.addListener 'end', ->
          file.serve req, res
      server.listen conf.testserverport
    catch error
      console.log "Couldn't launch test server:", error.message

  # The actual builder function
  sb.build = ->
    if not path.existsSync paths.outputdir
      console.log 'output dir not found. creating...'
      fs.mkdirSync paths.outputdir

    console.log 'compiling static files...'
    staticfiles = compileAllStaticfiles()

    console.log 'compiling templates...'
    templates = compileAllTemplates()

    console.log 'compiling pages..'
    compileAllPages staticfiles, templates

  # Watch directories for changes
  sb.watch = () ->
    console.log 'watching files for changes...'
    for p in sb.watchDirs
      fs.watch p, { persistent: true }, (event, fname) ->
        if event is 'change'
          console.log 'change found in', fname
          try
            sb.build()
          catch error
            console.log "** Error:"
            console.log error.stack

  return sb

