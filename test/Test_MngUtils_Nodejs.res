Test.testAsync("readFile", ~timeout=30000, cb => {
  MngUtils.Nodejs.Fs.readFile("./src/MngUtils__Nodejs.res", {"encoding": "utf-8"})
  ->Promise.then(contents => {
    Js.log2(`contents:\n`, contents)
    cb(~planned=0, ())
    Promise.resolve()
  })
  ->ignore
})
