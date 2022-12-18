import lib/html

pub fn document() {
  html.document([html.lang("en")], head: #([], head()), body: #([], body()))
}

fn head() {
  [
    html.title("Saved articles and links"),
    html.link([html.rel("stylesheet"), html.href("styles.css")]),
    html.link([html.rel("stylesheet"), html.href("home.css")]),
  ]
}

fn body() {
  [
    html.header([], [html.h1([], [html.text("Hello, world")])]),
    html.p(
      [],
      [
        html.text(
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
        ),
      ],
    ),
  ]
}
