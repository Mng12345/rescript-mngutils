module Stats = {
  type t = {size: int}

  @send
  external isDirectory: t => bool = "isDirectory"

  @send
  external isFile: t => bool = "isFile"
}

module Dirent = {
  type t

  @send
  external isDirectory: t => bool = "isDirectory"

  @send
  external isFile: t => bool = "isFile"

  @get
  external name: t => string = "name"
}

module Buffer = {
  type t
}
module Fs = {
  type error<'a> = Js.Nullable.t<'a>
  type stats = {size: int}

  @module("fs")
  external stat: (string, (error<'a>, stats) => unit) => unit = "stat"

  let fileSize = path => {
    Promise.make((resolve, reject) => {
      path->stat((error, stats) => {
        switch error->Js.Nullable.toOption {
        | None => resolve(. stats.size)
        | Some(error) => reject(. error)
        }
      })
    })
  }

  @module("fs/promises") external readdir: string => Promise.t<array<string>> = "readdir"

  @module("fs/promises")
  external readdirWithFileTypes: (string, 'options) => Promise.t<array<Dirent.t>> = "readdir"

  @module("fs/promises")
  external stat: string => Promise.t<Stats.t> = "stat"

  @module("fs/promises")
  external writeFile: (string, string, 'options) => Promise.t<unit> = "writeFile"

  @module("fs/promises")
  external readFileIntoBuffer: string => Promise.t<Buffer.t> = "readFile"

  @module("fs/promises")
  external readFile: (string, 'options) => Promise.t<string> = "readFile"

  @module("fs/promises")
  external rm: string => Promise.t<unit> = "rm"
}

module Path = {
  @module("path") external resolve2: (string, string) => string = "resolve"
  @module("path") external resolve3: (string, string, string) => string = "resolve"
  @module("path") external resolve4: (string, string, string) => string = "resolve"
  @module("path") external resolve5: (string, string, string) => string = "resolve"
}
