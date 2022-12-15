import gleam/string_builder
import xml
import gleam/list

/// An HTML 5 node
pub opaque type Node {
  Node(xml_node: xml.Node)
}

pub fn text(content: String) {
  Node(xml.Text(content))
}

fn to_xml(node: Node) {
  let Node(xml_node) = node
  xml_node
}

fn tag(tag_name: String, attributes: List(Attribute), children: List(Node)) {
  Node(xml.Tag(
    tag_name,
    attributes
    |> list.map(attribute_to_xml),
    children
    |> list.map(to_xml),
  ))
}

pub fn main(attributes: List(Attribute), children: List(Node)) {
  tag("main", attributes, children)
}

pub fn h1(attributes: List(Attribute), children: List(Node)) {
  tag("h1", attributes, children)
}

pub fn h2(attributes: List(Attribute), children: List(Node)) {
  tag("h2", attributes, children)
}

pub fn h3(attributes: List(Attribute), children: List(Node)) {
  tag("h3", attributes, children)
}

pub fn h4(attributes: List(Attribute), children: List(Node)) {
  tag("h4", attributes, children)
}

pub fn h5(attributes: List(Attribute), children: List(Node)) {
  tag("h5", attributes, children)
}

pub fn div(attributes: List(Attribute), children: List(Node)) {
  tag("div", attributes, children)
}

pub fn span(attributes: List(Attribute), children: List(Node)) {
  tag("span", attributes, children)
}

pub fn article(attributes: List(Attribute), children: List(Node)) {
  tag("article", attributes, children)
}

pub fn p(attributes: List(Attribute), children: List(Node)) {
  tag("p", attributes, children)
}

pub fn i(attributes: List(Attribute), children: List(Node)) {
  tag("i", attributes, children)
}

pub fn b(attributes: List(Attribute), children: List(Node)) {
  tag("b", attributes, children)
}

pub fn u(attributes: List(Attribute), children: List(Node)) {
  tag("u", attributes, children)
}

pub fn code(attributes: List(Attribute), children: List(Node)) {
  tag("code", attributes, children)
}

pub fn blockquote(attributes: List(Attribute), children: List(Node)) {
  tag("blockquote", attributes, children)
}

pub fn aside(attributes: List(Attribute), children: List(Node)) {
  tag("aside", attributes, children)
}

pub fn nav(attributes: List(Attribute), children: List(Node)) {
  tag("nav", attributes, children)
}

pub fn header(attributes: List(Attribute), children: List(Node)) {
  tag("header", attributes, children)
}

pub fn footer(attributes: List(Attribute), children: List(Node)) {
  tag("footer", attributes, children)
}

pub fn caption(attributes: List(Attribute), children: List(Node)) {
  tag("caption", attributes, children)
}

pub fn a(attributes: List(Attribute), children: List(Node)) {
  tag("a", attributes, children)
}

pub fn button(attributes: List(Attribute), children: List(Node)) {
  tag("button", attributes, children)
}

pub fn ul(attributes: List(Attribute), children: List(Node)) {
  tag("ul", attributes, children)
}

pub fn ol(attributes: List(Attribute), children: List(Node)) {
  tag("ol", attributes, children)
}

pub fn li(attributes: List(Attribute), children: List(Node)) {
  tag("li", attributes, children)
}

fn self_closing_tag(tag_name: String, attributes: List(Attribute)) {
  Node(xml.SelfClosingTag(
    tag_name,
    attributes
    |> list.map(attribute_to_xml),
  ))
}

pub fn img(attributes: List(Attribute)) {
  self_closing_tag("img", attributes)
}

pub fn meta(attributes: List(Attribute)) {
  self_closing_tag("meta", attributes)
}

pub fn link(attributes: List(Attribute)) {
  self_closing_tag("link", attributes)
}

pub fn hr(attributes: List(Attribute)) {
  self_closing_tag("hr", attributes)
}

pub fn br() {
  self_closing_tag("br", [])
}

/// An HTML 5 attribute
pub opaque type Attribute {
  Attribute(xml_attribute: xml.Attribute)
}

fn attribute_to_xml(attribute: Attribute) {
  let Attribute(xml_attribute) = attribute
  xml_attribute
}

pub fn name(value: String) {
  Attribute(xml.StringAttribute("name", value))
}

pub fn content(value: String) {
  Attribute(xml.StringAttribute("content", value))
}

/// An HTML 5 document
pub opaque type Document {
  Document(
    lang: String,
    title: String,
    head: List(Node),
    stylesheet_paths: List(String),
    body_attributes: List(Attribute),
    body_children: List(Node),
  )
}

pub fn document(
  lang lang: String,
  title title: String,
  head head: List(Node),
  body body: #(List(Attribute), List(Node)),
) {
  let #(body_attributes, body_children) = body

  Document(
    lang: lang,
    title: title,
    head: head,
    stylesheet_paths: [],
    body_attributes: body_attributes,
    body_children: body_children,
  )
}

pub fn with_stylesheet(document: Document, stylesheet_path: String) {
  Document(
    ..document,
    stylesheet_paths: [stylesheet_path, ..document.stylesheet_paths],
  )
}

pub fn to_string(document: Document) {
  let head =
    xml.Tag(
      "head",
      [],
      [
        xml.SelfClosingTag("meta", [xml.StringAttribute("charset", "UTF-8")]),
        xml.Tag("title", [], [xml.Text(document.title)]),
        ..document.stylesheet_paths
        |> list.map(fn(path) {
          xml.SelfClosingTag(
            "link",
            [
              xml.StringAttribute("rel", "stylesheet"),
              xml.StringAttribute("href", path),
            ],
          )
        })
        |> list.append(
          document.head
          |> list.map(to_xml),
        )
      ],
    )

  let body =
    xml.Tag(
      "body",
      document.body_attributes
      |> list.map(attribute_to_xml),
      document.body_children
      |> list.map(to_xml),
    )

  string_builder.from_string("<!doctype HTML>\n")
  |> string_builder.append(xml.to_string(xml.Tag(
    "html",
    [xml.StringAttribute("lang", document.lang)],
    [xml.Text("\n"), head, xml.Text("\n"), body, xml.Text("\n")],
  )))
  |> string_builder.append("\n")
  |> string_builder.to_string
}
