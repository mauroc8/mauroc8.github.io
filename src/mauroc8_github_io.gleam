import gleam/io
import gleam/http/elli
import gleam/http/service
import gleam/http/request.{Request}
import gleam/http/response
import gleam/list
import gleam/result
import gleam/erlang
import gleam/string
import gleam/bit_builder.{BitBuilder}
import lib/fs.{File}
import home
import lib/html

pub fn main() {
  case erlang.start_arguments() {
    ["build"] -> build()
    ["serve"] -> development_server()
    _ -> {
      io.println("No command")
      io.println("Run `gleam run build` or gleam run serve")
      Error(Nil)
    }
  }
}

fn build() {
  io.println("- Delete the contents of dist/ (except dist/.git)")

  assert Ok(dist_directory) = fs.touch_directory(fs.path(["dist"]))

  assert Ok(_) =
    fs.list_directory(dist_directory)
    |> list.map(fn(resource) {
      case fs.path(["dist", ".git"]) == fs.resource_path(resource) {
        True -> Ok(Nil)
        False -> fs.delete_resource(resource)
      }
    })
    |> result.all()

  io.println("- Copy the contents of static/ to dist/")

  assert Ok(static_directory) = fs.touch_directory(fs.path(["static"]))

  assert Ok(_) =
    fs.list_directory(static_directory)
    |> list.map(fn(resource) { fs.copy_resource(resource, to: dist_directory) })
    |> result.all()

  io.println("- Write dist/index.html")

  assert Ok(_) =
    fs.write_file(
      dist_directory,
      "index.html",
      home.document()
      |> html.to_string,
    )

  Ok(Nil)
}

fn development_server() {
  io.println("Serving in http://localhost:2583/")

  assert Ok(_) = elli.become(serve(), on_port: 2583)

  Ok(Nil)
}

fn serve() -> service.Service(BitString, BitBuilder) {
  fn(request) {
    case request {
      Request(path: "", ..) | Request(path: "index.html", ..) | Request(
        path: "/",
        ..,
      ) ->
        response.new(200)
        |> response.prepend_header("Content-Type", "text/html")
        |> response.set_body(
          home.document()
          |> html.to_string
          |> bit_builder.from_string,
        )

      Request(path: request_path, ..) ->
        case
          fs.get_resource(fs.path([
            "static",
            ..request_path
            |> string.split("/")
            |> list.filter(fn(segment) { segment != ".." })
          ]))
        {
          Ok(File(file)) -> {
            assert Ok(bits) = fs.read_file_as_bits(file)
            response.new(200)
            |> response.set_body(bit_builder.from_bit_string(bits))
          }
          _ ->
            response.new(404)
            |> response.set_body(
              "404 Not found "
              |> string.append(request_path)
              |> bit_builder.from_string,
            )
        }
    }
  }
}
