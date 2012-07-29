{spawn} = require 'child_process'
fs     = require 'fs'
path   = require 'path'
jade   = require 'jade'
stylus = require 'stylus'
md     = require('node-markdown').Markdown
mkdirp = require 'mkdirp'

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
  if not path.existsSync dir then mkdirp.sync dir
  fs.writeFileSync fpath, content

# Traverse a directory recursively, calling `callback` for each found file. The
# callback receives the file path and file stats as a parameter.
traverseDirRecursive = (dir, callback) ->
  files = fs.readdirSync dir
  dirs = []
  for file in files
    fpath = path.join dir, file
    try
      stats = fs.lstatSync fpath
      if stats.isDirectory()
        dirs.push file
      callback fpath, stats
    catch err
      console.log err
  if dirs.length
    traverseDirRecursive path.join(dir, d), callback for d in dirs

# Calls `callback` for each file (not symbolic links or directories) in
# provided directory.
processFiles = (dir, callback) ->
  traverseDirRecursive dir, (fpath, stats) ->
    if not stats.isSymbolicLink() and not stats.isDirectory()
      callback fpath

# Calls `callback` for each directory in provided directory.
processDirectories = (dir, callback) ->
  traverseDirRecursive dir, (fpath, stats) ->
    if stats.isDirectory()
      callback fpath

parseConfig = (configstr) ->
  JSON.parse "{" + configstr + "}"

# The site builder
exports.sitebuilder = (conffilepath) ->
  that = {}
  compilers = {}
  conf = JSON.parse(fs.readFileSync(conffilepath))
  that.watchDirs = do ->
    dirs = ['.']
    processDir = (path) ->
      dirs.push path
      processDirectories path, (fpath) -> dirs.push fpath
    processDir v for k, v of conf.paths when k isnt 'outputdir'
    dirs

  # Compilers for static files
  that.compilers =
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
        if not path.existsSync dir then mkdirp.sync dir
        ws = fs.createWriteStream outpath
        ps = spawn 'coffee', ['-sc']
        ps.stdout.pipe ws
        ps.stderr.on 'data', (d) -> console.log d.toString()
        ps.stdin.write content
        ps.stdin.end()

  # Compiles all the static files
  compileStaticfiles = ->
    obj = {}
    processFiles conf.paths.staticfiles, (fpath) ->
      relativepath = path.relative conf.paths.staticfiles, fpath
      ext = path.extname fpath
      content = readfile fpath
      if ext.slice(1) of that.compilers
        c = that.compilers[ext.slice(1)]
        outname = path.basename(relativepath, ext) + ".#{c.to}"
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
    processFiles conf.paths.templatesdir, (fpath) ->
      relativepath = path.relative conf.paths.staticfiles, fpath
      ext = (path.extname fpath).slice(1)
      if ext is 'jade'
        idname = path.basename fpath, '.jade'
        content = readfile fpath
        obj[idname] = jade.compile content
    obj

  # Compiles all the pages
  compileAllPages = (staticfiles, templates) ->
    pages = {}
    processFiles conf.paths.pagesdir, (fpath) ->
      page = parsePage fpath
      if page then pages[page.id] = page
    for k of pages
      page = pages[k]
      tmpl = templates[page.template]
      outpath = path.join conf.paths.outputdir, page.url
      sitedata =
        site: conf.sitedata
        allpages: pages
        page: page
        static: staticfiles
      html = tmpl sitedata
      writefile outpath, html

  # Parses a page from a single file
  parsePage = (fpath) ->
    file = readfile(fpath).split('\n---\n')
    if file.length < 2 then return null
    page = parseConfig file[0]
    page.body = md file.slice(1).join('\n')
    ext = path.extname fpath
    relativepath = path.relative conf.paths.pages, fpath
    page.url = "/" + path.basename(relativepath, ext) + ".html"
    if not page.template then page.template = "default"
    page

  # Launches a test server
  that.launchTestServer = ->
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
  that.build = ->
    if not path.existsSync conf.paths.outputdir
      console.log 'output dir not found. creating...'
      mkdir.sync conf.paths.outputdir

    console.log 'compiling static files...'
    staticfiles = compileStaticfiles()

    console.log 'compiling templates...'
    templates = compileTemplates()

    console.log 'compiling pages..'
    compileAllPages staticfiles, templates

  # Watch directories for changes
  that.watch = () ->
    console.log 'watching files for changes...'
    for p in that.watchDirs
      fs.watch p, { persistent: true }, (event, fname) ->
        if event is 'change'
          console.log 'change found in', fname
          try
            that.build()
          catch error
            console.log "** Error:"
            console.log error.stack

  # Return the final object
  that
