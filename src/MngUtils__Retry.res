module Sync = {
  let retry = (func, times, args) => {
    let break = ref(false)
    let i = ref(0)
    let result = ref(None)
    while i.contents < times && !break.contents {
      try {
        let r = func(args)
        result := Some(Belt.Result.Ok(r))
        break := true
      } catch {
      | exn =>
        result := Some(Belt.Result.Error(exn))
        i := i.contents + 1
      }
    }
    result.contents->Belt.Option.getUnsafe
  }
}

module Async = {
  let retry = async (func, times, args) => {
    let break = ref(false)
    let i = ref(0)
    let result = ref(None)
    while i.contents < times && !break.contents {
      try {
        let r = await func(args)
        result := Some(Belt.Result.Ok(r))
        break := true
      } catch {
      | exn =>
        result := Some(Belt.Result.Error(exn))
        i := i.contents + 1
      }
    }
    result.contents->Belt.Option.getUnsafe
  }
}
