import gleam/io
import gleam/list
import gleam/result
import home
import lib/html
import lib/fs

pub fn main() {
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
