@deprecated("use Belt.Result")
type t<'value, 'err> = Ok('value) | Err('err)

external unsafeWrap: Belt.Result.t<'value, 'err> => 'value = "%identity"

let unwrap = result => {
  switch result {
  | Ok(value) => value
  | Err(exn) => Js.E
  }
  assert false
}