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
}

@module("node:fs/promises") external readdir: string => Promise.t<array<string>> = "readdir"

module Dirent = {
  type t

  @send
  external isDirectory: t => bool = "isDirectory"

  @send
  external isFile: t => bool = "isFile"

  @get
  external name: t => string = "name"
}

@module("node:fs/promises")
external readdirWithFileTypes: (string, 'options) => Promise.t<array<Dirent.t>> = "readdir"

module Stats = {
  type t = {size: int}

  @send
  external isDirectory: t => bool = "isDirectory"

  @send
  external isFile: t => bool = "isFile"
}

@module("node:fs/promises")
external stat: string => Promise.t<Stats.t> = "stat"

@module("fs/promises")
external writeFile: (string, string, 'options) => Promise.t<unit> = "writeFile"
