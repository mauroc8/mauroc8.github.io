import gleam/io
import gleam/list
import gleam/string
import gleam/result
import gleam/erlang/file
import home
import lib/html

pub fn main() {
  // Create the dist/ directory if does not exist
  assert Ok(Nil) = case file.is_directory("dist") {
    True -> Ok(Nil)

    False -> file.make_directory("dist")
  }

  io.println("- Delete the contents of dist/ (except dist/.git)")

  assert Ok(Nil) =
    for_every_file_in_directory(
      "dist",
      fn(file_name) {
        case file_name {
          "dist/.git" -> Ok(Nil)
          _ ->
            case file.is_directory(file_name) {
              True -> file.delete_directory(file_name)
              False -> file.delete(file_name)
            }
        }
      },
    )

  io.println("- Copy the contents of static/ to dist/")

  assert Ok(Nil) =
    for_every_file_in_directory(
      "static",
      fn(file_name) {
        file.read_bits(file_name)
        |> result.then(fn(file_contents) {
          file_contents
          |> file.write_bits(string.append(
            "dist",
            file_name
            |> string.drop_left(string.length("static")),
          ))
        })
      },
    )

  io.println("- Write dist/index.html")

  assert Ok(Nil) =
    file.write(
      contents: home.document()
      |> html.to_string,
      to: "dist/index.html",
    )
}

fn for_every_file_in_directory(
  in directory: String,
  do callback: fn(String) -> Result(Nil, _),
) {
  assert Ok(Nil) = case file.is_directory(directory) {
    True -> Ok(Nil)

    False -> file.make_directory(directory)
  }

  assert Ok(dist_files) = file.list_directory(directory)

  assert Ok(_) =
    result.all(
      dist_files
      |> list.map(fn(dist_file) {
        let path =
          directory
          |> string.append("/")
          |> string.append(dist_file)

        callback(path)
      }),
    )

  Ok(Nil)
}
