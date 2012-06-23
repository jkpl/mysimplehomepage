{spawn} = require 'child_process'
fs     = require 'fs'
path   = require 'path'
jade   = require 'jade'
stylus = require 'stylus'
md     = require('node-markdown').Markdown

# Helper functions
clone = (obj) ->
  return obj if obj is null or typeof (obj) isnt "object"
  temp = obj.constructor()
  for key of obj
    temp[key] = clone obj[key]
  temp
readfile = (fpath) -> fs.readFileSync(fpath).toString()
writefile = (fpath, content) ->
  dir = path.dirname fpath
  if not path.existsSync dir then fs.mkdirSync dir
  fs.writeFileSync fpath, content

exports.sitebuilder = (conffilepath) ->
  sb = {}
  compilers = {}
  conf = JSON.parse(fs.readFileSync(conffilepath))
  sb.watchDirs = do ->
    dirs = (conf.paths[k] for k of conf.paths when k isnt 'outputdir')
    dirs.push '.'
    dirs

  # Compilers for static files
  sb.compilers =
    styl:
      to: 'css'
      compiler: (outpath, content) ->
        outname = path.basename outpath
        stylus(content).set('filename', outname).render (err, css) ->
          throw err if err
          writefile outpath, css
    coffee:
      to: 'js'
      compiler: (outpath, content) ->
        dir = path.dirname outpath
        if not path.existsSync dir then fs.mkdirSync dir
        ws = fs.createWriteStream outpath
        ps = spawn 'coffee', ['-sc']
        ps.stdout.pipe ws
        ps.stderr.on 'data', (d) -> console.log d.toString()
        ps.stdin.write content
        ps.stdin.end()

  # Processes a directory recursively and executes 'callback' for each found file.
  processDirectory = (dir, callback) ->
    files = fs.readdirSync dir
    dirs = []
    for file in files
      fpath = path.join dir, file
      stats = fs.statSync fpath
      if stats.isDirectory()
        dirs.push file
      else
        callback fpath
    if dirs.length
      processDirectory path.join(dir, d), callback for d in dirs

  # Compiles all the static files
  compileStaticfiles = ->
    obj = {}
    processDirectory conf.paths.staticfiles, (fpath) ->
      relativepath = path.relative conf.paths.staticfiles, fpath
      ext = (path.extname fpath).slice(1)
      content = readfile fpath
      if ext of sb.compilers
        c = sb.compilers[ext]
        re = new RegExp "\\.#{ext}$"
        outname = relativepath.replace re, ".#{c.to}"
        outpath = path.join conf.paths.outputdir, outname
        c.compiler outpath, content
        if not obj[c.to] then obj[c.to] = []
        obj[c.to].push "/#{outname}"
      else
        outpath = path.join conf.paths.outputdir, relativepath
        writefile outpath, content
        if not obj[ext] then obj[ext] = []
        obj[ext].push "/#{relativepath}"
    obj

  # Compiles Jade templating functions
  compileTemplates = ->
    obj = {}
    processDirectory conf.paths.templatesdir, (fpath) ->
      relativepath = path.relative conf.paths.staticfiles, fpath
      ext = (path.extname fpath).slice(1)
      if ext is 'jade'
        idname = path.basename fpath, '.jade'
        content = readfile fpath
        obj[idname] = jade.compile content
    obj

  # Compiles all the pages
  compileAllPages = (staticfiles, templates) ->
    urls = {}
    for page in conf.pages
      urls[page.id] =
        url: do ->
          ext = (path.extname page.file).slice(1)
          re = new RegExp "\\.#{ext}$"
          outname = page.file.replace re, ".html"
          "/#{outname}"
        title: page.title
    for page in conf.pages
      fullpath = path.join conf.paths.pagesdir, page.file
      if path.existsSync fullpath
        tmpl = templates[page.template]
        outpath = path.join conf.paths.outputdir, urls[page.id].url
        sitedata = {}
        sitedata.site = conf.sitedata
        sitedata.urls = urls
        sitedata.static = staticfiles
        sitedata.page =
          id: page.id
          title: page.title
          body: md readfile fullpath
          data: page.pagedata
        html = tmpl sitedata
        writefile outpath, html

  # Launches a test server
  sb.launchTestServer = ->
    console.log 'launching test server on port', conf.testserverport
    try
      node_static = require 'node-static'
      file = new(node_static.Server)(conf.paths.outputdir)
      server = require('http').createServer (req, res) ->
        req.addListener 'end', ->
          file.serve req, res
      server.listen conf.testserverport
    catch error
      console.log "Couldn't launch test server:", error.message

  # The actual builder function
  sb.build = ->
    if not path.existsSync conf.paths.outputdir
      console.log 'output dir not found. creating...'
      fs.mkdirSync conf.paths.outputdir

    console.log 'compiling static files...'
    staticfiles = compileStaticfiles()

    console.log 'compiling templates...'
    templates = compileTemplates()

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

  # Return the final object
  sb

