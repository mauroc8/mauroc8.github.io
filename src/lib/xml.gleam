import gleam/string_builder.{StringBuilder}
import gleam/string
import gleam/list

pub type Node {
  Tag(tag_name: String, attributes: List(Attribute), children: List(Node))
  SelfClosingTag(tag_name: String, attributes: List(Attribute))
  Text(content: String)
  Comment(content: String)
  // <script> and <style> tags are special because they can only contain `Text` nodes,
  // whose content can be unescaped HTML, like `.foo > .bar` instead of `.foo &gt; .bar`.
  UnescapedContentTag(
    tag_name: String,
    attributes: List(Attribute),
    content: String,
  )
}

pub type Attribute {
  StringAttribute(name: String, value: String)
  BooleanAttribute(name: String, visible: Bool)
}

pub fn escape_text(str: String) -> String {
  str
  |> string.replace("&", "&amp;")
  |> string.replace("\"", "&quot;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
}

pub fn to_string(node: Node) -> String {
  string_builder.from_string("")
  |> append_node(node)
  |> string_builder.to_string
}

fn append_attribute(
  builder: StringBuilder,
  attribute: Attribute,
) -> StringBuilder {
  case attribute {
    StringAttribute(name, value) ->
      builder
      |> string_builder.append(name)
      |> string_builder.append("=\"")
      |> string_builder.append(escape_text(value))
      |> string_builder.append("\"")

    BooleanAttribute(name: name, visible: True) ->
      builder
      |> string_builder.append(name)
    BooleanAttribute(name: _, visible: False) -> builder
  }
}

fn append_attributes(
  builder: StringBuilder,
  attributes: List(Attribute),
) -> StringBuilder {
  let f = fn(builder: StringBuilder, attr: Attribute) -> StringBuilder {
    builder
    |> string_builder.append(" ")
    |> append_attribute(attr)
  }
  attributes
  |> list.fold(from: builder, with: f)
}

fn append_children(
  builder: StringBuilder,
  children: List(Node),
) -> StringBuilder {
  let f = fn(builder, child) {
    builder
    |> append_node(child)
  }

  children
  |> list.fold(builder, f)
}

fn append_node(builder: StringBuilder, node: Node) -> StringBuilder {
  let open_node = fn(builder: StringBuilder, tag_name: String) {
    builder
    |> string_builder.append("<")
    |> string_builder.append(tag_name)
  }

  let with_closing_node = fn(builder: StringBuilder, tag_name: String) {
    builder
    |> string_builder.append("</")
    |> string_builder.append(tag_name)
    |> string_builder.append(">")
  }

  case node {
    Tag(tag_name, attributes, children) ->
      builder
      |> open_node(tag_name)
      |> append_attributes(attributes)
      |> string_builder.append(">")
      |> append_children(children)
      |> with_closing_node(tag_name)

    SelfClosingTag(tag_name, attributes) ->
      builder
      |> open_node(tag_name)
      |> append_attributes(attributes)
      |> string_builder.append(" />")

    Text(content) ->
      builder
      |> string_builder.append(escape_text(content))
    Comment(content) ->
      builder
      |> string_builder.append("<!--")
      |> string_builder.append(escape_text(content))
      |> string_builder.append("-->")

    UnescapedContentTag(tag_name, attributes, content) ->
      builder
      |> open_node(tag_name)
      |> append_attributes(attributes)
      |> string_builder.append(">\n")
      |> string_builder.append(content)
      |> with_closing_node(tag_name)
  }
}
