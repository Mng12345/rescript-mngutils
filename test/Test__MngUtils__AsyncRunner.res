Test.testAsync("AsyncRunner", ~timeout=30_000, cb => {
  let runner = MngUtils.AsyncRunner.make(
    [
      () => MngUtils.Async.sleep(1000)->Promise.then(_ => Promise.resolve(1)),
      () => MngUtils.Async.sleep(2000)->Promise.then(_ => Promise.resolve(2)),
      () => MngUtils.Async.sleep(2000)->Promise.then(_ => Promise.resolve(3)),
      () => MngUtils.Async.sleep(2000)->Promise.then(_ => Promise.resolve(4)),
      () => MngUtils.Async.sleep(3000)->Promise.then(_ => Promise.resolve(5)),
      () => MngUtils.Async.sleep(4000)->Promise.then(_ => Promise.resolve(6)),
      () => MngUtils.Async.sleep(3000)->Promise.then(_ => Promise.resolve(7)),
      () => MngUtils.Async.sleep(4000)->Promise.then(_ => Promise.resolve(8)),
    ],
    4,
  )
  runner
  ->MngUtils.AsyncRunner.runWithPollTimeWithTimeout(150, None)
  ->Promise.then(results => {
    Js.log2(`results: `, results)
    cb(~planned=0, ())
    Promise.resolve()
  })
  ->ignore
})
