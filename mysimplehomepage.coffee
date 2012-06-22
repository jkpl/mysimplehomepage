{spawn} = require 'child_process'
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
  writefile = (fpath, content) ->
    dir = path.dirname fpath
    if not path.existsSync dir then fs.mkdirSync dir
    fs.writeFileSync fpath, content
  copyfile = (fname, category) ->
    outpath = path.join paths.outputdir, category, outname
    content = readfile path.join paths.staticfiles, fname
    writefile outpath, content
    [category, fname]
  staticfile = (fname, from, to, category, callback) ->
    re = new RegExp "\\.#{from}$"
    outname = fname.replace re, ".#{to}"
    outpath = path.join paths.outputdir, category, outname
    content = readfile path.join paths.staticfiles, fname
    callback outpath, content, outname
    [category, fname]

  # Compilers for static files
  sb.compilers =
    styl:
      to: 'css'
      category: 'css'
      callback: (outpath, content, outname) ->
        stylus(content).set('filename', outname).render (err, css) ->
          throw err if err
          writefile outpath, css
    css:
      copy: true
      category: 'css'
    js:
      copy: true
      category: 'js'
    coffee:
      to: 'js'
      category: 'js'
      callback: (outpath, content) ->
        dir = path.dirname outpath
        if not path.existsSync dir then fs.mkdirSync dir
        ws = fs.createWriteStream outpath
        ps = spawn 'coffee', ['-sc']
        ps.stdout.pipe ws
        ps.stderr.on 'data', (d) -> console.log d.toString()
        ps.stdin.write content
        ps.stdin.end()

  # Compiles a single static file
  compileStaticfile = (fname) ->
    ext = (path.extname fname).slice(1)
    if ext of sb.compilers
      c = sb.compilers[ext]
      if c.copy
        copyfile fname, c.category
      else
        staticfile fname, ext, c.to, c.category, c.callback
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
    writefile outpath, html

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

