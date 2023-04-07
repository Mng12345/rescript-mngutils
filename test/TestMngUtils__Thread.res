Test.testAsync("Internals.run", ~timeout=10000, cb => {
  let asyncFun = async () => {
    let compute = module(
      TestMngUtils__Thread__Compute: MngUtils.Thread.Compute with
        type input = int
        and type result = string

    )
    let result = try {
      await MngUtils.Thread.run([1, 2, 3, 4], compute, 4)
    } catch {
    | exn => raise(exn)
    }
    assert (result->Belt.Array.length === 4)
    assert (result[0] === "1")
    assert (result[1] === "2")
    assert (result[2] === "3")
    assert (result[3] === "4")
  }
  asyncFun()
  ->Promise.thenResolve(() => {
    cb()
  })
  ->Promise.catch(err => {
    Js.log2(`error: `, err)
    Promise.resolve()
  })
  ->ignore
})

// add image parse performance test
Test.testAsync("matrix compute", ~timeout=60000, cb => {
  let asyncFunc = async () => {
    let compute = module(
      TestMngUtils__Thread__Compute__Matrix: MngUtils.Thread.Compute with
        type input = int
        and type result = int

    )
    let result = await MngUtils.Thread.run([30000, 30000, 30000, 30000], compute, 4)
    assert (result->Belt.Array.length === 4)
    result->Belt.Array.forEach(item => {
      Js.log(`thread time use: ${item->Belt.Int.toString}ms`)
    })
    module Compute = unpack(compute)
    Compute.compute(30000)->Js.log2(`time use in main thread: `, _)
    module Compute = unpack(compute)
    Compute.compute(30000)->Js.log2(`time use in main thread: `, _)
    module Compute = unpack(compute)
    Compute.compute(30000)->Js.log2(`time use in main thread: `, _)
    module Compute = unpack(compute)
    Compute.compute(30000)->Js.log2(`time use in main thread: `, _)
  }
  asyncFunc()
  ->Promise.thenResolve(() => cb())
  ->Promise.catch(err => {
    Js.log2(`error: `, err)
    Promise.resolve()
  })
  ->ignore
})
