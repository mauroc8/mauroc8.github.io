const chokidar = require('chokidar');
const { exec } = require('child_process')

function build() {
    exec("gleam run", (_, stdout, stderr) => {
        if (stdout) {
            console.log(ident(stdout))
        }
        if (stderr) {
            console.log(ident(stderr))
        }
    })
}

// ---

console.log("- Watching for changes in src/ and static/\n")

chokidar.watch('src').on('all', watcher);
chokidar.watch('static').on('all', watcher);

function watcher(event, path) {
    switch (event) {
        case 'add':
        case 'addDir':
            break

        case 'change':
            console.log("File", path, "changed\n")
            build()
            break

    }
}

// ---

var serveStatic = require('serve-static')
var finalHandler = require('finalhandler')
var http = require('http')

console.log("- Serving the build in http://localhost:2583/\n")

var serve = serveStatic('dist', { dotfiles: 'ignore' });

var server = http.createServer(function onRequest (req, res) {
    serve(req, res, finalHandler(req, res))
})

server.listen(2583)

// ---

function ident(string) {
    return string.split('\n')
        .map(str => `  ${str}`)
        .join('\n')
}
