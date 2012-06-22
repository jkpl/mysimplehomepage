sb = require './mysimplehomepage.coffee'

conffile = 'configuration.json'

task 'build', 'compiles all the source files', ->
  mybuilder = sb.sitebuilder conffile
  mybuilder.build()

task 'watch', 'watches for source file changes', ->
  mybuilder = sb.sitebuilder conffile
  mybuilder.launchTestServer()
  mybuilder.watch()

task 'serve', 'launches the test server', ->
  mybuilder = sb.sitebuilder conffile
  mybuilder.launchTestServer()
