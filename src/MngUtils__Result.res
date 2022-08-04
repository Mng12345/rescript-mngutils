@deprecated("use Belt.Result")
type t<'value, 'err> = Ok('value) | Err('err)

external unsafeWrap: Belt.Result.t<'value, 'err> => 'value = "%identity"
