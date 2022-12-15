import gleam/string_builder.{StringBuilder}
import gleam/string
import gleam/list

const identation_unit = "  "

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

pub fn to_string(node: Node, with config: Config) {
  string_builder.from_string("")
  |> append_node(node, config)
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

pub opaque type Config {
  Minified
  Expanded(identation: String, max_line_length: Int)
}

pub fn minified() {
  Minified
}

pub fn expanded(max_characters_per_line: Int) {
  Expanded("", max_characters_per_line)
}

fn increase_identation(config: Config) -> Config {
  case config {
    Minified -> config
    Expanded(identation, max_line_length) ->
      Expanded(
        identation
        |> string.append(identation_unit),
        max_line_length,
      )
  }
}

fn subtract_characters_per_line(
  config: Config,
  subtracted_characters_per_line: Int,
) -> Config {
  case config {
    Minified -> config
    Expanded(identation, max_line_length) ->
      Expanded(identation, max_line_length - subtracted_characters_per_line)
  }
}

fn append_identation(
  builder: StringBuilder,
  identation: String,
) -> StringBuilder {
  builder
  |> string_builder.append("\n")
  |> string_builder.append(identation)
}

fn with_identation(builder: StringBuilder, config: Config) -> StringBuilder {
  case config {
    Minified -> builder

    Expanded(identation, _) ->
      builder
      |> append_identation(identation)
  }
}

fn append_attributes_preserving_config(
  builder: StringBuilder,
  attributes: List(Attribute),
  with config: Config,
) -> StringBuilder {
  let f = case config {
    Minified -> fn(builder: StringBuilder, attr: Attribute) -> StringBuilder {
      builder
      |> string_builder.append(" ")
      |> append_attribute(attr)
    }
    Expanded(identation, _) -> fn(builder: StringBuilder, attr: Attribute) -> StringBuilder {
      builder
      |> append_identation(identation)
      |> append_attribute(attr)
    }
  }
  attributes
  |> list.fold(from: builder, with: f)
}

fn append_attributes_minified_if_possible(
  builder: StringBuilder,
  attributes: List(Attribute),
  identation: String,
  max_line_length: Int,
) -> StringBuilder {
  let minified_attributes =
    append_attributes(string_builder.from_string(""), attributes, Minified)
    |> string_builder.to_string()

  case
    string.length(identation) + string.length(minified_attributes) > max_line_length
  {
    True ->
      builder
      |> append_attributes(
        attributes,
        Expanded(identation, max_line_length)
        |> increase_identation,
      )

    False ->
      builder
      |> string_builder.append(minified_attributes)
  }
}

fn append_attributes(
  builder: StringBuilder,
  attributes: List(Attribute),
  with config: Config,
) -> StringBuilder {
  case config {
    Minified -> append_attributes_preserving_config(builder, attributes, config)

    Expanded(identation, max_line_length) ->
      append_attributes_minified_if_possible(
        builder,
        attributes,
        identation,
        max_line_length,
      )
  }
}

fn append_text_content(
  builder: StringBuilder,
  content: String,
  with config: Config,
) -> StringBuilder {
  builder
  |> string_builder.append_builder(
    content
    |> string.split("\n")
    |> list.fold(
      string_builder.from_string(""),
      fn(content_with_ident, line) {
        content_with_ident
        |> with_identation(config)
        |> string_builder.append(escape_text(line))
        |> string_builder.append("\n")
      },
    ),
  )
}

fn append_children(
  builder: StringBuilder,
  children: List(Node),
  with config: Config,
) -> StringBuilder {
  let f = fn(builder, child) {
    builder
    |> append_node(child, config)
  }

  children
  |> list.fold(builder, f)
}

fn append_node(
  builder: StringBuilder,
  node: Node,
  with config: Config,
) -> StringBuilder {
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
      |> with_identation(config)
      |> open_node(tag_name)
      |> append_attributes(
        attributes,
        config
        |> subtract_characters_per_line(1 + string.length(tag_name) + 1),
      )
      |> string_builder.append(">")
      |> append_children(children, with: increase_identation(config))
      |> with_identation(config)
      |> with_closing_node(tag_name)

    SelfClosingTag(tag_name, attributes) ->
      builder
      |> with_identation(config)
      |> open_node(tag_name)
      |> append_attributes(
        attributes,
        config
        |> subtract_characters_per_line(1 + string.length(tag_name) + 2),
      )
      |> string_builder.append("/>")

    Text(content) ->
      builder
      |> append_text_content(content, with: increase_identation(config))
    Comment(content) ->
      builder
      |> with_identation(config)
      |> string_builder.append("<!--")
      |> append_text_content(content, with: increase_identation(config))
      |> with_identation(config)
      |> string_builder.append("-->")

    UnescapedContentTag(tag_name, attributes, content) ->
      builder
      |> with_identation(config)
      |> open_node(tag_name)
      |> append_attributes(
        attributes,
        config
        |> subtract_characters_per_line(1 + string.length(tag_name) + 1),
      )
      |> string_builder.append(">\n")
      |> string_builder.append(content)
      |> with_identation(config)
      |> with_closing_node(tag_name)
  }
}
