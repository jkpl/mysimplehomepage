# mysimplehomepage

This is a really, really simple static website generator I made using various
Node.JS modules. I use this to generate my [homepage][].

## Requirements

For rolling out your own website, you need to have [Node.JS][nodejs] and
[npm][] installed. Also, the following packages need to installed locally:

* [jade][], for generating templates
* [node-markdown][], for generating content from Markdown files
* [mkdirp][], for creating a bunch of directories

mysimplehomepage can also use these modules if they are available:

* [stylus][], for compiling Stylus stylesheets into CSS
* [coffee-script][], for compiling CoffeeScript scripts
* [node-static][], for running a test server

## So here's how it works...

If you haven't installed the modules above, install them first. You can either
install them individually with command `npm install` or by running the
`installdeps.sh` script:

    ./installdeps.sh

Place all your Markdown files in the `pages` directory. These files will
be used for generating the content of the site. Place all your templates in the
`templates` directory. All the Stylus stylesheets and CoffeeScript and
JavaScript files should be places to the `static` directory. You can customize
these paths in the `configuraton.json` file, if you like. You should have
atleast one template and one Markdown file for this to work. The directory
structure in `pages` and `static` directories will remain the same in the
output directory, so you can, for example, place all your stylesheets in
`static/css/` and they will appear in `out/css/`.

Each Markdown file should be in this kind of format:

    id: index
    title: Home
    template: default
    mydata: Some data I'd like to use
      in this specific page. This one reaches
      to multiple lines.

    ---
    # Here is the actual Markdown portion

    ...

The `---` line acts as a separator for the page metadata and the page
body. Everything before the separator is interpreted in the program's
configuration parser, and the rest is interpreted as Markdown.

The string in the beginning of line till character `:` is interpreted as a
key. The string following the `:` character is interpreted as its value. If you
want your values in multiple lines, start the next line with two spaces. The
parser first tries to interpret the accumulated value as a JSON value, and then
as a string value if that fails.

You can write pretty much any data to your page configurations but be sure to
have atleast an `id` for each page. If you don't specify a `template`, the
template named `default` is used.

Once the configuration has been parsed, the configurations are passed to the
template engine as a JavaScript object when the page is rendered. Here's a full
list of what you have access to in the templates:;

* **site**: site wide data (`sitedata` in the configuration file)
* **allpages**: all the pages with their metadata and body intact
* **page**: the data from the Markdown file
  * **id**: the ID for the page
  * **body**: the page contents
* **static**: all the static files

Once the `configuration.json` has been configured, and the files are in place
run `./mysimplehomepage.js build` to build your site. The generated files will
be placed to the output directory (default: `out/`). If you want to use files
like images with your site, just place them to the output directory.

There's also a feature built in for monitoring changes in the source files. If
you run the `./mysimplehomepage.js watch`, the program will automatically
generate the site after you change any of the source files. If you have
`node-static` installed, the program will launch a web server that serves files
from the output directory. The default port for the test server is 3030.

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

(2-clause BSD license)

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
[mkdirp]: https://github.com/substack/node-mkdirp/
[highlight]: https://github.com/andris9/highlight
