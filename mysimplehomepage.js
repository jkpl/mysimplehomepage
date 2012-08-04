#!/usr/bin/env node

var conffile = 'configuration.json';

// Modules
var spawn = require('child_process').spawn,
    fs = require('fs'),
    path = require('path'),
    jade = require('jade'),
    md = require('node-markdown').Markdown,
    mkdirp = require('mkdirp'),
    Server, http, compilers = {};

// Optional modules
try {
  http = require('http');
  Server = require('node-static').Server;
} catch (err) {}


//// Helper functions

// Iterate through objects
var each = function(obj, callback) {
  for (var k in obj)
    if (Object.prototype.hasOwnProperty.call(obj, k))
      callback(k, obj[k], obj);
  return obj;
};

// Read a file, and return the contents as string
var readfile = function(fpath) {
  return fs.readFileSync(fpath).toString();
};

// Write contents to file
var writefile = function(fpath, content) {
  var dir = path.dirname(fpath);
  if (!path.existsSync(dir))
    mkdirp.sync(dir);
  fs.writeFileSync(fpath, content);
};

// Change file extension
var changeFileExtension = function(fpath, to_ext) {
  var ext = path.extname(fpath),
      outname = path.basename(fpath, ext) + "." + to_ext;
  return path.join(path.dirname(fpath), outname);
};

// Traverse a directory recursively, calling `callback` for each found
// file. The callback receives the file path and file stats as a parameter.
var traverseDirRecursive = function(dir, callback) {
  var files = fs.readdirSync(dir),
      dirs = [];
  files.forEach(function(file) {
    var fpath = path.join(dir, file), stats;
    try {
      stats = fs.lstatSync(fpath);
      if (stats.isDirectory())
        dirs.push(file);
      callback(fpath, stats);
    } catch (err) {
      console.log(err);
    }
  });
  if (dirs.length)
    dirs.forEach(function(d) {
      traverseDirRecursive(path.join(dir, d), callback);
    });
};

// Calls `callback` for each file (not symbolic links or directories) in
// provided directory.
var processFiles = function(dir, callback) {
  traverseDirRecursive(dir, function(fpath, stats) {
    if (!stats.isSymbolicLink() && !stats.isDirectory())
      callback(fpath);
  });
};

// Calls `callback` for each directory in provided directory.
var processDirectories = function(dir, callback) {
  traverseDirRecursive(dir, function(fpath, stats) {
    if (stats.isDirectory())
      callback(fpath);
  });
};

// The main function of the script
var run = function(args) {
  if (args.length < 2) return null;
  var mybuilder = sitebuilder(conffile, compilers);
  var printHelp = function() {
    var cmd = path.relative('.', args[1]);
    console.log([
      "Usage: " + cmd + " build|watch|serve\n",
      "where:",
      "  build: compile all the source files once",
      "  watch: watch source files for changes",
      "  serve: launch the test server"
    ].join('\n'));
  };
  switch(args[2]) {
  case "build":
    mybuilder.build();
    break;
  case "watch":
    mybuilder.launchTestServer();
    mybuilder.watch();
    break;
  case "serve":
    mybuilder.launchTestServer();
    break;
  default:
    printHelp();
    break;
  }
};

// The site builder
var sitebuilder = function(conffilepath, compilers) {
  var that = {compilers: compilers},
      conf = JSON.parse(fs.readFileSync(conffilepath)),
      pageConfigParser = configParser(),
      compileAllPages, compileStaticfiles, compileTemplates, parsePage;

  // Watch these directories for changes.
  that.watchDirs = (function() {
    var dirs = ['.'];
    each(conf.paths, function(key, val) {
      if (key !== 'outputdir') {
        dirs.push(val);
        processDirectories(val, function(fpath) {
          dirs.push(fpath);
        });
      }
    });
    return dirs;
  })();

  // Static file compiler: compiles all the static files or copies them to the
  // output directory.
  compileStaticfiles = function() {
    var obj = {};
    processFiles(conf.paths.staticfiles, function(fpath) {
      var relativepath = path.relative(conf.paths.staticfiles, fpath),
          ext = path.extname(fpath).slice(1),
          content = readfile(fpath),
          c = compilers[ext],
          compiler, outname, outpath;
      if (typeof c !== 'undefined') { // a compiler exists
        outname = changeFileExtension(relativepath, c.to);
        outpath = path.join(conf.paths.outputdir, outname);
        c.compiler(outpath, content);
        if (!obj[c.to])
          obj[c.to] = [];
        obj[c.to].push("/" + outname);
      } else { // no compiler, copy files instead
        outpath = path.join(conf.paths.outputdir, relativepath);
        writefile(outpath, content);
        if (!obj[ext])
          obj[ext] = [];
        obj[ext].push("/" + relativepath);
      }
    });
    return obj;
  };

  // Template compiler: compiles all the Jade templates.
  compileTemplates = function() {
    var obj = {};
    processFiles(conf.paths.templatesdir, function(fpath) {
      var content, idname,
          relativepath = path.relative(conf.paths.staticfiles, fpath),
          ext = (path.extname(fpath)).slice(1);
      if (ext === 'jade') {
        idname = path.basename(fpath, '.jade');
        content = readfile(fpath);
        obj[idname] = jade.compile(content);
      }
    });
    return obj;
  };

  // Page compiler: compiles all the pages in pages directory.
  compileAllPages = function(staticfiles, templates) {
    var pages = {};
    processFiles(conf.paths.pagesdir, function(fpath) {
      var page = parsePage(fpath);
      if (page) pages[page.id] = page;
    });
    each(pages, function(k, page) {
      var tmpl = templates[page.template],
          outpath = path.join(conf.paths.outputdir, page.url);
      var sitedata = {
        site: conf.sitedata,
        allpages: pages,
        page: page,
        "static": staticfiles
      };
      writefile(outpath, tmpl(sitedata));
    });
  };

  // Page parser: parses a Markdown file for configurations and Markdown
  // content
  parsePage = function(fpath) {
    var ext, page, relativepath,
        file = readfile(fpath).split('\n---\n');
    if (file.length < 2) return null;
    page = pageConfigParser(file[0]);
    page.body = md(file.slice(1).join('\n'));
    ext = path.extname(fpath);
    relativepath = path.relative(conf.paths.pages, fpath);
    page.url = "/" + path.basename(relativepath, ext) + ".html";
    if (!page.template)
      page.template = "default";
    return page;
  };

  // Launches a test server.
  that.launchTestServer = function() {
    var fileserver, server;
    console.log('launching test server on port', conf.testserverport);
    try {
      fileserver = new Server(conf.paths.outputdir);
      server = http.createServer(function(req, res) {
        req.addListener('end', function() {
          fileserver.serve(req, res);
        });
      });
      server.listen(conf.testserverport);
    } catch (error) {
      console.log("Couldn't launch test server:", error.message);
    }
  };

  // Builds the whole project
  that.build = function() {
    var staticfiles, templates;
    if (!path.existsSync(conf.paths.outputdir)) {
      console.log('output dir not found. creating...');
      mkdirp.sync(conf.paths.outputdir);
    }

    console.log('compiling static files...');
    staticfiles = compileStaticfiles();

    console.log('compiling templates...');
    templates = compileTemplates();

    console.log('compiling pages...');
    compileAllPages(staticfiles, templates);
  };

  // Watches the watch directories for changes, and compiles the whole project
  // when changes are found.
  that.watch = function() {
    var p;
    console.log('watching files for changes...');
    that.watchDirs.forEach(function(p) {
      fs.watch(p, {persistent: true}, function(event, fname) {
        if (event === 'change') {
          console.log('change found in', fname);
          try {
            that.build();
          } catch (error) {
            console.log("** Error:", error.stack);
          }
        }
      });
    });
  };

  return that;
};

// Static file compilers
try {
  stylus = require('stylus');
  compilers.styl = {
    to: 'css',
    compiler: function(outpath, content) {
      var outname = path.basename(outpath);
      stylus(content).set('filename', outname).render(function(err, css) {
        if (err) throw err;
        writefile(outpath, css);
      });
    }
  };
} catch (err) {}
try {
  coffee = require('coffee-script');
  compilers.coffee = {
    to: 'js',
    compiler: function(outpath, content) {
      var output, dir = path.dirname(outpath);
      if (!path.existsSync(dir))
        mkdirp.sync(dir);
      output = coffee.compile(content);
      writefile(outpath, output);
    }
  };
} catch (err) {}

// A custom configuration parser
var configParser = function() {
  var kvparser, makeBuffer, parseConfig, valueParser;

  makeBuffer = function() {
    var that = {};
    that.id = null;
    that.buffer = null;

    that.init = function(newid, val) {
      that.id = newid;
      if (val !== void 0) {
        that.buffer = [val];
      } else {
        that.buffer = [];
      }
    };

    that.append = function(val) {
      that.buffer.push(val);
    };

    return that;
  };

  kvparser = function(configstr, callback) {
    var appendline, newkey, processline,
        buf = makeBuffer();

    newkey = function(match) {
      if (buf.id && buf.buffer.length > 0) {
        callback(buf.id, buf.buffer);
      }
      buf.init(match[1], match[2]);
    };

    appendline = function(match) {
      return buf.append(match[1]);
    };

    configstr.split('\n').forEach(function(line) {
      var m = line.match(/(\w+)\s*:(.*)$/);
      if (m) {
        newkey(m);
      } else {
        m = line.match(/[ ]{2}(.*)$/);
        if (m) appendline(m);
      }
    });
    callback(buf.id, buf.buffer);
  };

  valueParser = function(buffer) {
    if (buffer.length === 0) return undefined;
    var bufstr = buffer.join('\n').trim();
    try {
      return JSON.parse(bufstr);
    } catch (err) {
      return bufstr;
    }
  };

  return parseConfig = function(configstr) {
    var config = {};
    kvparser(configstr, function(id, buffer) {
      if (config[id] === void 0)
        config[id] = valueParser(buffer);
    });
    return config;
  };
};

// run it!
run(process.argv);