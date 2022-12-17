import lib/html

pub fn document() {
  html.document(lang: "en", head: #([], head()), body: #([], body()))
}

fn head() {
  [
    html.title("Saved articles and links"),
    html.link([html.rel("stylesheet"), html.href("styles.css")]),
  ]
}

fn body() {
  [html.div([], [html.text("Hello world")]), html.div([], [html.text(" ")])]
}
