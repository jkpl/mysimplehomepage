# mysimplehomepage

This is a really, really simple static website generator I made using various
Node.JS modules. I use this to generate my [homepage][].

## Requirements

For generating your own website, you need [Node.JS][nodejs] and the following
modules (you can install them with [npm][]).

* [coffee-script][], for running the Cakefile
* [jade][], for generating templates
* [stylus][], for generating stylesheets
* [node-markdown][], for generating content from Markdown files
* [node-static][], for running a test server (optional)

## So here's how it works...

In the `configuration.json` file, list all the files you want to use for
generating your site in the subobject `files`, and place the files to the input
directory (default `in/`). The `sitedata` object will be passed to each
template, so you can define your own template variables there.

The files listed in `markdown` will be rendered to HTML, and placed to
`sitedata.content` object. For example, a Markdown file named `mycontent.md`
can be found from `sitedata.content.mycontent` after compilation. The files
listed in `plain` will be handled just like the Markdown files, except that
there is no rendering process.

Once the `configuration.json` has been configured, and the files are in place
run the Cakefile's `build` task to build your site. The generated files will be
placed to the output directory (default: `out/`).  If you want to use files
like images with your site, just place them to the output directory.

There's also a feature built in the Cakefile for monitoring changes in the
source files. If you run the Cakefile task `watch`, the program will
automatically generate the site after you change any of the source files. If
you have `node-static` installed, the program will launch a web server that
serves files from the output directory. The default port for the test server is 3030.

## Configuration

You can change any of the configurations in the `configuration.json` file.

* **sitedata**: all the variables that are passed to the templates
* **files**: files used for generating the site
    * **markdown**: Markdown files
    * **templates**: Jade files
    * **stylesheets**: Stylus files
    * **plain**: HTML or plain text files
* **inputdir**: the directory where the files are located
* **outputdir**: the directory where the generated files will be placed
* **testserverport**: the port for the test web server

# TODO

* A support for generating Javascript files from CoffeeScript files.

[homepage]: http://jkpl.lepovirta.org/
[nodejs]: http://nodejs.org/
[npm]: http://npmjs.org/
[coffee-script]: http://coffeescript.org/
[jade]: https://github.com/visionmedia/jade
[stylus]: https://github.com/learnboost/stylus
[node-markdown]: https://github.com/andris9/node-markdown
[node-static]: https://github.com/cloudhead/node-static
