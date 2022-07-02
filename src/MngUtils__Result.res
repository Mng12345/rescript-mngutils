type t<'value, 'err> = Ok('value) | Err('err)

external unsafeWrap: t<'value, 'err> => 'value = "%identity"
