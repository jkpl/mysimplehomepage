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

First, place all your Markdown files in the `pages` directory. These files will
be used for generating the content of the site. Place all your templates in the
`templates` directory. All the Stylus stylesheets and CoffeeScript and
JavaScript files should be places to the `static` directory. You can customize
these paths in the `configuraton.json` file, if you like. You should have
atleast one template and one Markdown file for this to work. The directory
structure in `pages` and `static` directories will remain the same in the
output directory, so you can, for example, place all your stylesheets in
`static/css/` and they will appear in `out/css/`.

Each Markdown file should be in this kind of format:

    "id": "index",
    "title": "Home",
    "template": "default",
    "mydata": "Some data I'd like to use in this specific page."
    
    ---
    # Here is the actual Markdown portion
    
    ...
    
The `---` line acts as a separator for the page metadata and the page
body. Everything before the separator is interpreted as a JSON object, and the
rest is interpreted as Markdown. You can add pretty much any JSON data you
want, but just be sure you have atleast specified an ID for the page. If you
don't specify a template, the template named `default` is used. The JSON object
is passed to the template engine when the page is rendered. Here's a full list
of what you have access to in the templates:

* **site**: site wide data (`sitedata` in the configuration file)
* **allpages**: all the pages with their metadata and body intact
* **page**: the data from the Markdown file
  * **id**: the ID for the page
  * **body**: the page contents
* **static**: all the static files

Once the `configuration.json` has been configured, and the files are in place
run the Cakefile's `build` task to build your site. The generated files will be
placed to the output directory (default: `out/`).  If you want to use files
like images with your site, just place them to the output directory.

There's also a feature built in the Cakefile for monitoring changes in the
source files. If you run the Cakefile task `watch`, the program will
automatically generate the site after you change any of the source files. If
you have `node-static` installed, the program will launch a web server that
serves files from the output directory. The default port for the test server is
3030.

## Configuration

You can change any of the configurations in the `configuration.json` file.

* **sitedata**: site wide data
* **paths**
  * **staticfiles**: directory for static files such as Stylus stylesheets and
      JavaScript files.
  * **pagesdir**: directory for the Markdown files
  * **templatesdir**: directory for the Jade templates
  * **outputdir**: the directory where all the generated files are placed to
* **testserverport**: the port for the test web server


## License

Copyright (c) 2012, Jaakko Pallari
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[homepage]: http://jkpl.lepovirta.org/
[nodejs]: http://nodejs.org/
[npm]: http://npmjs.org/
[coffee-script]: http://coffeescript.org/
[jade]: https://github.com/visionmedia/jade
[stylus]: https://github.com/learnboost/stylus
[node-markdown]: https://github.com/andris9/node-markdown
[node-static]: https://github.com/cloudhead/node-static
[docco]: http://jashkenas.github.com/docco/
[highlight]: https://github.com/andris9/highlight
