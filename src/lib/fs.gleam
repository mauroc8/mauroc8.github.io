import gleam/erlang/file
import gleam/string
import gleam/list
import gleam/result

pub opaque type Path {
  Path(path: List(String))
}

fn sanitize_path_segment(path: String) {
  path
  |> string.replace("/", "")
  |> string.trim
}

pub fn path(segments: List(String)) {
  Path(
    segments
    |> list.map(sanitize_path_segment),
  )
}

pub fn append_segment(path: Path, segment: String) {
  case path {
    Path(segments) ->
      Path(
        segments
        |> list.append([sanitize_path_segment(segment)]),
      )
  }
}

pub fn path_to_string(path: Path) {
  case path {
    Path([directory, subdirectory, ..files]) ->
      Path([
        string.append(directory, "/")
        |> string.append(subdirectory),
        ..files
      ])
      |> path_to_string

    Path([file_path]) -> file_path

    Path([]) -> "."
  }
}

pub fn get_last_segment(path: Path) -> String {
  case path {
    Path([segment]) -> segment

    Path([]) -> "."

    Path([_, ..tail]) -> get_last_segment(Path(tail))
  }
}

pub opaque type File {
  FileResource(path: Path)
}

pub fn get_file_path(file: File) -> Path {
  let FileResource(path) = file

  path
}

pub fn get_file_name(file: File) -> String {
  file
  |> get_file_path
  |> get_last_segment
}

pub opaque type Directory {
  DirectoryResource(path: Path)
}

pub fn get_directory_path(directory: Directory) -> Path {
  let DirectoryResource(path) = directory

  path
}

pub fn get_directory_name(directory: Directory) -> String {
  directory
  |> get_directory_path
  |> get_last_segment
}

pub type Resource {
  File(file: File)
  Directory(directory: Directory)
}

pub fn get_resource(path path: Path) -> Result(Resource, Nil) {
  let file_path = path_to_string(path)

  case file.is_directory(file_path), file.is_file(file_path) {
    True, _ -> Ok(Directory(DirectoryResource(path)))
    _, True -> Ok(File(FileResource(path)))
    _, _ -> Error(Nil)
  }
}

pub fn resource_path(resource: Resource) -> Path {
  case resource {
    File(file) -> get_file_path(file)
    Directory(dir) -> get_directory_path(dir)
  }
}

pub fn read_file_as_string(file: File) -> Result(String, Nil) {
  let FileResource(file_path) = file

  case file.read(path_to_string(file_path)) {
    Ok(str) -> Ok(str)
    Error(_) -> Error(Nil)
  }
}

pub fn read_file_as_bits(file: File) -> Result(BitString, Nil) {
  let FileResource(file_path) = file

  case file.read_bits(path_to_string(file_path)) {
    Ok(bits) -> Ok(bits)
    Error(_) -> Error(Nil)
  }
}

pub fn write_file(
  in directory: Directory,
  name name: String,
  content content: String,
) -> Result(File, Nil) {
  let DirectoryResource(dir_path) = directory
  let file_path = append_segment(dir_path, name)

  case file.write(contents: content, to: path_to_string(file_path)) {
    Ok(Nil) -> Ok(FileResource(file_path))
    Error(_) -> Error(Nil)
  }
}

pub fn write_file_bits(
  in directory: Directory,
  name name: String,
  content content: BitString,
) -> Result(File, Nil) {
  let DirectoryResource(dir_path) = directory
  let file_path = append_segment(dir_path, name)

  case file.write_bits(contents: content, to: path_to_string(file_path)) {
    Ok(Nil) -> Ok(FileResource(file_path))
    Error(_) -> Error(Nil)
  }
}

/// Reads a file, but it creates it if it has to.
/// It can even delete a directory if it has to in order to create the file.
pub fn touch_file(
  in directory: Directory,
  name name: String,
) -> Result(File, Nil) {
  case
    get_resource(
      get_directory_path(directory)
      |> append_segment(name),
    )
  {
    Ok(File(file)) -> Ok(file)
    Ok(Directory(directory)) -> {
      use _ <- result.then(delete_resource(Directory(directory)))
      write_file(directory, name, "")
    }
    Error(Nil) -> write_file(directory, name, "")
  }
}

pub fn list_directory(directory: Directory) -> List(Resource) {
  let DirectoryResource(dir_path) = directory

  case file.list_directory(path_to_string(dir_path)) {
    Ok(dir_resources) ->
      result.values(
        dir_resources
        |> list.map(fn(resource_path) {
          get_resource(append_segment(dir_path, resource_path))
        }),
      )

    Error(_) -> []
  }
}

/// Tries to create a directory in the `path`. It fails if a directory
/// or file exists at that `path`.
pub fn create_directory(path: Path) -> Result(Directory, Nil) {
  let dir_path = path_to_string(path)

  case file.make_directory(dir_path) {
    Ok(_) -> Ok(DirectoryResource(path))
    Error(_) -> Error(Nil)
  }
}

/// Writes a empty directory in the contents of `path`.
///
/// If the directory already exists, it doesn't do anything.
/// If the path points to a file, it deletes the file and then
/// creates the directory.
pub fn touch_directory(path: Path) -> Result(Directory, Nil) {
  case get_resource(path) {
    Ok(File(file)) ->
      delete_resource(File(file))
      |> result.then(fn(_) { create_directory(path) })

    Ok(Directory(directory)) -> Ok(directory)

    Error(_) -> create_directory(path)
  }
}

pub fn delete_resource(resource: Resource) -> Result(Nil, Nil) {
  case resource {
    File(FileResource(file_path)) ->
      file.delete(path_to_string(file_path))
      |> result.map_error(fn(_) { Nil })

    Directory(DirectoryResource(dir_path)) ->
      list_directory(DirectoryResource(dir_path))
      |> list.map(delete_resource)
      |> result.all()
      |> result.then(fn(_) {
        file.delete_directory(path_to_string(dir_path))
        |> result.map_error(fn(_) { Nil })
      })
  }
}

pub fn copy_resource(
  resource: Resource,
  to directory: Directory,
) -> Result(Resource, Nil) {
  case resource {
    File(file) -> {
      use bits <- result.then(read_file_as_bits(file))
      write_file_bits(in: directory, name: get_file_name(file), content: bits)
      |> result.map(File)
    }

    Directory(subdirectory) -> {
      use
        subdirectory_copy
      <- result.then(touch_directory(
          get_directory_path(directory)
          |> append_segment(get_directory_name(subdirectory)),
        ))
      list_directory(subdirectory)
      |> list.map(fn(resource) {
        copy_resource(resource, to: subdirectory_copy)
      })
      |> result.all()
      |> result.map(fn(_) { Directory(subdirectory_copy) })
    }
  }
}
