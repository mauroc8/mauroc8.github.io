import gleam/io
import gleam/list
import gleam/string
import gleam/result
import gleam/erlang/file
import home
import lib/html

pub fn main() {
  io.println("Writing index.html")

  let path = "dist/index.html"

  // Create the dist/ directory if does not exist
  assert Ok(Nil) = case file.is_directory("dist") {
    True -> Ok(Nil)

    False -> file.make_directory("dist")
  }

  // Delete the contents of dist/ except the .git/ folder
  assert Ok(dist_files) = file.list_directory("dist")

  assert Ok(_) =
    result.all(
      dist_files
      |> list.map(fn(dist_file) {
        let path = string.append("dist/", dist_file)

        case #(path == "dist/.git", file.is_directory(path)) {
          #(True, _) -> Ok(Nil)

          #(_, True) -> file.delete_directory(path)

          #(_, False) -> file.delete(path)
        }
      }),
    )

  // Write the new contents of dist/
  let index_html =
    home.document()
    |> html.to_string

  assert Ok(Nil) = file.write(contents: index_html, to: path)
}
