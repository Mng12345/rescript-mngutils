let sleep = time => {
  Promise.make((resolve, _) => {
    Js.Global.setTimeout(() => {
      resolve(. ignore())
    }, time)->ignore
  })
}
