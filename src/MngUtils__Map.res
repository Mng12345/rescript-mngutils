type t<'a>

@new external make: unit => t<'a> = "Map"

@send external set: (t<'a>, string, 'a) => unit = "set"

@send external get: (t<'a>, string) => option<'a> = "get"

@send external delete: (t<'a>, string) => bool = "delete"

@send external clear: t<'a> => unit = "clear"
