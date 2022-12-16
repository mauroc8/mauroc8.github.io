import lib/html

pub fn document() {
  html.document(lang: "en", head: #([], head()), body: #([], body()))
}

fn head() {
  [html.title("Saved articles and links")]
}

fn body() {
  [html.div([], [html.text("Hello world")])]
}
