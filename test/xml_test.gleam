import gleeunit/should
import gleam/string
import lib/xml
import lib/html

pub fn button_test() {
  let button =
    xml.Tag(
      tag_name: "button",
      attributes: [],
      children: [xml.Text("Button <")],
    )

  button
  |> xml.to_string()
  |> should.equal("<button>Button &lt;</button>")
}

pub fn input_test() {
  let input =
    xml.SelfClosingTag(
      tag_name: "input",
      attributes: [
        xml.StringAttribute("type", "text"),
        xml.BooleanAttribute("required", True),
      ],
    )

  input
  |> xml.to_string()
  |> should.equal("<input type=\"text\" required />")
}

pub fn document_test() {
  let document =
    html.document(
      lang: "en",
      head: #([], [html.title("Test document")]),
      body: #([], [html.text("Hello world")]),
    )

  let head_string = "<meta charset=\"UTF-8\" /><title>Test document</title>"

  document
  |> html.to_string
  |> should.equal(
    "<!doctype HTML>
<html lang=\"en\">
<head>"
    |> string.append(head_string)
    |> string.append(
      "</head>
<body>Hello world</body>
</html>
",
    ),
  )
}
