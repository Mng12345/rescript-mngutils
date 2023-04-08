type dayjs

@module external dayjs: unit => dayjs = "dayjs"

@module external dayjsWithString: string => dayjs = "dayjs"

@module external dayjsWithDate: Js.Date.t => dayjs = "dayjs"

@send
external format: (dayjs, string) => string = "format"

@send
external isBefore: (dayjs, dayjs) => bool = "isBefore"

@send
external isAfter: (dayjs, dayjs) => bool = "isAfter"

@send
external add: (dayjs, int, string) => dayjs = "add"

@send
external subtract: (dayjs, int, string) => dayjs = "subtract"
