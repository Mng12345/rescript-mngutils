@deprecated("use Belt.Result")
type t<'value, 'err> = Ok('value) | Err('err)

external unsafeWrap: Belt.Result.t<'value, 'err> => 'value = "%identity"

let unwrap = result => {
  switch result {
  | Ok(value) => value
  | Err(exn) => raise(exn)
  }
  assert false
}

let expect = (result, expect: string) => {
  switch result {
  | Ok(value) => value
  | Err(exn) =>
    raise(
      {
        "expect": expect,
        "exn": exn,
      }->Js.Exn.anyToExnInternal,
    )
  }
}

let unwrap = result => {
  switch result {
  | Ok(value) => value
  | Err(exn) => raise(exn)
  }
  assert false
}

let expect = (result, expect: string) => {
  switch result {
  | Ok(value) => value
  | Err(exn) =>
    raise(
      {
        "expect": expect,
        "exn": exn,
      }->Js.Exn.anyToExnInternal,
    )
  }
}
